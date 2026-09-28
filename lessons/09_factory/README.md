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

## Registration and creation

```systemverilog
class boundary_bus_item extends mini_bus_item;
  `uvm_object_utils(boundary_bus_item)
  function new(string name = "boundary_bus_item");
    super.new(name);
  endfunction
endclass

mini_bus_item req;
req = mini_bus_item::type_id::create("req");
```

The macro registers a proxy for the type. `create()` asks the factory to resolve
overrides and then construct it. Neither step alone is sufficient.

## Type and instance overrides

```systemverilog
mini_bus_item::type_id::set_type_override(boundary_bus_item::get_type());

mini_bus_driver::type_id::set_inst_override(
  error_inject_driver::get_type(), "uvm_test_top.env.agent.driver");
```

Set overrides before the target is created. Type override applies to all future
requests for the original type; instance override applies only when requested at
the matching full construction path. Instance overrides usually take precedence
for their matched location.

Use `replace=0` or `replace=1` deliberately for repeated type overrides; silently
overwriting another test's policy makes regressions order-dependent.

## Parameterized classes

Each parameter specialization is a distinct SystemVerilog type and factory
registration. A common typedef gives it a stable readable name:

```systemverilog
typedef packet_driver #(32) packet32_driver;
```

Overrides must use compatible specializations; a 64-bit driver cannot replace a
32-bit base merely because their class templates share a name. Parameterized
classes normally use `` `uvm_object_param_utils`` or
`` `uvm_component_param_utils`` rather than the non-parameterized registration
macros; factory type-name printing may be less informative unless the project
adds an explicit naming convention.

## Factory debug procedure

1. Confirm both base and override classes are registered.
2. Confirm the reusable code requests the expected base via `type_id::create`.
3. Confirm the override executes before creation.
4. For instance override, print topology and copy the exact path.
5. Call factory debug/print and inspect requested versus produced type.
6. Log `req.get_type_name()` at the use point.

## Interview-ready answer (60–90 seconds)

“The UVM factory separates the requested type from the concrete type created at
runtime. I register classes with the appropriate object/component macro and make
reusable code call `type_id::create`. A type override replaces every future
request of a base type; an instance override applies only to a matching component
construction path. Overrides must be installed before creation. I use the
factory for implementation substitution, config objects for data, and callbacks
for narrow hooks, then debug with topology, factory print, and actual type names.”

## Interview follow-ups

1. **Why did an override not affect an item made with `new`?** `new` bypasses
   factory resolution.
2. **Does override change an existing object?** No; it affects future creates.
3. **String versus type override APIs?** Type-based APIs provide compile-time
   checking and are preferred where available.
4. **Why is an instance override fragile?** It depends on an exact construction
   path that hierarchy refactoring can change.
5. **Factory or callback for one optional log hook?** Callback; replacing the
   entire component is excessive.

## Revision summary

**Register + create + early override. Type override is broad; instance override
is path-specific; factory changes implementation, not configuration data.**
