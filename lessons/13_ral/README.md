# 13 — Register abstraction layer (RAL)

## What problem RAL solves

Large designs contain hundreds or thousands of registers. Hand-writing bus
transactions and mirror checks for each register duplicates address, field,
access-policy, and reset knowledge. RAL models registers, fields, maps, access
rights, reset values, and mirrored/desired state in reusable objects.

## Main pieces

- `uvm_reg_field`: bit position, width, access policy, reset.
- `uvm_reg`: a logical register containing fields.
- `uvm_reg_block`: hierarchy and one or more address maps.
- `uvm_reg_map`: bus address, byte width, and endianness.
- Adapter: converts between `uvm_reg_bus_op` and a protocol item.
- Predictor: updates the mirror from monitor-observed bus traffic.

The [focused RAL example](../../examples/ral/mini_reg_model.sv) defines an
8-bit control register, block/map, and mini-bus adapter.

## Frontdoor, backdoor, desired, mirrored, actual

Frontdoor access uses the real bus and verifies integration. Backdoor access
touches HDL state directly and is useful for setup/checks when deliberately
mapped. Desired is what the model wants; mirrored is what the model believes;
actual is DUT state. They can differ until prediction/read/write updates them.

## Prediction

Auto-predict is simple for model-initiated accesses. An explicit predictor fed
by the monitor also sees other bus masters and is safer in a shared system.

## Build order and exact model skeleton

```systemverilog
class control_reg extends uvm_reg;
  `uvm_object_utils(control_reg)
  rand uvm_reg_field enable;

  function new(string name = "control_reg");
    super.new(name, 8, UVM_NO_COVERAGE);
  endfunction

  function void build();
    enable = uvm_reg_field::type_id::create("enable");
    enable.configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 0);
  endfunction
endclass
```

The block creates registers, calls each register's `configure` and `build`, then
creates an address map and calls `add_reg`. Finally it calls `lock_model()` after
the complete hierarchy exists. The environment then assigns HDL paths/backdoor
information and connects the map to a bus sequencer and adapter.

## Adapter directions

```systemverilog
virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
  // Convert UVM_READ/UVM_WRITE, address, data, and byte enables to protocol item.
endfunction

virtual function void bus2reg(uvm_sequence_item bus_item,
                              ref uvm_reg_bus_op rw);
  // Cast item, return kind/address/data/status for prediction.
endfunction
```

Set `supports_byte_enable` and `provides_responses` to match real adapter/driver
behavior. A wrong response policy can make a frontdoor access wait forever or
predict from the wrong object.

## Desired, mirrored, and actual state

| Operation | Meaning |
|---|---|
| `set(value)` | Change desired model value only |
| `get()` | Read desired value from the model |
| `get_mirrored_value()` | Read predicted/mirrored value |
| `update()` | Write fields whose desired differs from mirror |
| `mirror()` | Read DUT and optionally compare/update mirror |
| `read()/write()` | Explicit frontdoor/backdoor DUT access |
| `predict()` | Update model based on externally observed result |
| `reset()` | Reset model values only; does not drive DUT reset |

This distinction is a frequent interview point: calling `model.reset()` cannot
reset hardware, and calling `set()` cannot program a register until `update()` or
a write occurs.

## Frontdoor, backdoor, and prediction

Frontdoor accesses validate the bus path and side effects. Backdoor accesses are
fast but require correct HDL paths and may bypass access side effects. For shared
buses, connect `uvm_reg_predictor` to the protocol monitor, supply the same
adapter, and usually disable simple auto-predict to avoid double prediction.

Volatile, read-clear, write-one-to-clear, and read-only fields need correct access
policy and prediction. The model cannot infer a hardware side effect that the
monitor/adapter fails to describe.

## Built-in sequence caution

RAL bit-bash, reset, access, and memory sequences are useful, but exclude or
special-case registers with destructive reads, volatile status, write-only
fields, lock bits, or external side effects. “Run every built-in sequence” is
not a safe signoff strategy without model metadata and exclusions.

## Interview-ready answer (60–90 seconds)

“UVM RAL centralizes registers, fields, access rights, reset values, and maps so
tests do not hand-code bus addresses. A register block builds and locks the model;
an adapter translates `uvm_reg_bus_op` to protocol items and back; the map uses a
bus sequencer for frontdoor access. Desired is what software wants, mirrored is
what the model predicts, and actual is hardware. In a shared system I connect an
explicit predictor to monitor-observed traffic so accesses from any master update
the mirror. I use backdoor carefully because it can bypass bus integration and
side effects.”

## Interview follow-ups

1. **Does `set()` write the DUT?** No; it changes desired model state.
2. **Does `reset()` reset hardware?** No; it resets model values.
3. **Why use an explicit predictor?** It sees observed accesses from all masters
   and keeps the mirror synchronized with bus truth.
4. **What does `lock_model()` do?** Finalizes model structure/addressing after
   build; add all registers/maps first.
5. **Why can bit-bash be unsafe?** Some fields are volatile, destructive,
   write-only, locked, or have side effects.

## Revision summary

**Block owns registers/maps, adapter translates, sequencer drives frontdoor,
predictor follows observed traffic, and desired/mirrored/actual are distinct.**
