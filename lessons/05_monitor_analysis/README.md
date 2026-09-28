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
