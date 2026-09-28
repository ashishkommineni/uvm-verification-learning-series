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
