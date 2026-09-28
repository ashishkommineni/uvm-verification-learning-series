# 03 — Sequences and sequencers

## Why two layers?

A sequence describes scenario policy: which transactions to create and in what
relationship. A sequencer arbitrates requests from one or more sequences and
implements the typed request/response channel to the driver. The sequencer does
not drive pins.

For an item, `start_item` obtains permission and `finish_item` randomizes or
finalizes the fields before completing the request handshake. In the driver,
`get_next_item` must be paired exactly once with `item_done`; missing or double
completion causes deadlock or protocol corruption.

## Project examples

The directed sequence sends four known operations. The random sequence creates
its item through the factory on every iteration. Its optional
`guarantee_operation_mix` mode directs the first two operation fields after
successful randomization to one write and one read, avoiding a statistically
possible all-read or all-write test. Address and data remain constrained-random.

See [`mini_bus_sequences.svh`](../../tb/uvm/mini_bus_sequences.svh).

## Arbitration and responses

Multiple sequences can compete using arbitration, priority, lock, or grab.
Use lock/grab sparingly because forgotten release can starve other traffic.
For response-carrying protocols, preserve transaction IDs and decide whether
the driver calls `item_done(response)` or uses a response port.

## Debug checklist

When a sequence hangs, find the last grant/request log; then inspect
`start_item/finish_item`, `get_next_item/item_done`, reset waits, lock release,
response waits, and sequencer-driver connection.
