# 04 — Driver and virtual interface

## Role of the driver

The driver is the transaction-to-signal adapter. It receives an item, applies
protocol timing, waits for completion, reports a timing failure if needed, and
only then calls `item_done`. Scenario generation does not belong in the driver;
that would reduce reuse and make stimulus invisible to sequence control.

## Why a virtual interface?

Class objects cannot contain statically elaborated wires. A SystemVerilog
interface bundles the DUT signals and clocking semantics, while a virtual
interface is the class-side handle to that instance. The top places the handle
in `uvm_config_db`; driver and monitor retrieve it during `build_phase` and
fail early if it is missing.

Clocking blocks separate sampling from driving and reduce races. The driver
uses `driver_cb`; the monitor uses a read-only sampling view. The driver waits
for reset, drives one request, checks the response, then returns signals idle.

Relevant code:

- [Interface](../../tb/interfaces/mini_bus_if.sv)
- [Driver](../../tb/uvm/mini_bus_driver.svh)
- [Top-level configuration](../../tb/top/tb_top.sv)

## Common mistakes

- Driving pins directly from a sequence.
- Using `#delay` instead of clock/protocol events.
- Calling `item_done` before the transfer is actually complete.
- Ignoring reset in the driver.
- Letting driver and monitor sample the same edge without clocking discipline.
