# Reset, error injection, regression, and coverage closure

## Verification is more than legal traffic

A bench is robust only when it handles startup, mid-transaction reset, illegal
stimulus policy, DUT error responses, random reproducibility, and incomplete
checking. Positive smoke traffic proves a narrow path; negative and recovery
scenarios establish resilience.

## Define the reset contract first

For every interface, document:

1. Whether reset is synchronous or asynchronous and its active polarity.
2. Which request/response signals must become idle and when.
3. Whether an accepted request is cancelled, retried, or completed.
4. Which DUT state clears and which state is retained.
5. When the driver may resume and when monitors may publish again.
6. How scoreboard predictions and pending queues are flushed or reconciled.
7. Which assertions are disabled during reset and when they re-arm.

Without this contract, resetting the driver but not the reference model creates
false mismatches; clearing the reference model too early can hide lost DUT work.

## Reset-safe component flow

```systemverilog
task run_phase(uvm_phase phase);
  forever begin
    wait (!vif.rst_n);
    drive_idle();
    clear_local_protocol_state();
    wait (vif.rst_n);
    @(vif.driver_cb); // settle at a defined clocking-block edge
  end
endtask
```

In a practical driver, reset observation and item driving are coordinated so a
request is never left checked out from the sequencer. Decide whether to complete
it with an aborted response or return to an idle request loop. The monitor must
discard partial transfers. The scoreboard needs a reset notification or observed
reset transaction so its model changes at the same semantic boundary as the DUT.

Assertions normally use `disable iff (!rst_n)` for reset-vacuous cycles, but
separate properties should verify reset outputs themselves.

## Negative and error-injection scenarios

| Scenario | What it validates |
|---|---|
| Boundary legal values | Constraint and decode edges |
| Reserved/illegal request | DUT error response or environment rejection policy |
| Backpressure maximum | Stability and timeout behavior |
| Reset during request | Cancellation/recovery contract |
| Corrupted response | Scoreboard must detect, not tolerate, mismatch |
| Duplicate/missing response | Outstanding tracking and timeout |
| Protocol timing violation | Assertion fires with a useful message |

Do not disable normal constraints globally. Create a negative-test item or use a
narrow inline constraint so the intent is explicit. A negative test passes only
when the **expected** error is observed and no unexpected errors occur.

```systemverilog
int expected_error_count = 1;
// At final check: detected_expected == expected_error_count
// and all other UVM_ERROR/UVM_FATAL counts are zero.
```

## Timeout and hang-debug chain

When a regression times out, debug in causal order:

1. Is clock/reset progressing at the interface?
2. Is a sequence waiting for grant?
3. Did the driver call `get_next_item()` and later `item_done()`?
4. Did the DUT accept the request and produce a response?
5. Did the monitor reconstruct and publish it?
6. Is the scoreboard blocked with outstanding expected/actual work?
7. Which component still holds an objection?

This path finds the first missing handoff instead of adding random delays.

## Reproducible regression discipline

Record at least test name, simulator/version, source commit, random seed, command,
configuration, start/end time, UVM error/fatal counts, coverage database, and log
path. A failing seed is a test case: rerun it unchanged before shrinking or
debugging it.

Classify results as:

- **PASS:** all explicit checkers passed and expected counts completed.
- **FAIL:** DUT/bench checker, assertion, timeout, or unexpected report failure.
- **INFRA:** license, compile farm, filesystem, or tool launch failure.
- **NOT RUN:** never executed; expected output is not evidence.

Keep deterministic smoke tests fast, then add a seeded random matrix. Avoid a
large seed count when coverage data shows it repeats the same behavior.

## Coverage closure workflow

For every uncovered item ask:

1. Is it reachable under the specification?
2. Does the generator permit and target it?
3. Can the DUT accept it in the intended state?
4. Does the monitor sample the correct semantic event?
5. Is the bin definition correct, or should it be justified as excluded?

Coverage is a feedback metric, not the pass/fail oracle. A covered behavior may
still be wrong; the scoreboard and assertions must check it. Code coverage shows
executed implementation, functional coverage shows planned scenario space, and
assertion coverage shows property attempts/successes/vacuity.

## Performance and acceleration readiness

- Keep pin-level timing inside synthesizable interfaces/drivers/monitors.
- Avoid unbounded queues and per-cycle high-verbosity logs.
- Sample only meaningful transactions, not every clock edge.
- Partition transactor and testbench layers clearly for emulation.
- Prefer stable transaction APIs so the checking layer can run outside the
  timing-critical path.

## Evidence in this repository

- Reset and protocol timing: [`mini_bus_if.sv`](../../tb/interfaces/mini_bus_if.sv)
- Assertions: [`mini_bus_sva.sv`](../../tb/assertions/mini_bus_sva.sv)
- Deterministic tests: [`mini_bus_tests.svh`](../../tb/uvm/mini_bus_tests.svh)
- Regression command: [`Makefile`](../../Makefile)
- Verification intent: [`verification_plan.md`](../../docs/verification_plan.md)
- Recorded results and tool boundary: [`verification_report.md`](../../docs/verification_report.md)

## Interview-ready answer (60–90 seconds)

“I start reset verification by defining what happens to accepted requests, DUT
state, outputs, monitor partial transactions, and scoreboard predictions. The
driver goes idle and must resolve any checked-out item; the monitor suppresses
partial traffic; the scoreboard resets at the same semantic boundary. I then add
directed negative cases for illegal values, maximum backpressure, mid-transaction
reset, and missing or corrupt responses. Regressions are reproducible by test,
seed, commit, simulator, and configuration, and they separate design failures
from infrastructure failures. For closure, I correlate code, functional, and
assertion coverage with the verification plan—coverage guides stimulus, while
scoreboards and assertions decide correctness.”

## Interview follow-ups

1. **Should `disable iff` be used on every reset property?** It disables normal
   protocol checks during reset; separate properties must still check reset
   behavior itself.
2. **What if reset occurs after the driver gets an item?** Follow the documented
   abort/retry policy and always resolve the sequencer handshake.
3. **How does a negative test pass?** It observes exactly the expected failure
   mode while all unrelated checks remain clean.
4. **Why save the seed?** Random failure is not reproducible without the same
   seed, test, configuration, source, and tool version.
5. **Does 100% coverage prove correctness?** No. It proves defined bins/code were
   exercised; it does not prove the model or properties are complete or correct.

## Common traps

- Resetting DUT state but not scoreboard state, or the reverse.
- Leaving a sequence item checked out across reset.
- Calling any log with zero UVM errors a pass despite zero observed transfers.
- Treating license failure as a DUT failure.
- Waiving uncovered bins without a specification-based justification.

## Revision summary

**Define reset semantics, inject failures intentionally, preserve reproducibility,
and close planned coverage with independent checking.** Expected output is not
execution evidence; recorded logs and explicit counts are.
