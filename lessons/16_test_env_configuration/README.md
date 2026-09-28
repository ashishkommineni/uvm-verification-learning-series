# Test, environment, and configuration objects

## What problem does this layer solve?

A reusable UVM bench separates **mechanism** from **policy**. Drivers, monitors,
and agents implement mechanism: they know how to move or observe one protocol.
The environment assembles those reusable blocks. The test selects policy: which
components are active, which sequence runs, how long it runs, and which error
mode is enabled. A typed configuration object carries those choices without
hard-coding them into protocol components.

Think of a laboratory. The agent is an instrument, the environment is the lab
bench, and the test is today's experiment sheet. Rewiring the instrument for
every experiment would make reuse impossible; changing a configuration object
is controlled and reviewable.

## Ownership hierarchy

```text
uvm_test_top (test)
└── env
    ├── agent
    │   ├── sequencer   [only when active]
    │   ├── driver      [only when active]
    │   └── monitor     [always present]
    ├── scoreboard
    └── coverage
```

The test creates the environment. The environment creates structural children.
The agent creates active children only when its configuration says `UVM_ACTIVE`.
This keeps construction deterministic and leaves stimulus selection in the test.

## Typed configuration object

Use one object when multiple settings belong to the same agent. This avoids a
collection of unrelated wildcard entries and gives one place for validation.

```systemverilog
class mini_bus_agent_cfg extends uvm_object;
  `uvm_object_utils(mini_bus_agent_cfg)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  virtual mini_bus_if      vif;
  bit                      checks_enable = 1;
  int unsigned             response_timeout = 20;

  function new(string name = "mini_bus_agent_cfg");
    super.new(name);
  endfunction

  function void validate();
    if (vif == null)
      `uvm_fatal("CFG/VIF", "mini_bus_agent_cfg.vif was not assigned")
    if (response_timeout == 0)
      `uvm_fatal("CFG/TIMEOUT", "response_timeout must be greater than zero")
  endfunction
endclass
```

At the test or top-level boundary:

```systemverilog
cfg = mini_bus_agent_cfg::type_id::create("cfg");
cfg.vif       = vif;
cfg.is_active = UVM_ACTIVE;
cfg.validate();
uvm_config_db#(mini_bus_agent_cfg)::set(this, "env.agent", "cfg", cfg);
```

At the agent:

```systemverilog
if (!uvm_config_db#(mini_bus_agent_cfg)::get(this, "", "cfg", cfg))
  `uvm_fatal("CFG/MISSING", {get_full_name(), " requires cfg"})
```

The exact type, field name, and instance path must match. `set()` should happen
before the receiver's `build_phase()` calls `get()`.

## Construction and execution sequence

1. The HDL top places a virtual interface in `uvm_config_db` and calls
   `run_test()`.
2. The factory creates the selected test as `uvm_test_top`.
3. The test's `build_phase()` creates/configures the environment.
4. The environment creates agents and subscribers.
5. `connect_phase()` connects TLM ports after all endpoints exist.
6. At runtime the test raises an objection, starts a sequence, waits for its
   completion, then drops the objection.
7. Scoreboard checks and reporting decide pass/fail; the sequence finishing is
   not, by itself, a proof of correctness.

## Base test versus scenario test

Put shared construction and configuration in a base test. A scenario-specific
test should change only what distinguishes that scenario.

```systemverilog
class mini_bus_base_test extends uvm_test;
  `uvm_component_utils(mini_bus_base_test)
  mini_bus_env env;
  // build_phase creates env and common configuration
endclass

class mini_bus_boundary_test extends mini_bus_base_test;
  `uvm_component_utils(mini_bus_boundary_test)
  function void build_phase(uvm_phase phase);
    mini_bus_item::type_id::set_type_override(
      boundary_bus_item::get_type());
    super.build_phase(phase);
  endfunction
endclass
```

The override occurs before factory creation of the affected item. A late
override does not retroactively replace objects that already exist.

## Where this repository demonstrates it

- [`tb_top.sv`](../../tb/top/tb_top.sv) publishes the interface and selects the
  test from the command line.
- [`mini_bus_tests.svh`](../../tb/uvm/mini_bus_tests.svh) owns scenario policy.
- [`mini_bus_env.svh`](../../tb/uvm/mini_bus_env.svh) builds reusable structure.
- [`mini_bus_agent.svh`](../../tb/uvm/mini_bus_agent.svh) implements active and
  passive modes.
- [`agent_config_example.sv`](../../examples/configuration/agent_config_example.sv)
  is a linted typed-configuration reference.

## Interview-ready answer (60–90 seconds)

“I keep the test, environment, and agent responsibilities separate. The test
selects scenario policy and starts sequences; the environment constructs and
connects reusable verification components; the agent encapsulates one protocol
interface. Settings such as active/passive mode, virtual interface, checks, and
timeouts travel in a typed configuration object through `uvm_config_db`. The
agent retrieves and validates that object during build, creates a driver and
sequencer only in active mode, and always creates the monitor. This design lets
the same environment serve directed, random, passive-monitoring, and error tests
without editing the protocol components.”

## Interview follow-ups

1. **Why not put the virtual interface in a static package variable?** It breaks
   clean instance-level configuration and becomes ambiguous with multiple agents.
2. **Why use a config object instead of ten scalar entries?** It groups related
   policy, enables validation, and reduces wildcard/key mistakes.
3. **Can a test create a driver directly?** It can, but doing so couples scenario
   policy to protocol structure and damages reuse.
4. **What belongs in `connect_phase()`?** TLM connections and handle wiring that
   require both endpoints to have been built.
5. **How do you create two differently configured agents?** Create two config
   object instances and set each at its exact agent path.

## Common traps

- Setting with `"*"` and accidentally configuring unrelated instances.
- Forgetting `super.build_phase(phase)` in a derived component.
- Calling `new` for factory-controlled UVM components instead of `type_id::create`.
- Starting traffic before reset/configuration is complete.
- Treating “sequence ended” as “test passed” without scoreboard status.

## Revision summary

**Test = policy, environment = integration, agent = protocol unit, config object
= instance policy.** Build first, connect second, run third, and let independent
checkers determine the result.
