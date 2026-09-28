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

## Exact request handshake

```systemverilog
task body();
  mini_bus_item tr;
  tr = mini_bus_item::type_id::create("tr");
  start_item(tr);                         // arbitration/grant
  if (!tr.randomize())
    `uvm_fatal("RAND", "item randomization failed")
  finish_item(tr);                        // send and wait for item_done
endtask
```

The matching driver code is:

```systemverilog
forever begin
  seq_item_port.get_next_item(req);       // waits for request
  drive_one(req);                         // consumes protocol time
  seq_item_port.item_done();              // completes exactly once
end
```

`try_next_item()` is nonblocking and may return null; it is useful only when the
driver has independent work to perform. `get()` retrieves and completes the
request in one call, so it must not later be paired with `item_done()`.

## Sequence composition

```systemverilog
task body();
  configure_seq cfg = configure_seq::type_id::create("cfg");
  traffic_seq   run = traffic_seq::type_id::create("run");
  cfg.start(m_sequencer);  // ordered dependency
  run.start(m_sequencer);
endtask
```

A parent sequence can start child sequences, but excessive nested macros obscure
which sequencer owns an item and where randomization failed. Explicit create,
configuration, and `start()` calls produce clearer logs and interviews.

## Arbitration boundary

The sequencer decides which pending sequence receives the next grant. It does
not decide DUT readiness and does not drive signals. Priority, arbitration mode,
lock, and grab affect that grant only. See
[Chapter 18](../18_advanced_sequences/README.md) for response queues, ID routing,
all arbitration modes, and cancellation behavior.

## Interview-ready answer (60–90 seconds)

“A sequence expresses stimulus relationships and creates items; a sequencer
arbitrates multiple sequences and provides the typed channel to one driver. For
each item I create through the factory, call `start_item`, randomize/check it,
then call `finish_item`. The driver pairs `get_next_item` with exactly one
`item_done` after the timed protocol operation. The sequencer controls grant
order, not pins or DUT backpressure. For responses I preserve IDs so the item
returns to the originating sequence, and for multi-interface scenarios I use a
virtual sequence.”

## Interview follow-ups

1. **`get_next_item` versus `get`?** `get_next_item` requires `item_done`; `get`
   completes the sequencer handshake when it returns the item.
2. **Can a sequencer drive the interface?** No; the driver owns signal timing.
3. **What if `item_done` is called twice?** It violates the handshake and usually
   produces a sequencer error.
4. **Why create one item per loop iteration here?** It avoids accidental handle
   reuse and lets factory overrides apply to every request.
5. **Where should an objection be raised?** Normally in the test around the
   overall scenario, not in each reusable leaf sequence.

## Revision summary

**Sequence produces, sequencer grants, driver consumes. One grant/request must
have one completion; no pin timing belongs in sequence code.**
