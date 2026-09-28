# 07 — TLM, reference model, and scoreboard

## Why transaction-level communication?

TLM passes meaningful operations instead of individual signals. Producers and
consumers remain loosely coupled: the monitor knows only that it publishes an
item; it does not know whether one or five subscribers consume it.

An analysis **port** is the publisher endpoint. An analysis **imp** implements
the consumer's `write` method. An **export** forwards an interface through a
hierarchy level. The project connects the monitor port to scoreboard and
coverage implementations in the environment's `connect_phase`.

## Predictive scoreboard

The scoreboard owns an independent 16-byte model initialized to reset values.
On an observed write it updates the addressed byte. On an observed read it
compares returned data with the predicted byte. It also checks the exact
transaction count and requires both read and write traffic.

This is stronger than comparing DUT output to driver input: the reference state
is derived from completed pin observations, so driver/monitor problems remain
visible. See [`mini_bus_scoreboard.svh`](../../tb/uvm/mini_bus_scoreboard.svh).

## Ordering

The current protocol is in-order, so one analysis stream is sufficient. An AXI
scoreboard would normally track channel handshakes and IDs independently, then
match out-of-order responses by key rather than queue position.

## False-pass prevention

Zero mismatches alone is weak if nothing ran. Exact counts, non-zero operation
classes, pending-queue checks, timeout, assertions, and final UVM severities
together define completion.

## In-order reference-model algorithm

```systemverilog
function void write(mini_bus_item tr);
  seen++;
  if (tr.write) begin
    model[tr.address] = tr.data;
    writes++;
  end else begin
    reads++;
    if (tr.response_data !== model[tr.address])
      `uvm_error("DATA", $sformatf(
        "address=%0h expected=%0h actual=%0h",
        tr.address, model[tr.address], tr.response_data))
  end
endfunction
```

The predictor uses only accepted/completed monitor observations. It has an
independent model initialized from the documented reset state. Mirroring DUT RTL
line-for-line risks reproducing the same bug; model behavior at the specification
level.

## Two-stream and out-of-order scoreboards

When expected and actual results arrive separately, connect distinct analysis
implementations or analysis FIFOs. In-order traffic can compare queue fronts.
Out-of-order traffic needs a stable key:

```systemverilog
expected_by_id[id].push_back(expected);
actual_by_id[id].push_back(actual);
compare_ready_id(id);
```

The data structure must support repeated IDs if the protocol permits multiple
outstanding operations per ID. Ordering rules may apply within one ID even when
different IDs reorder. At check phase, report every leftover expected and actual
entry with its key rather than only a total count.

## Predictor versus comparator

- A **predictor/reference model** converts inputs and state into expected output.
- A **comparator** matches expected and actual items.
- A **scoreboard** may contain both, but keeping the roles visible simplifies
  replacement by a C/Python model or a subsystem predictor.

## Comparison policy

Define whether X/Z is legal and whether comparison is 2-state (`==`) or exact
4-state (`===`). Use field-by-field diagnostics for semantic fields; a blind
whole-object compare can include timestamps/debug fields that are not required
to match. Count mismatches locally and also issue `uvm_error` so both component
summary and global severity agree.

## Interview-ready answer (60–90 seconds)

“My scoreboard consumes monitor-observed completed transactions, maintains an
independent specification-level model, and compares every read against predicted
state. For one in-order stream, the write method can update/check immediately.
For separate expected/actual streams I use analysis FIFOs; for out-of-order
traffic I match by protocol ID and preserve ordering rules within each ID. In
check phase I require no leftovers, the exact expected count, both operation
classes, and zero mismatches, which prevents a zero-traffic false pass.”

## Interview follow-ups

1. **Why not compare driver requests directly?** That misses driver, interface,
   reset, and DUT-acceptance bugs.
2. **How do you handle two `write()` methods of one type?** Use
   `uvm_analysis_imp_decl` suffixes or separate analysis FIFOs.
3. **What belongs in `check_phase`?** Leftovers, count invariants, required
   traffic classes, and accumulated checker status—no timed waiting.
4. **How should X values compare?** According to the specification; for known
   response data, exact 4-state comparison exposes unknowns.
5. **Why can a detailed RTL-like model be bad?** It can duplicate implementation
   assumptions and share the DUT bug.

## Revision summary

**Observe, predict independently, match under protocol ordering, diagnose fields,
and prove completion—not merely absence of mismatches.**

See [Chapter 17](../17_tlm_interfaces_fifos/README.md) for full TLM method and
FIFO semantics.
