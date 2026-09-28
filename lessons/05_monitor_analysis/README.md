# 05 — Monitor and analysis communication

## Monitor responsibility

A monitor is passive. It never drives the DUT. It samples protocol handshakes,
reconstructs value objects, attaches response information, and publishes a
completed transaction. This makes the monitor reusable in active agents,
passive agents, scoreboards, coverage, protocol checkers, and predictors.

The mini-bus has a request and a later response, so the monitor stores accepted
requests in a pending queue. On `response_valid`, it pops the oldest request,
adds `read_data`, and broadcasts it. A response with no pending request and a
pending request left at end-of-test are both errors.

## Analysis port semantics

`uvm_analysis_port::write` is a nonblocking function call broadcast. Every
connected subscriber receives the same object handle. A monitor must therefore
create a fresh item for each request and must not mutate it after publication.
Subscribers that need long-term ownership should clone or copy deliberately.

See [`mini_bus_monitor.svh`](../../tb/uvm/mini_bus_monitor.svh).

## Interview-ready answer

“The monitor converts pin-level accepted activity back into transactions. I use
a pending queue to associate responses and publish only completed transfers.
Its analysis port fans out the same observed stream to checking and coverage.”

## Trap

Publishing at request acceptance when the scoreboard needs response data makes
the transaction incomplete and often creates race-dependent comparisons.

## Sampling state machine

For the one-response-later mini-bus, observation has two semantic events:

```systemverilog
if (vif.monitor_cb.response_valid) begin
  if (pending.size() == 0)
    `uvm_error("SPURIOUS", "response without request")
  else begin
    tr = pending.pop_front();
    tr.response_data = vif.monitor_cb.read_data;
    analysis_port.write(tr);
  end
end

if (vif.monitor_cb.req && vif.monitor_cb.ready) begin
  tr = mini_bus_item::type_id::create("observed_request");
  tr.write   = vif.monitor_cb.write;
  tr.address = vif.monitor_cb.address;
  tr.data    = vif.monitor_cb.write_data;
  pending.push_back(tr);
end
```

Response is processed before a same-edge new request so a one-cycle pipeline is
associated with the older entry. For an out-of-order protocol, queue position is
insufficient; use the observed transaction ID as a lookup key.

## Publication and ownership rule

`analysis_port.write(tr)` calls all connected subscribers in zero simulation
time with the same handle. Therefore:

- Create a fresh transaction for every accepted request.
- Complete all fields before publication.
- Never edit the object after publication.
- A subscriber that stores it beyond `write()` should clone it.

The coverage subscriber in this project samples synchronously inside `write()`,
while the scoreboard immediately consumes the values. A queued/asynchronous
consumer should use an analysis FIFO or clone into its own queue.

## Passive behavior and reset

A monitor must never drive pins, raise traffic objections, or depend on a
sequencer. In passive-agent mode it should behave identically. On reset it must
discard or resolve partial protocol state according to the specification; simply
continuing with pre-reset pending entries produces false pairings.

## Monitor checks versus SVA

Use monitor checks for transaction-assembly invariants such as response with no
pending request, malformed field combinations, or incomplete queued operations.
Use SVA for exact cycle relationships and stability. This gives the best error
timestamp without duplicating a temporal state machine in classes.

## Interview follow-ups

1. **Why is a monitor passive?** So the same observation/checking path works when
   another VIP or real system master drives the interface.
2. **When should it publish?** At the semantic completion event required by its
   subscribers, after all necessary fields are known.
3. **What happens if it reuses one item?** Subscribers retaining the handle see
   later mutations, corrupting results.
4. **How do you handle out-of-order responses?** Store accepted requests by a
   unique observed ID and match each response by that ID.
5. **Should the monitor raise an objection?** Normally no; the scenario owner
   controls lifetime, while pending-state checks expose premature shutdown.

## Debug exercise

If the scoreboard reports the right address but the previous response data,
compare sampling regions and pipeline timing first. Log request acceptance and
response completion with a monotonic observation ID, then check whether the
monitor published before the response was sampled.

## Revision summary

**Monitor samples accepted pins, reconstructs one complete fresh object, and
broadcasts it once. Its stream is the checker’s evidence path.**
