# Mini-bus verification plan

## Protocol specification

- Address width: 4 bits; data width: 8 bits; 16 byte locations.
- Memory resets to zero.
- `ready` is always high in this DUT revision.
- A request is accepted on a rising edge when `req && ready`.
- `write=1` updates the selected byte; `write=0` reads it.
- `response_valid` is visible on the sampled cycle after every accepted request.
- Read response data equals the most recent accepted write to that address, or
  zero when the address has not been written after reset.
- Requests are non-pipelined in the supplied driver. The monitor still uses a
  pending queue so request/response ownership is explicit and extensible.

## Feature-to-evidence matrix

| Requirement | Stimulus | Scoreboard/check | Assertion | Coverage |
|---|---|---|---|---|
| Reset value is zero | Directed read of address 0 | Model initialized to zero | Control known | Read/address bins |
| Write then read | Directed pairs and random traffic | Per-address memory model | Response timing | Read/write bins |
| First/last address | Directed and factory boundary test | Address-indexed compare | Response timing | First/last bins |
| All random addresses | 40 constrained items | Every completed read compared | No spurious response | Middle bin |
| Every request responds | All tests | Exact completed count | Request implies response | Read/write cover properties |
| No spontaneous response | Idle cycles between transfers | Monitor pending-queue check | Response has prior request | Assertion attempts |
| Factory override works | `mini_bus_boundary_test` | Exactly 20 completed items | Same protocol rules | Boundary address bins |
| Analysis fanout works | Every monitor publication | Scoreboard seen count | — | Coverage sample count |
| Read and write both occur | Directed pair or operation-mix guard | Scoreboard operation counts | Read/write cover | Operation bins |

## Tests

### `mini_bus_test`

Four stable directed transfers followed by 40 constrained-random transfers.
Pass requires exactly 44 monitor publications, both reads and writes, no data
mismatch, and no assertion/UVM error.

### `mini_bus_boundary_test`

Overrides `mini_bus_item` with `boundary_bus_item` before environment creation.
Twenty randomized items must use only address 0 or 15 and complete cleanly. An
operation-mix guard directs the first two randomized items to one write and one
read, so the pass criterion is deterministic rather than probability-dependent.

### `mini_bus_smoke`

Portable module-level test that executes four checked reads and three writes
through the same RTL and assertions. It validates behavior without claiming to
exercise UVM classes.

## Closure criteria

- Exact transaction counts and zero scoreboard errors.
- Zero UVM error/fatal summaries.
- Zero assertion failures.
- Read, write, first, middle, and last address bins reviewed in Xcelium.
- Test name, seed, tool version, command, and log retained for failures.
