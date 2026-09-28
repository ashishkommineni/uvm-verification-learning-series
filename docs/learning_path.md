# Suggested learning path

## First pass — follow one transaction

Read chapters 00–08 in order. Keep one write transaction in mind and trace it
from sequence creation to the driver, pins, monitor, scoreboard, and coverage.
Run `make check` before studying the UVM hierarchy so the DUT contract is known.

## Second pass — reuse mechanisms

Study chapters 09–14. For every factory or configuration feature, ask what is
being changed, who owns the setting, and at what phase the decision becomes
fixed. Compile the advanced examples with `make uvm-lint`.

## Third pass — interview and debug practice

Answer the 60 questions aloud in 60–90 seconds each. Then deliberately break
one connection, expected count, assertion, or configuration path and diagnose
the first failure rather than the final cascade.

## Completion evidence

A learner should be able to draw the hierarchy, explain the TLM connections,
predict the scoreboard state for a trace, add a new sequence/test, and state
which results were actually run versus merely expected.
