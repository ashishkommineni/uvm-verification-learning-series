# 11 — Virtual sequencers and virtual sequences

## Why they are needed

A single protocol sequence starts on one protocol sequencer. A system scenario
may need reset, control-bus programming, DMA traffic, interrupts, and data flow
coordinated across several agents. A virtual sequence expresses that scenario
without driving pins itself.

A virtual sequencer is an optional component that stores handles to lower-level
sequencers. A virtual sequence starts child sequences on those handles, often
using `fork...join` or ordered calls. It should not duplicate protocol timing.

The focused [coordination example](../../examples/virtual_sequences/coordination_example.sv)
contains two mini-bus sequencer handles and starts directed and random child
sequences concurrently. A real subsystem environment would connect those
handles during `connect_phase`.

## When not to use one

For one agent, the test can start a normal sequence directly. Adding a virtual
sequencer with no coordination need creates hierarchy and null-handle failure
opportunities without value.

## Common mistakes

- Starting a child sequence on a null sequencer handle.
- Using `p_sequencer` without verifying the actual sequencer type.
- Hiding all test intent in a monolithic virtual sequence.
- Forgetting reset/order dependencies when using `fork`.

## Wiring the virtual sequencer

```systemverilog
class system_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(system_virtual_sequencer)
  mini_bus_sequencer control_sqr;
  mini_bus_sequencer data_sqr;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

function void system_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  virtual_sqr.control_sqr = control_agent.sequencer;
  virtual_sqr.data_sqr    = data_agent.sequencer;
endfunction
```

These are handle assignments, not TLM connections. Validate them before starting
a scenario so a configuration error fails at time zero.

## Typed access from a virtual sequence

```systemverilog
class boot_and_traffic_vseq extends uvm_sequence;
  `uvm_object_utils(boot_and_traffic_vseq)
  `uvm_declare_p_sequencer(system_virtual_sequencer)

  task body();
    boot_seq    boot = boot_seq::type_id::create("boot");
    traffic_seq data = traffic_seq::type_id::create("data");
    if (p_sequencer.control_sqr == null || p_sequencer.data_sqr == null)
      `uvm_fatal("VSEQ/NULL", "physical sequencer handle missing")
    boot.start(p_sequencer.control_sqr);
    data.start(p_sequencer.data_sqr);
  endtask
endclass
```

`m_sequencer` is the generic base handle. The macro casts it to typed
`p_sequencer`; a wrong actual sequencer type causes a fatal cast failure. An
alternative is to place explicit physical-sequencer handles directly in the
virtual sequence through a scenario config object, which reduces coupling to a
virtual-sequencer component.

## Ordered and concurrent orchestration

Sequential `start()` calls express a dependency such as configure before
traffic. `fork...join` starts independent child sequences concurrently;
`fork...join_any` requires explicit cancellation/cleanup of survivors. Use an
event or state check for real dependencies instead of fixed delays.

```systemverilog
reset_seq.start(reset_sqr);
program_seq.start(control_sqr);
fork
  ingress_seq.start(input_sqr);
  irq_service_seq.start(irq_sqr);
join
```

The virtual sequence should coordinate *what/when*. Each child protocol sequence
and driver still own its transaction construction and pin timing.

## Objection policy

Prefer the test to raise an objection around the top-level virtual sequence. If
a standalone default sequence must raise its own objection, use `starting_phase`
carefully and document the policy. Mixing test-owned and child-owned objections
can leave the test alive after intended completion.

## Interview-ready answer (60–90 seconds)

“A virtual sequence coordinates a system scenario across multiple protocol
sequencers but never drives pins. An optional virtual sequencer is a component
that stores handles to those physical sequencers; the environment assigns the
handles in connect phase. The virtual sequence creates child sequences and
starts them in dependency order or concurrently. I validate all handles, keep
protocol timing in child drivers, and let the test own the scenario objection.
For a single agent I start its sequence directly because a virtual layer adds no
value.”

## Interview follow-ups

1. **Does a virtual sequencer connect to a driver?** No; physical protocol
   sequencers connect to drivers. The virtual sequencer stores coordination handles.
2. **Is `p_sequencer` mandatory?** No; explicit typed handles are an alternative.
3. **Why can `fork...join_any` leak traffic?** Remaining child sequences continue
   unless deliberately killed or allowed to finish.
4. **Where are physical handles assigned?** Usually in environment connect phase
   after all agents exist.
5. **Virtual sequence versus layered sequence?** Virtual coordinates several
   sequencers; layered transforms one transaction abstraction into another.

## Revision summary

**Virtual sequence coordinates scenario dependencies; physical sequences create
protocol items; drivers own pins. Validate handles and keep objection ownership
clear.**
