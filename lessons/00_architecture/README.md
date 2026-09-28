# 00 — UVM architecture and transaction flow

## What problem does the architecture solve?

A directed module test can drive pins and check one result, but it becomes hard
to reuse when the DUT, scenario count, or integration level grows. UVM divides
the work into stable responsibilities: a test selects intent, a sequence creates
transactions, a driver converts them into timing, a monitor reconstructs what
the DUT actually accepted, and independent subscribers check and measure it.

Think of a parcel service. The sequence writes an order, the sequencer queues
orders, the driver delivers a parcel, and the monitor is the receiving-camera
record. The scoreboard trusts the camera record—not the order form—because the
pins are the hardware truth.

## Flow in this repository

1. `mini_bus_test` raises an objection and starts directed then random sequences.
2. A sequence creates `mini_bus_item` objects through the factory.
3. `mini_bus_sequencer` arbitrates and hands one item to `mini_bus_driver`.
4. The driver applies request fields through a virtual interface clocking block.
5. `mini_bus_monitor` observes accepted requests and corresponding responses.
6. Its analysis port broadcasts completed items to scoreboard and coverage.
7. The scoreboard predicts memory state and checks every completed read.
8. Assertions check temporal rules directly on interface signals.

The executable hierarchy is in [`mini_bus_env.svh`](../../tb/uvm/mini_bus_env.svh),
and the closure requirements are in the
[verification plan](../../docs/verification_plan.md).

## Interview-ready explanation

“My UVM environment separates stimulus, pin timing, observation, checking, and
coverage. The monitor is the source of truth and broadcasts completed transfers
to a predictive scoreboard and coverage subscriber. SVA checks cycle-level
protocol behavior, while exact counts and final UVM severity decide pass/fail.”

## Common trap

Connecting the scoreboard to items sent by the driver can hide a driver bug.
The scoreboard must consume monitor observations made at the interface.

## Static structure versus dynamic flow

The component hierarchy is built once; transactions are created and destroyed
during runtime. This distinction explains many UVM rules:

| Static component | Dynamic object | Responsibility |
|---|---|---|
| Test | Sequence | Select scenario / generate intent |
| Sequencer | Sequence item | Arbitrate / represent one operation |
| Driver | Request handle | Translate transaction into timed pins |
| Monitor | Observed item | Reconstruct accepted pin behavior |
| Scoreboard | Expected value/state | Predict and compare correctness |
| Coverage subscriber | Sample handle | Measure verification-plan progress |

A component receives a parent and participates in phases. A transaction has no
permanent hierarchy; its lifetime is governed by ownership and handles.

## One transfer, end to end

For a write to address `3` with data `8'hA5`:

1. The sequence creates an item, assigns `write=1`, `address=3`, `data=A5`, and
   sends it through `finish_item()`.
2. The sequencer grants the request. The driver receives it through
   `get_next_item()` and drives the interface on its clocking block.
3. The DUT accepts when `req && ready` is sampled. SVA starts the
   request-to-response timing obligation at this exact event.
4. The monitor creates a new observed item from signals and queues it until the
   response appears one cycle later.
5. The monitor publishes the completed item. The scoreboard updates its own
   byte model; coverage samples the address/operation bins.
6. The driver calls `item_done()` after checking completion. The sequence may
   now issue its next item.

Control and observed data deliberately use different paths. The sequence-driver
path controls activity; the monitor-subscriber path establishes evidence.

The environment expresses the evidence fanout explicitly:

```systemverilog
agent.monitor.analysis_port.connect(scoreboard.analysis_export);
agent.monitor.analysis_port.connect(coverage.analysis_export);
```

The monitor does not call scoreboard methods by name, so either subscriber can
be replaced or extended without modifying the protocol monitor.

## Checker partitioning

- The **scoreboard** checks data/state relationships across transactions.
- **SVA** checks cycle-accurate protocol obligations at the signal boundary.
- **Functional coverage** measures whether planned situations occurred.
- **UVM reporting and final counts** establish that checking really completed.

Duplicating the same check everywhere increases noise. Put a rule at the lowest
layer that has all required information and the clearest failure timestamp.

## Extension exercise

Add a `status` response bit without changing the sequence's timing knowledge:

1. Add `response_status` to `mini_bus_item` and its copy/print logic.
2. Sample the signal in the monitor only when `response_valid` is true.
3. Teach the scoreboard which status is expected.
4. Add an SVA property for legal response encoding.
5. Add a functional-coverage point/cross for status by operation.

If timing logic appears in the sequence after this change, the abstraction
boundary has leaked.

## Interview follow-ups

1. **Why should the scoreboard trust the monitor?** Because the monitor sees
   what crossed the DUT interface, including driver, reset, and backpressure effects.
2. **Can coverage replace a scoreboard?** No. Coverage records occurrence, not
   correctness.
3. **Where should protocol timing live?** Driver, monitor, interface clocking
   blocks, and SVA—not the transaction or scenario sequence.
4. **Why separate monitor from driver?** Passive reuse and independent evidence;
   a driver cannot objectively validate its own behavior.
5. **How do you prevent a zero-traffic false pass?** Check expected observed
   counts, operation mix, pending queues, assertions, timeout, and error totals.

## Revision summary

**Sequence creates intent; driver creates pins; monitor creates evidence;
scoreboard and SVA establish correctness; coverage establishes progress.**
