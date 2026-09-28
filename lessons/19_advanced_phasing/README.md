# Advanced UVM phasing and end-of-test control

## Phase purpose

UVM phases give every component the same construction, connection, runtime, and
final-check schedule. Correct phasing prevents three common failures: accessing a
child before it exists, dropping stimulus before checking drains, and reporting
a pass before outstanding work completes.

## Standard phase order and traversal

| Phase | Kind | Typical work | Traversal |
|---|---|---|---|
| `build_phase` | function | Get config, factory-create children | Top-down |
| `connect_phase` | function | Connect TLM endpoints | Bottom-up |
| `end_of_elaboration_phase` | function | Validate/print topology | Bottom-up |
| `start_of_simulation_phase` | function | Final setup/banner | Bottom-up |
| `run_phase` | task | Reset, drive, monitor, check | Concurrent |
| `extract_phase` | function | Gather final statistics | Bottom-up |
| `check_phase` | function | Verify queues/counts/invariants | Bottom-up |
| `report_phase` | function | Summarize pass/fail | Bottom-up |
| `final_phase` | function | Last zero-time cleanup | Bottom-up |

Function phases must not consume simulation time. All components' run phases
start concurrently; hierarchy does not serialize their task execution.

## Runtime subphases

The predefined runtime schedule also contains `pre_reset`, `reset`, `post_reset`,
`pre_configure`, `configure`, `post_configure`, `pre_main`, `main`, `post_main`,
`pre_shutdown`, `shutdown`, and `post_shutdown`. Use these only when a project has
a shared phase policy. Mixing traffic in `run_phase` with unrelated traffic in
`main_phase` can create confusing objection domains and shutdown order.

## Objections: exact ownership

```systemverilog
task run_phase(uvm_phase phase);
  mini_bus_smoke_seq seq;
  phase.raise_objection(this, "scenario started");
  seq = mini_bus_smoke_seq::type_id::create("seq");
  seq.start(env.agent.sequencer);
  wait (env.scoreboard.outstanding() == 0);
  phase.drop_objection(this, "stimulus and checking drained");
endtask
```

An objection keeps a task phase alive; it does not schedule stimulus or prove the
scoreboard passed. A test (or a dedicated scenario owner) should own the main
objection. Raise before any time-consuming activity and drop exactly once on
every exit path.

## Drain time and `phase_ready_to_end`

Drain time is a fixed grace interval after objections reach zero:

```systemverilog
phase.phase_done.set_drain_time(this, 100ns);
```

It is useful for a known pipeline latency, but it can hide a broken completion
condition. Prefer an explicit outstanding-count/queue-empty handshake. A
component can use `phase_ready_to_end()` to briefly raise an objection when it
knows work remains, then drop it after drain. Guard this logic so it cannot raise
repeatedly forever.

## Domains, synchronization, and jumps

A phase domain is an independent schedule. It is useful when separate interfaces
have genuinely independent reset/runtime timelines. Custom domains can be
synchronized at named phases, but every added domain increases debug complexity.

`phase.jump(target_phase)` transfers a schedule to another phase and is sometimes
used for reset recovery. All components in the affected domain observe the jump;
local component cleanup must therefore tolerate interruption. Prefer an explicit
reset controller unless the whole environment has a documented jump policy.

## Timeout is a safety net

```systemverilog
uvm_root::get().set_timeout(1ms, 1); // second argument makes it non-overridable
```

A timeout converts a hang into a bounded failure. It does not fix the cause.
When it fires, inspect objections, sequencer grants, driver `item_done`, interface
clocks/reset, and scoreboard outstanding counts.

## End-of-test contract

Before dropping the last objection, establish:

1. The sequence returned and no driver request is outstanding.
2. The DUT response pipeline has completed.
3. The monitor has published the final operation.
4. Scoreboard expected/actual queues are empty.
5. Required coverage sampling has occurred.
6. Error/fatal counts are zero or match the negative-test expectation.

The repository's exact operation-count checks prevent a false pass in which both
stimulus and checking silently process zero transactions.

## Where this repository demonstrates it

- Test objection ownership: [`mini_bus_tests.svh`](../../tb/uvm/mini_bus_tests.svh)
- Final count/invariant checks: [`mini_bus_scoreboard.svh`](../../tb/uvm/mini_bus_scoreboard.svh)
- Simulator timeout and result criteria: [`run_xcelium.sh`](../../scripts/run_xcelium.sh)
- Basic phase introduction: [Chapter 08](../08_phases_objections/README.md)

## Interview-ready answer (60–90 seconds)

“UVM phases coordinate the whole hierarchy. Build is top-down so parents can set
configuration before creating children; connect and later function phases are
bottom-up; all run phases execute concurrently. An objection only controls when
a task phase may finish, so I let the test own it around the scenario and drop it
only after the driver, DUT pipeline, monitor, and scoreboard have drained. Fixed
drain time is acceptable for a documented latency but an explicit outstanding
count is safer. Runtime subphases and custom domains help with complex reset and
multi-interface schedules, but I use them only with a project-wide policy. A
timeout bounds hangs and the check/report phases establish the final verdict.”

## Interview follow-ups

1. **Why is build top-down?** A parent must configure a child before creating it.
2. **Do objections stop all run-phase tasks immediately?** No. When all objections
   drop, the phase may end and UVM terminates remaining phase processes.
3. **Can a function phase call `#10ns`?** No; function phases cannot consume time.
4. **Drain time or outstanding counter?** Use a counter/handshake for correctness;
   drain time only for known bounded trailing activity.
5. **What does a phase jump affect?** The schedule/domain, not just the component
   that requested the jump.

## Common traps

- Raising an objection after a delay, when the phase may already have ended.
- A forever loop that raises an objection and never drops it.
- Starting sequences in multiple runtime schedules without a clear policy.
- Using a large drain time to conceal lost responses.
- Printing PASS in `report_phase` without checking error counts and pending work.

## Revision summary

**Build structure, connect endpoints, run concurrently, drain deliberately, then
check and report.** Objections manage lifetime; checker state determines pass.
