# 10 — `uvm_config_db` and configuration scope

## What it solves

Direct handle assignment tightly couples hierarchy layers. `uvm_config_db#(T)`
allows an ancestor or top module to set typed configuration for a matching
component path and field name. Descendants retrieve the value during build.

The project sets the virtual interface from `tb_top` for all agent descendants.
Driver and monitor each call `get` and issue `uvm_fatal` if it is absent. Tests
set `expected_count` specifically for the scoreboard. This shows both a shared
resource and a targeted scalar configuration.

## Scope and precedence

Lookup depends on context, instance pattern, field name, type, phase, and set
order/precedence. A wildcard such as `*` is convenient but can accidentally
configure unrelated instances. Prefer the narrowest path that still supports
reuse and centralize field-name constants in large environments.

Set build-critical values before the target's build decision. Calling `set`
after a driver already failed to get its VIF is too late.

## `config_db` versus `resource_db`

`config_db` is hierarchy-oriented and is the usual choice for component
configuration. `resource_db` is a broader named/type resource pool and can be
useful outside strict hierarchy, but its wider lookup makes accidental matches
harder to debug.

## Interview-ready answer

“I pass the VIF through a typed `config_db` entry from top and retrieve it in
driver/monitor build phases with a fatal check. I keep paths narrow and set
values before construction decisions.”

## Exact `set`, `get`, `exists`, and `wait_modified`

```systemverilog
// HDL top: null context means the instance string is absolute from uvm_top.
uvm_config_db#(virtual mini_bus_if #(4, 8))::set(
  null, "uvm_test_top.env.agent.*", "vif", bus_if);

// Component: empty instance means this component's own lookup scope.
if (!uvm_config_db#(virtual mini_bus_if #(4, 8))::get(
      this, "", "vif", vif))
  `uvm_fatal("CFG/VIF", {get_full_name(), " missing vif"})

if (uvm_config_db#(int unsigned)::exists(this, "", "timeout_cycles"))
  void'(uvm_config_db#(int unsigned)::get(
    this, "", "timeout_cycles", timeout_cycles));

uvm_config_db#(bit)::wait_modified(this, "", "runtime_enable");
```

`wait_modified` is a task for intentional runtime configuration changes; most
structural configuration must remain stable after build.

## How lookup works

The database matches **type**, field name, and hierarchical scope/pattern, then
resolves precedence and set order. Common failure causes are:

- parameterized VIF type mismatch;
- a relative path evaluated from the wrong context;
- field-name spelling mismatch;
- broad wildcard shadowing an exact intent;
- `set()` executed after the receiving build phase;
- scalar value of a different typedef/signedness than expected.

For build-time settings, higher hierarchy normally has precedence; for later
same-precedence writes, the most recent setting may win. Avoid relying on subtle
precedence: use one clear owner and narrow instance scopes.

## Typed config object

```systemverilog
agent_cfg cfg = agent_cfg::type_id::create("cfg");
cfg.vif       = bus_if;
cfg.is_active = UVM_PASSIVE;
cfg.timeout   = 50;
uvm_config_db#(agent_cfg)::set(this, "env.agent", "cfg", cfg);
```

The receiver gets one handle and validates required fields. If a child may edit
configuration, give it a clone; otherwise document the object as read-only after
publication. See [Chapter 16](../16_test_env_configuration/README.md).

## Debugging configuration

Enable config-db tracing (commonly `+UVM_CONFIG_DB_TRACE`) and read the first
successful/failed lookup. Print the receiver's full name, requested type, key,
and resolved value. Avoid “fixing” a path by expanding it to `*`; that can merely
mask the intended instance and misconfigure another one.

## Interview follow-ups

1. **Why is a VIF commonly passed through config-db?** A class cannot construct
   an elaborated interface, and config-db avoids hard-coded hierarchy.
2. **Can config-db store objects?** Yes; it stores the handle. Define whether the
   recipient treats it as shared/read-only or clones it.
3. **Why prefer one config object?** It groups related policy, supports validation,
   and reduces key/path proliferation.
4. **When is `resource_db` useful?** For broader name/type lookup not naturally
   tied to component hierarchy, with careful control of ambiguity.
5. **Can a late set change built topology?** Not automatically; a child already
   omitted or created during build is unchanged.

## Common traps

- Using `this, "*"` without understanding its relative scope.
- Calling `get` repeatedly in a timing-critical loop.
- Treating missing required config as a warning and continuing with null handles.
- Sharing a mutable config object and changing it behind another component.

## Revision summary

**Config-db lookup is typed and hierarchical. Set early, scope narrowly, validate
on get, and group related policy in a typed configuration object.**
