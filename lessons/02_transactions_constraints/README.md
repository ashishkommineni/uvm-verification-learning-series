# 02 — Transactions, fields, constraints, and object operations

## Transaction as an abstraction

A transaction describes one logical operation without embedding clock-edge
details. `mini_bus_item` contains operation, address, write data, and observed
response data. The driver decides *when* these fields reach pins; the monitor
decides when a completed operation exists.

The item uses `rand` fields plus an equal-weight `dist` constraint for read and
write selection. `boundary_bus_item` derives from it and adds an address
constraint for only 0 and 15. Because the sequence requests the base type via
the factory, a test can replace it without rewriting the sequence.

## Randomization contract

`randomize()` returns a bit. A zero return is a verification failure, not a
minor warning: fields can retain stale values. The random sequence checks every
call and issues `uvm_fatal` before sending an invalid item.

Inline constraints express one-scenario intent. Class constraints continue to
apply, so conflicting hard constraints fail. `soft` constraints are useful for
defaults that tests may legally replace.

## Copy, compare, and print

Handle assignment aliases the same object; it is not a copy. The item provides
explicit `do_copy`, `do_compare`, and `convert2string` methods so ownership and
debug output remain visible. Nested handles require a deliberate deep-copy
policy.

Study [`mini_bus_item.svh`](../../tb/uvm/mini_bus_item.svh).

## Interview trap

Functional coverage is not guaranteed by `randc`, `dist`, or many seeds. Those
control generation; coverage measures what was actually observed.
