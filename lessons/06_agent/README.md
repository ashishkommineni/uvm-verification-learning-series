# 06 — Active and passive agents

## Agent as a reusable protocol container

An agent groups the protocol-specific sequencer, driver, and monitor. In active
mode it generates traffic and observes it; in passive mode it instantiates only
the monitor. The environment can therefore reuse the same monitor on interfaces
driven by another master or at subsystem/SoC level.

`mini_bus_agent` always creates its monitor. It creates and connects driver and
sequencer only when `get_is_active() == UVM_ACTIVE`. This conditional structure
is the key behavior—not simply placing three files in one directory.

See [`mini_bus_agent.svh`](../../tb/uvm/mini_bus_agent.svh).

## Configuration timing

Active/passive mode must be configured before the agent's `build_phase` makes
its construction decision. A late setting cannot recreate missing components.
The same principle applies to many build-time configuration values.

## Scaling

At block level, one active agent drives the DUT. At subsystem level, one agent
may stay active while other instances become passive observers. At SoC level,
protocol VIP can be reused with virtual sequences coordinating multiple agents.

## Common mistake

Connecting `driver.seq_item_port` unconditionally causes a null-handle failure
in passive mode. Guard both construction and connection with the same mode.
