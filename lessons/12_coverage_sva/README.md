# 12 — Functional coverage and assertions

## Different questions

The scoreboard asks, “Was the result correct?” Assertions ask, “Did temporal
protocol rules hold every cycle?” Functional coverage asks, “Which planned
scenarios were observed?” Code coverage asks, “Which implementation structures
executed?” None replaces the others.

## Functional coverage

`mini_bus_coverage` samples only monitor-published completed transactions. Its
covergroup measures operation, first/middle/last address, data categories, and
operation × address cross. Sampling generator intent would count transfers that
could have been blocked or changed before reaching the DUT.

Coverage closure begins with a written plan. An important reachable hole needs
targeted legal stimulus; an unreachable bin needs a justified exclusion. A
percentage without bin meaning is not closure.

## Assertions

The protocol module checks request-to-response timing, no spontaneous response,
stability under stall, and known controls. `disable iff (!reset_n)` prevents
reset behavior from becoming a false failure. Read/write cover properties show
assertion attempts, but they do not replace transaction coverage.

See [coverage subscriber](../../tb/uvm/mini_bus_coverage.svh) and
[SVA](../../tb/assertions/mini_bus_sva.sv).

## Tool boundary

The portable smoke executes SVA. Full covergroup/code/assertion coverage belongs
to Xcelium in this repository; the portable full-UVM path disables covergroups.
