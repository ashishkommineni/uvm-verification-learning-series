# 14 — Reporting, callbacks, timeout, and debug

## Reporting

Severity (`INFO`, `WARNING`, `ERROR`, `FATAL`) controls meaning and action.
Verbosity filters informational detail; it does not suppress errors. Use stable
report IDs such as `DATA`, `COUNT`, and `NO_RSP` so regressions can group root
causes. A fatal is appropriate when continuing would make results meaningless,
such as a missing virtual interface.

Report catchers can transform expected reports but should not demote real DUT
failures merely to obtain a green regression.

## Callbacks

A callback inserts narrow policy at an explicit hook without replacing a whole
component. The driver registers a callback type and invokes `before_drive`.
The [callback example](../../examples/callbacks/driver_callback_example.sv)
adds high-verbosity transaction tracing to one driver instance.

Factory override is better for replacing an implementation; a config field is
better for simple data. Callback order, lifetime, and legal mutation contract
must be documented.

## Debug order

1. Reproduce the exact test, seed, build, and command.
2. Read the first error, not the final cascade.
3. Print topology and factory/config information for structural failures.
4. Trace one transaction: sequence → driver → pins → monitor → scoreboard.
5. Inspect sampling region and object reuse before blaming the DUT.
6. Keep a timeout so deadlock becomes a deterministic failure.

## Typical intermittent causes

Race-prone signal access, uninitialized fields, shared object handles, random
stream changes, uncontrolled forked processes, objection timing, and an
incorrect response-order assumption.

## Reporting control in practice

```systemverilog
`uvm_info("MON/OBS", tr.convert2string(), UVM_HIGH)
`uvm_error("SB/DATA", $sformatf(
  "id=%0d address=%0h expected=%0h actual=%0h",
  id, address, expected, actual))
```

Severity communicates impact; verbosity controls optional `INFO` detail; ID
identifies a stable message family; action determines display/log/count/stop/exit.
Use per-ID/per-component settings before global suppression. `UVM_FATAL` ends the
simulation after reporting and is appropriate when further results are invalid.

## Callback registration, hook, and installation

Three pieces are required:

```systemverilog
// Component declaration:
`uvm_register_cb(mini_bus_driver, mini_bus_driver_callback)

// Explicit hook:
`uvm_do_callbacks(mini_bus_driver, mini_bus_driver_callback,
                  before_drive(tr))

// Test installation:
uvm_callbacks#(mini_bus_driver, mini_bus_driver_callback)::add(driver, cb);
```

Document whether the callback may mutate `tr`, whether callbacks run in
registration order, and who removes an instance. In this project the hook runs
immediately before drive; the trace callback observes the item without delaying.

## Report catcher distinction

A `uvm_report_catcher` intercepts reports, not component behavior. It can demote
an explicitly expected negative-test message, but the test must count and verify
that exact message and restore normal behavior. Returning `CAUGHT` for a broad
error class is a false-pass risk.

## Transaction-by-transaction debug method

Assign or log a stable ID, then create this timeline:

| Boundary | Evidence to capture |
|---|---|
| Sequence | Randomized fields and seed |
| Sequencer/driver | Grant, request, `item_done`/response ID |
| Interface | Acceptance edge and payload |
| DUT | Response edge/status/data |
| Monitor | Assembled transaction and publish time |
| Scoreboard | Predicted state, expected, actual |

Stop at the first boundary where reality differs from expectation. Later errors
are often cascades. If a failure disappears under high logging, suspect timing,
uninitialized state, or shared-handle mutation rather than “random simulator
behavior.”

## Interview-ready answer (60–90 seconds)

“For reporting I use severity for impact, verbosity for optional detail, and
stable IDs for targeted control and regression triage. Failures include instance,
transaction ID, expected, actual, and time. A callback adds narrow behavior at a
declared hook, while a factory override replaces an implementation and config-db
supplies data. I debug from the first error by reproducing test, seed, commit,
and command, then tracing one transaction from sequence through pins, monitor,
and scoreboard. A timeout bounds deadlocks, but I fix the missing handshake
instead of adding delay.”

## Interview follow-ups

1. **Does `UVM_HIGH` make a message severe?** No; it is verbosity for `INFO`.
2. **Callback or factory override?** Callback for a narrow hook; factory for
   replacing the class implementation.
3. **Why read the first error?** Later mismatches may be consequences of the
   first broken transfer/configuration.
4. **What if verbose logging changes the bug?** Investigate race regions,
   initialization, shared handles, and uncontrolled processes.
5. **How should an expected error be handled?** Match/count a narrow expected
   report or checker outcome and ensure no unrelated errors remain.

## Revision summary

**Stable reports make failures searchable; callbacks add bounded policy; causal
boundary tracing finds the first broken handoff.** Chapter 20 covers catchers,
command-line processing, events, barriers, pools, and object utilities in depth.
