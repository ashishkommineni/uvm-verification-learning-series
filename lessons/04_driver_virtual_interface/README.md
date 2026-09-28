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

## Exact configuration and type match

```systemverilog
virtual mini_bus_if #(MINI_ADDR_WIDTH, MINI_DATA_WIDTH) vif;

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual mini_bus_if #(
        MINI_ADDR_WIDTH, MINI_DATA_WIDTH))::get(this, "", "vif", vif))
    `uvm_fatal("NOVIF", "driver did not receive vif")
endfunction
```

The parameterized virtual-interface type in `set()` and `get()` must match
exactly. A non-parameterized or differently parameterized type occupies a
different config-db type namespace.

## Clocking-block timing

```systemverilog
clocking driver_cb @(posedge clk);
  default input #1step output #0;
  output req, write, address, write_data;
  input  ready, response_valid, read_data;
endclocking
```

The driver writes clocking-block outputs at the event; inputs sampled with
`#1step` represent values immediately before the edge. This avoids an unordered
active-region race between the DUT and class code. Nonblocking assignment to
clocking outputs also makes drive intent explicit.

## Driver state flow

For this bus the driver performs:

1. Initialize all owned outputs to idle.
2. Wait until reset is known deasserted.
3. Get exactly one item from the sequencer.
4. Invoke the documented pre-drive callback.
5. Drive request fields at `driver_cb`.
6. Release request after the acceptance edge.
7. Sample `response_valid` on the following defined edge.
8. Report a missing response and complete the sequencer handshake.

For a protocol with backpressure, hold request and payload stable until
`valid && ready`, with a timeout or reset escape. Do not call `item_done()` merely
because request was presented; define completion from the protocol contract.

## Request versus response ownership

The sequence owns request intent until it sends the item. The driver must not
quietly randomize or rewrite scenario fields. If returned status/data matters to
the sequence, the driver creates a separate response, calls
`rsp.set_id_info(req)`, and returns it through `item_done(rsp)` or the response
port. Monitor observations remain separate and feed the checker.

## Reset edge case

If reset asserts while the driver has checked out an item, the design must state
whether the operation is aborted, retried, or completed with an error response.
Leaving the item checked out makes `finish_item()` hang. Chapter 21 defines the
full driver/monitor/scoreboard reset contract.

## Interview-ready answer (60–90 seconds)

“The driver is the only active transaction-to-pin adapter. It retrieves a typed
request from the sequencer, drives it through a virtual interface clocking block,
waits for the protocol-defined completion, and calls `item_done` exactly once.
The top publishes the interface through a type-matched config-db entry and the
driver fails in build if it is missing. Clocking-block skew avoids DUT/testbench
sampling races. I keep scenario randomization out of the driver and define an
explicit abort/retry policy so reset cannot strand a checked-out sequence item.”

## Interview follow-ups

1. **Why not access `dut.signal` hierarchically?** It hard-codes hierarchy,
   prevents instance reuse, and bypasses interface timing/modport discipline.
2. **Why call `item_done` after completion?** It prevents the sequence from
   assuming an operation completed before the timed driver work is finished.
3. **What must remain stable under stall?** Request-valid and all associated
   payload/control fields until acceptance.
4. **Can the driver publish to the scoreboard?** It can publish debug intent, but
   correctness should use monitor-observed interface activity.
5. **What causes a VIF get failure?** Wrong type/parameters, key, instance path,
   context, or a set that occurred too late.

## Revision summary

**Driver owns active timing, VIF owns signal access, clocking block owns race-free
sampling/drive semantics, and the protocol defines when `item_done` is legal.**
