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

## Build and connect pattern

```systemverilog
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  monitor = mini_bus_monitor::type_id::create("monitor", this);
  if (get_is_active() == UVM_ACTIVE) begin
    sequencer = mini_bus_sequencer::type_id::create("sequencer", this);
    driver    = mini_bus_driver::type_id::create("driver", this);
  end
endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (get_is_active() == UVM_ACTIVE)
    driver.seq_item_port.connect(sequencer.seq_item_export);
endfunction
```

The agent normally exposes the monitor's analysis port or lets the environment
connect directly to it. Protocol-independent scoreboards and coverage remain in
the environment; agent-internal protocol checks may remain inside the agent.

## Configuration object pattern

For more than active/passive mode, use a typed configuration object containing
the VIF, checks/coverage enables, timeout, and protocol role. Retrieve and
validate it before deciding which children to create. Chapter 16 provides the
complete pattern and linted example.

## Multi-agent example

A subsystem might instantiate:

| Instance | Mode | Purpose |
|---|---|---|
| `ctrl_agent` | Active | Programs DUT registers |
| `input_agent` | Active | Generates incoming traffic |
| `output_agent` | Passive | Observes DUT-produced traffic |
| `tap_agent` | Passive | Collects system-level coverage |

Each instance needs its own config object and VIF. A wildcard VIF assignment can
silently connect two agents to the wrong interface, so prefer exact paths.

## Interview-ready answer (60–90 seconds)

“An agent packages all verification components for one protocol interface. In
active mode it creates sequencer, driver, and monitor; in passive mode it creates
only the monitor, so the same observation and checking code works at block and
SoC levels. I retrieve a typed agent configuration during build, validate its
VIF and policy, and guard both active-child creation and driver-sequencer
connection with the same mode. The environment connects monitor analysis to
system-level scoreboards and coverage.”

## Interview follow-ups

1. **Why always create the monitor?** Observation is required in both active and
   passive modes and provides independent checker evidence.
2. **Where is active/passive configured?** Before agent build, usually through a
   typed config object or `is_active` setting.
3. **Can an agent contain a scoreboard?** A protocol-local checker can, but
   end-to-end/reference-model scoreboards normally belong in the environment.
4. **Why not create inactive children then leave them idle?** It complicates
   topology/configuration and can leave unexpected connections or processes.
5. **How is the agent reused at SoC?** Configure it passive on externally driven
   interfaces while retaining its monitor, assertions, and coverage.

## Revision summary

**Agent = reusable protocol container. Monitor always; driver and sequencer only
when active; configuration must be resolved before construction.**
