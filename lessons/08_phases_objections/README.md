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
