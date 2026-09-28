# 12 — Functional coverage and assertions

## Different questions

The scoreboard asks, “Was the result correct?” Assertions ask, “Did temporal
protocol rules hold every cycle?” Functional coverage asks, “Which planned
scenarios were observed?” Code coverage asks, “Which implementation structures
executed?” None replaces the others.

## Functional coverage

`mini_bus_coverage` samples only monitor-published completed transactions. Its
covergroup measures operation, first/middle/last address, data categories, and
operation × address cross. Sampling generator intent would count transfers that
could have been blocked or changed before reaching the DUT.

Coverage closure begins with a written plan. An important reachable hole needs
targeted legal stimulus; an unreachable bin needs a justified exclusion. A
percentage without bin meaning is not closure.

## Assertions

The protocol module checks request-to-response timing, no spontaneous response,
stability under stall, and known controls. `disable iff (!reset_n)` prevents
reset behavior from becoming a false failure. Read/write cover properties show
assertion attempts, but they do not replace transaction coverage.

See [coverage subscriber](../../tb/uvm/mini_bus_coverage.svh) and
[SVA](../../tb/assertions/mini_bus_sva.sv).

## Tool boundary

The portable smoke executes SVA. Full covergroup/code/assertion coverage belongs
to Xcelium in this repository; the portable full-UVM path disables covergroups.

## Covergroup syntax and sampling

```systemverilog
covergroup bus_cg with function sample(mini_bus_item tr);
  option.per_instance = 1;
  cp_op: coverpoint tr.write {
    bins read  = {0};
    bins write = {1};
  }
  cp_addr: coverpoint tr.address {
    bins low  = {[0:3]};
    bins mid  = {[4:11]};
    bins high = {[12:15]};
  }
  op_x_addr: cross cp_op, cp_addr;
endgroup
```

An argument-sampled covergroup avoids mutable shared sample fields. Alternatively,
the subscriber can assign a stable item then call `sample()`, as this project
does. Sample on the semantic event—completed monitor transaction—not an arbitrary
clock or sequence generation.

Important bin tools:

- `bins` count planned legal values, ranges, or transitions.
- `ignore_bins` remove legal but out-of-scope combinations with justification.
- `illegal_bins` flag forbidden samples, but assertions/checkers should remain
  the primary failure mechanism because illegal-bin behavior is tool-dependent.
- `iff` gates sampling; it does not make a bin unreachable.
- Cross bins should represent useful risk, not a Cartesian explosion.

## SVA temporal reasoning

```systemverilog
property request_gets_response;
  @(posedge bus.clk) disable iff (!bus.reset_n)
    bus.req && bus.ready |=> bus.response_valid;
endproperty
```

`|=>` is non-overlapped implication: the consequent begins on the next sampled
clock. `|->` begins on the same sampled clock. `$past`, `$stable`, `$rose`, and
`$fell` refer to sampled values. Use `disable iff` for normal protocol behavior
during reset, plus separate properties that check reset itself.

```systemverilog
request_stable_while_waiting:
  assert property (bus.req && !bus.ready |=>
                   bus.req && $stable({bus.write, bus.address, bus.write_data}));
```

Every assertion failure should name the violated requirement and include key
signals/IDs where supported. Bound/module assertions see the pin truth and catch
driver as well as DUT violations.

## Coverage closure example

If `write × high_address` is uncovered:

1. Confirm the specification says it is reachable and legal.
2. Confirm constraints do not exclude it.
3. Confirm the sequence starts and the DUT accepts it.
4. Confirm monitor publication reaches the covergroup.
5. Add targeted stimulus only after identifying the missing link.

Do not modify bins solely to raise the percentage. Connect every bin to a
verification-plan requirement and record exclusions with a reason.

## Interview-ready answer (60–90 seconds)

“I use three complementary measurements. The scoreboard checks transaction data
and state, SVA checks temporal signal rules at every sampled clock, and functional
coverage measures whether planned observed scenarios occurred. I sample coverage
from completed monitor transactions so rejected generator intent is not counted.
Coverpoints and selective crosses come from the verification plan; ignore bins
need justification. For SVA I choose overlapped or non-overlapped implication
from the protocol timing diagram, disable normal checks during reset, and add
separate reset properties. Coverage guides stimulus but never decides correctness.”

## Interview follow-ups

1. **`|->` versus `|=>`?** Consequent starts same sampled cycle versus next
   sampled cycle.
2. **Why not sample the sequence item?** It may never be accepted or may be
   transformed before reaching the DUT.
3. **`iff` versus `ignore_bins`?** `iff` gates sampling dynamically; ignore bins
   statically exclude declared combinations from the coverage goal.
4. **Assertion coverage versus assertion pass?** Coverage records attempts and
   successes/vacuity; a property can pass vacuously without its antecedent.
5. **Does 100% functional coverage mean no bugs?** No; bins/model can be
   incomplete and coverage does not compare expected results.

## Revision summary

**Scoreboard = data correctness, SVA = temporal correctness, functional coverage
= planned scenario observation, code coverage = implementation execution.**
