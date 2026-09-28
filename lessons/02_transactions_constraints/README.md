# 02 — Transactions, fields, constraints, and object operations

## Transaction as an abstraction

A transaction describes one logical operation without embedding clock-edge
details. `mini_bus_item` contains operation, address, write data, and observed
response data. The driver decides *when* these fields reach pins; the monitor
decides when a completed operation exists.

The item uses `rand` fields plus an equal-weight `dist` constraint for read and
write selection. `boundary_bus_item` derives from it and adds an address
constraint for only 0 and 15. Because the sequence requests the base type via
the factory, a test can replace it without rewriting the sequence.

## Randomization contract

`randomize()` returns a bit. A zero return is a verification failure, not a
minor warning: fields can retain stale values. The random sequence checks every
call and issues `uvm_fatal` before sending an invalid item.

Inline constraints express one-scenario intent. Class constraints continue to
apply, so conflicting hard constraints fail. `soft` constraints are useful for
defaults that tests may legally replace.

## Copy, compare, and print

Handle assignment aliases the same object; it is not a copy. The item provides
explicit `do_copy`, `do_compare`, and `convert2string` methods so ownership and
debug output remain visible. Nested handles require a deliberate deep-copy
policy.

Study [`mini_bus_item.svh`](../../tb/uvm/mini_bus_item.svh).

## Interview trap

Functional coverage is not guaranteed by `randc`, `dist`, or many seeds. Those
control generation; coverage measures what was actually observed.

## Constraint tools with exact syntax

```systemverilog
class burst_item extends uvm_sequence_item;
  rand bit [7:0] address;
  rand int unsigned length;
  rand bit [1:0] kind;

  constraint legal_c {
    length inside {[1:16]};
    address % 4 == 0;
    kind dist {0 := 5, 1 := 3, [2:3] := 1};
  }
  constraint default_len_c { soft length == 4; }
  constraint order_c { solve kind before length; }
endclass
```

- `inside` defines a set/range; negating it excludes values.
- `dist` uses `:=` weight per value and `:/` weight divided across a range.
- `soft` supplies a default that a stronger inline constraint may replace.
- `solve ... before` changes probability/order, not the legal solution set.
- `if/else` and implication (`->`) express conditional legality.
- `foreach` constrains every element of an array.

`randc` cycles through values before repeating, subject to the solver and any
changing constraints. It is not practical for a large state space and does not
guarantee observed functional coverage after protocol filtering.

## Randomization lifecycle

```systemverilog
function void pre_randomize();
  // Prepare non-random helper state; do not hide scenario intent here.
endfunction

function void post_randomize();
  // Derive fields such as checksum from randomized source fields.
endfunction
```

Inline constraints combine with enabled class constraints:

```systemverilog
if (!tr.randomize() with { address inside {[8'h20:8'h2f]}; length == 8; })
  `uvm_fatal("RAND", "No legal solution for window transaction")
```

Use `constraint_mode(0)` only with a documented reason and restore it when an
object is reused. `rand_mode(0)` freezes one variable; direct assignment after
randomization is clearer for a deliberately directed field.

## Object-operation contract

| Operation | Purpose | Ownership issue |
|---|---|---|
| `copy(rhs)` | Replace fields in an existing object | Destination already exists |
| `clone()` | Allocate and copy dynamic type | Cast returned `uvm_object` |
| `compare(rhs)` | Compare under comparer policy | Exclude non-semantic debug fields |
| `print/sprint()` | Structured debug output | Select printer/verbosity |
| `pack/unpack()` | Serialize/deserialize | Field order and metadata must match |
| `record()` | Wave/database transaction attributes | Begin/end timing belongs at transactor |

The repository explicitly copies response data as well as request fields. If a
new semantic field is added but omitted from copy/compare/print, factory-derived
items can fail in ways that logs cannot explain.

## Worked reasoning example

Suppose the base item says `address inside {[0:15]}` and a test adds
`address == 31`. Both are hard constraints, so randomization returns zero. The
correct response is not to ignore the return bit. Either make the base preference
`soft`, derive a legal negative-test type with a changed contract, or deliberately
disable the named constraint and document why the resulting operation is valid
for that negative scenario.

## Interview-ready answer (60–90 seconds)

“A sequence item represents one logical protocol operation without clock timing.
I use hard constraints for specification legality, soft constraints for defaults,
inline constraints for scenario intent, and I check every randomize return value.
`dist` changes stimulus probability but does not prove coverage. Because class
handles alias, I define copy/clone ownership and explicit compare/print methods,
including derived response fields. The driver consumes the request fields while
the monitor produces a fresh observed item containing the completed response.”

## Interview follow-ups

1. **`:=` versus `:/` in `dist`?** `:=` assigns the weight to each value;
   `:/` distributes the stated weight across the range.
2. **Does `solve before` change legality?** No, it affects distribution/order.
3. **Why can randomization fail after adding an inline constraint?** It may
   conflict with an enabled hard class constraint.
4. **Handle assignment versus `copy`?** Assignment aliases one object; copy
   transfers fields into a distinct object.
5. **When is `post_randomize` useful?** For derived values such as checksums or
   normalized encodings after source fields are solved.

## Revision summary

**Transaction = untimed operation. Hard constraints encode legality, soft/inline
constraints encode preference/scenario, and object methods encode ownership.**
