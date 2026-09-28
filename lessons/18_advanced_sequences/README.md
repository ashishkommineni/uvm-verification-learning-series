# Advanced sequences, arbitration, locks, and responses

## Why this topic matters

A basic sequence can generate one item, but real benches have concurrent traffic,
priority changes, protocol responses, reset interruption, and coordination across
interfaces. Those cases are controlled by the sequencer/driver handshake—not by
adding arbitrary delays inside the sequence.

## One request: exact control flow

```systemverilog
task body();
  mini_bus_item req;
  req = mini_bus_item::type_id::create("req");

  start_item(req);                    // wait for grant; pre_do runs on grant
  if (!req.randomize() with { write == 1; })
    `uvm_fatal("RAND", "request randomization failed")
  finish_item(req);                   // mid_do, send, wait item_done, post_do
endtask
```

Internally, `start_item()` associates the item with this sequence/sequencer and
waits for arbitration. `finish_item()` sends the finalized item and waits until
the driver calls `item_done()`. Randomize **between** these calls; changing the
item after `finish_item()` begins creates a race with the driver.

Equivalent lower-level flow is:

```systemverilog
wait_for_grant();
assert(req.randomize());
send_request(req);
wait_for_item_done();
```

Prefer `start_item/finish_item` unless teaching or implementing a specialized
protocol because they preserve the expected callback flow.

## Sequencer arbitration and priority

Multiple sequences may request the same sequencer. Its arbitration mode decides
which granted request proceeds.

| Mode | Selection idea |
|---|---|
| `UVM_SEQ_ARB_FIFO` | Earliest request first |
| `UVM_SEQ_ARB_WEIGHTED` | Random selection weighted by priority |
| `UVM_SEQ_ARB_RANDOM` | Random requester |
| `UVM_SEQ_ARB_STRICT_FIFO` | Highest priority, FIFO among equals |
| `UVM_SEQ_ARB_STRICT_RANDOM` | Highest priority, random among equals |
| `UVM_SEQ_ARB_USER` | User-defined `user_priority_arbitration()` |

```systemverilog
sequencer.set_arbitration(UVM_SEQ_ARB_STRICT_FIFO);
hi_seq.start(sequencer, null, 500); // third argument is priority
```

Priority influences arbitration; it does not preempt an item already granted to
the driver.

## `lock()` versus `grab()`

Both reserve a sequencer across multiple items. `lock()` enters the normal
arbitration queue; `grab()` requests ahead of ordinary queued requests. The
current item still completes before ownership changes.

```systemverilog
lock(m_sequencer);
send_header();
send_payload();
unlock(m_sequencer);
```

Use the shortest possible lock window. Calling another sequence that waits on the
same locked sequencer can self-deadlock. `grab()` is appropriate only for urgent
traffic such as an interrupt response; routine use can starve other sequences.

## Request/response path and IDs

A driver may complete a request without a response:

```systemverilog
seq_item_port.get_next_item(req);
drive(req);
seq_item_port.item_done();
```

When the sequence needs returned data/status, create a response, copy sequence
and transaction IDs, then return it:

```systemverilog
seq_item_port.get_next_item(req);
drive_and_sample(req, rsp);
rsp.set_id_info(req);
seq_item_port.item_done(rsp);
```

The sequence consumes it with `get_response(rsp)`. IDs route responses to the
originating sequence when several sequences share a sequencer. A missing
`get_response()` can eventually overflow the response queue; a missing
`set_id_info()` can route or match incorrectly.

For pipelined/out-of-order protocols, preserve a protocol transaction ID in the
item as well. UVM sequence IDs solve sequence routing; they do not replace the
DUT protocol's ordering rules.

## Sequence lifetime and cancellation

- `pre_start`, `pre_body`, `body`, `post_body`, and `post_start` form the normal
  callback flow. Whether a child calls `pre_body/post_body` depends on how it is
  started (`call_pre_post`).
- `kill()` stops a sequence; cleanup code in `post_body()` is not guaranteed to
  run. Release external resources through a design that tolerates cancellation.
- A sequence should not normally own the test objection. The test controls test
  lifetime; a reusable sequence controls stimulus.
- Default phase sequences are compact but hide control and complicate debug.
  Explicitly starting sequences from a test or virtual sequence is clearer.

## Layered and virtual sequences

A layered sequence transforms one abstraction into another on a sequencer path,
for example register operations into bus transfers. A virtual sequence has no
driver; it coordinates child sequences on multiple physical sequencers.

```systemverilog
fork
  bus_seq.start(p_sequencer.bus_sqr);
  irq_seq.start(p_sequencer.irq_sqr);
join
```

Use `uvm_declare_p_sequencer` only when the convenience of a typed handle
outweighs the tighter coupling. An explicit handle assigned through configuration
is often easier to reuse and unit test.

## Where this repository demonstrates it

- Basic/directed/random sequences: [`mini_bus_sequences.svh`](../../tb/uvm/mini_bus_sequences.svh)
- Virtual coordination: [`coordination_example.sv`](../../examples/virtual_sequences/coordination_example.sv)
- Request/response IDs: [`response_example.sv`](../../examples/sequence_control/response_example.sv)

## Interview-ready answer (60–90 seconds)

“A sequence creates transaction intent and a sequencer arbitrates when multiple
sequences want one driver. `start_item` waits for a grant; I randomize next; then
`finish_item` sends the stable request and waits for the driver's `item_done`.
Arbitration modes and start priority decide among pending requests but never
preempt an item already granted. For an atomic multi-item operation I use a short
`lock`; `grab` has more urgent queue semantics and can cause starvation. If the
driver returns a response, it copies ID information from the request and calls
`item_done(rsp)`, while the sequence calls `get_response`. Virtual sequences
coordinate several sequencers but do not drive pins themselves.”

## Interview follow-ups

1. **Where should randomization occur?** Between `start_item()` and
   `finish_item()` after the grant and before the item is sent.
2. **Does a higher priority interrupt the current item?** No; it affects the next
   arbitration decision.
3. **Why can a sequence hang at `finish_item()`?** The driver may never call
   `item_done()`, reset may stall it, or the connection may be missing.
4. **Why call `set_id_info(req)`?** To copy routing IDs so the response returns to
   the correct originating sequence.
5. **When should the test raise objections?** Around scenario execution and any
   required drain; reusable leaf sequences normally should not own lifetime.

## Common traps

- Using a request handle before `type_id::create()`.
- Ignoring `randomize()` return status.
- Adding `#delay` to “fix” sequencer timing.
- Holding a lock while waiting for work that also requires that sequencer.
- Starting child traffic on a null sequencer handle.
- Ending the test while a driver or scoreboard still has an outstanding item.

## Revision summary

**Grant, randomize, send, complete, optionally respond.** Arbitration chooses the
next requester; locks protect a bounded item group; IDs make responses routable.
