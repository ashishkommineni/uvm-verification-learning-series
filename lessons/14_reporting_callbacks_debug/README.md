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
