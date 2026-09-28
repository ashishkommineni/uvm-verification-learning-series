# 09 — Factory and overrides

## Why the factory exists

The factory separates the requested base type from the concrete type created at
run time. This lets a test change behavior without editing reusable environment
or sequence source. Registration supplies a wrapper; `type_id::create` asks the
factory to resolve overrides and construct the result.

Type override replaces every request of a type. Instance override affects only
a matching hierarchical construction path. Instance overrides are more precise
but fragile if paths are guessed; print topology and factory debug information.

## Executable example

`mini_bus_boundary_test` sets a type override from `mini_bus_item` to
`boundary_bus_item`. The unchanged random sequence requests the base type, and
the factory returns the derived object constrained to addresses 0 and 15. The
test also enables an operation-mix guard so the first two operation fields
guarantee at least one write and one read without bypassing the address
constraint.

See [item definitions](../../tb/uvm/mini_bus_item.svh) and
[tests](../../tb/uvm/mini_bus_tests.svh).

## Factory versus callback versus configuration

- Factory: replace an implementation/type.
- Callback: inject a narrow policy at an explicit hook.
- Configuration: provide data such as mode, count, or interface handle.

Use the least-coupled mechanism that matches the change.
