# 01 — `uvm_object` and `uvm_component`

## Basic distinction

`uvm_object` is lightweight data or policy. It has no permanent hierarchy and
no automatic build/run phases. Transactions, sequences, configuration objects,
callbacks, and register-model objects belong here.

`uvm_component` is a persistent node in the testbench hierarchy. It has a name,
parent, full hierarchical path, phase callbacks, reporting context, and TLM
connections. Drivers, monitors, agents, environments, and tests are components.

The practical question is not “which base class is popular?” It is “does this
thing represent temporary data/policy, or does it own long-lived behavior and
connections?”

## Construction

Objects normally use `new(string name="...")`; components use
`new(string name, uvm_component parent)`. The parent creates the hierarchy that
controls phase traversal, `config_db` lookup, instance overrides, and report
paths.

Use `type_id::create` for factory-controlled construction. Calling `new`
directly bypasses factory overrides even if the class is registered.

Examples:

- [`mini_bus_item`](../../tb/uvm/mini_bus_item.svh) is an object.
- [`mini_bus_monitor`](../../tb/uvm/mini_bus_monitor.svh) is a component.
- [`mini_bus_random_sequence`](../../tb/uvm/mini_bus_sequences.svh) is an object
  that executes temporarily on a sequencer component.

## Common mistakes

- Giving an item a component parent: items should not live in hierarchy.
- Creating a driver with `new`: the factory cannot replace it.
- Assuming factory registration alone enables override: construction must also
  go through `create`.

## Interview-ready answer

“Objects model dynamic data or policy; components model persistent structure
and behavior. Components have hierarchy and phases. I use factory `create` for
both when I need overrides, but only components receive a parent.”
