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

## Relevant class hierarchy

```text
uvm_void
└── uvm_object
    ├── uvm_transaction
    │   └── uvm_sequence_item
    ├── uvm_sequence_base
    ├── uvm_callback
    └── uvm_component
        ├── uvm_driver / uvm_monitor / uvm_sequencer
        ├── uvm_agent / uvm_env
        └── uvm_test
```

`uvm_component` ultimately derives from `uvm_object`, so components also have
names, factory identity, printing, and reporting support. Their important extra
contract is hierarchy plus phase participation.

## Exact syntax

```systemverilog
class packet extends uvm_sequence_item;
  `uvm_object_utils(packet)
  function new(string name = "packet");
    super.new(name);
  endfunction
endclass

class packet_monitor extends uvm_monitor;
  `uvm_component_utils(packet_monitor)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
```

Use `uvm_object_utils_begin/end` or `uvm_component_utils_begin/end` only when
field automation is actually desired. Registration macros do not construct the
instance and do not automatically perform a factory override.

```systemverilog
packet         tr  = packet::type_id::create("tr");
packet_monitor mon = packet_monitor::type_id::create("mon", this);
```

The object name aids reports/recording. The component parent creates the full
path, for example `uvm_test_top.env.agent.monitor`.

## Lifetime and ownership

Components live for the test duration and UVM manages phase callbacks. Objects
can be stack-local handles, queue entries, config values, or transient sequence
items. SystemVerilog garbage-collects a class instance after no handle refers to
it, but UVM ownership conventions still matter: two handles may alias one object.

```systemverilog
packet a, b;
a = packet::type_id::create("a");
b = a;          // alias, not an independent packet
$cast(b, a.clone()); // independent object using copy semantics
```

## Decision table

| Requirement | Choose |
|---|---|
| Needs build/run phases | `uvm_component` |
| Owns a persistent TLM port | Usually `uvm_component` |
| Represents one transfer | `uvm_sequence_item` |
| Represents temporary scenario behavior | `uvm_sequence` |
| Carries reusable settings | `uvm_object` config class |
| Inserts optional hook behavior | `uvm_callback` |

## Interview follow-ups

1. **Can a component be cloned?** Although it inherits object APIs, cloning a
   component is not a valid way to duplicate hierarchy; create it through the
   factory with the correct parent.
2. **Why does a component constructor need a parent?** The parent establishes
   hierarchy for phases, paths, reporting, config lookup, and instance overrides.
3. **What happens if `new` replaces factory `create`?** The type is fixed and
   registered overrides are bypassed.
4. **Is a sequence a component?** No. It is a temporary object that executes on
   a sequencer.
5. **When should you hand-write `do_copy`?** When nested objects, queues, derived
   state, or performance require explicit ownership and field policy.

## Debug exercise

If an instance override does not work, confirm registration, factory-based
creation, requested base type, construction path, and that the override was set
before creation. `uvm_factory::get().print()` and topology output make those
facts visible.

## Revision summary

**Object means dynamic data/policy; component means persistent hierarchy and
phases. Registration enables the factory; `type_id::create()` uses it.**
