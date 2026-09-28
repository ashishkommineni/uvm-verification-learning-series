# 08 — Phases, objections, and end-of-test

## Phase purpose

UVM phases make construction and execution deterministic. `build_phase` creates
components and retrieves configuration. `connect_phase` joins TLM ports.
`end_of_elaboration_phase` is useful for topology/debug setup. `start_of_simulation`
prepares run-time reporting. `run_phase` consumes simulation time. `extract`,
`check`, and `report` finish the verdict without driving new traffic.

Function phases must not block or consume time. Task phases may consume time.
Components execute a given phase in framework-defined traversal order; code
should use connections and configuration rather than depending on sibling
source order.

## Objections

The run phase ends when all run-phase objections drop. A test raises before
starting stimulus and drops after stimulus and response drain. An objection is
not a delay and should not be raised forever by low-level components.

Both executable tests follow this ownership rule in
[`mini_bus_tests.svh`](../../tb/uvm/mini_bus_tests.svh). They allow four extra
clock edges before dropping so the monitor publishes the final response.

## End-of-test checks

The monitor checks its pending queue; the scoreboard checks exact counts and
traffic mix; the report phase prints stable evidence. A global timeout should
also be configured in larger regressions so a deadlock becomes a bounded fail.

## Interview trap

“The sequence returned” does not prove the DUT response was observed. End the
test only after protocol drain and use exact observed counts.

## Traversal and timing table

| Phase | Time? | Traversal | Example |
|---|---:|---|---|
| `build_phase` | No | Top-down | Set/get config, create children |
| `connect_phase` | No | Bottom-up | Connect analysis and seq-item ports |
| `end_of_elaboration_phase` | No | Bottom-up | Validate/print topology |
| `start_of_simulation_phase` | No | Bottom-up | Final banner/config report |
| `run_phase` | Yes | Concurrent tasks | Reset, stimulus, monitor, checking |
| `extract/check/report/final` | No | Bottom-up | Gather, verify, summarize, cleanup |

All component `run_phase` tasks start concurrently. Source order and sibling
hierarchy do not define runtime ordering; synchronize through protocols/events.

## Exact objection pattern

```systemverilog
task run_phase(uvm_phase phase);
  mini_bus_random_sequence seq;
  phase.raise_objection(this, "start scenario");
  seq = mini_bus_random_sequence::type_id::create("seq");
  seq.start(env.agent.sequencer);
  repeat (4) @(posedge env.agent.monitor.vif.clk); // known pipeline drain
  phase.drop_objection(this, "scenario drained");
endtask
```

An objection count can be inspected when a run hangs. Raise before the first
timed wait; pair every control path with one drop. A timeout remains necessary
because a stuck sequence can prevent code from reaching the drop.

## Better than arbitrary delay

The four-cycle drain in this compact teaching DUT is a known safe bound. A
scalable bench should wait for explicit completion: driver outstanding zero,
monitor pending zero, scoreboard queues empty, and expected observed count
reached. Fixed drain time alone can hide a latency change or dropped response.

## Interview-ready answer (60–90 seconds)

“UVM phases coordinate component construction and execution. Build is top-down,
connect and final function phases are bottom-up, and all run phases execute
concurrently. The test raises the runtime objection before starting stimulus and
drops it only after the sequence and checking pipeline drain. An objection does
not delay or prove correctness; it only prevents phase completion. I put leftover
and count invariants in check phase, the summary in report phase, and use a global
timeout to bound deadlocks.”

## Interview follow-ups

1. **Why call `super.build_phase`?** Base classes may implement required
   configuration and construction behavior.
2. **Can `check_phase` wait for a FIFO item?** No; it is a function phase.
3. **Who should own objections?** The highest scenario owner that knows when the
   complete test activity and drain are finished.
4. **Does dropping the last objection terminate every task immediately?** It
   allows phase termination; remaining phase processes are then ended by UVM.
5. **How do you debug a stuck phase?** Inspect objection trace, sequence/driver
   handshakes, reset/clock, and outstanding queues.

## Revision summary

**Build, connect, run concurrently, drain, check, report. Objections control
lifetime; explicit checker invariants control the verdict.**

Advanced runtime subphases, domains, drain time, `phase_ready_to_end`, and jumps
are covered in [Chapter 19](../19_advanced_phasing/README.md).
