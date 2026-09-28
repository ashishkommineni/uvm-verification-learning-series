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
