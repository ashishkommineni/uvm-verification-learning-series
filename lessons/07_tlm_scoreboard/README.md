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
