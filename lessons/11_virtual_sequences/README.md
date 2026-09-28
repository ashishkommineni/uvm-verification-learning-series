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
