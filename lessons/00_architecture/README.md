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
