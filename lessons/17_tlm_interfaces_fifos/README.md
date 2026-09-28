# UVM TLM interfaces, analysis, and FIFOs

## What and why

Transaction-Level Modeling moves class objects between components without
exposing pin timing. It lets a monitor publish one decoded transaction to any
number of subscribers and lets producers/consumers synchronize through a stable
interface. The producer depends on a TLM contract, not the consumer's class.

## Port, export, and implementation

| Endpoint | Meaning | Typical placement |
|---|---|---|
| `port` | Caller: requires an interface method | Producer |
| `export` | Forwards a required implementation through hierarchy | Wrapper/environment |
| `imp` | Callee: implements the method locally | Consumer |

The legal direction is `port -> export -> imp` or `port -> imp`. A port does
not contain the behavior; it resolves to an implementation during connection.

```systemverilog
class consumer extends uvm_component;
  `uvm_component_utils(consumer)
  uvm_blocking_put_imp #(mini_bus_item, consumer) put_imp;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    put_imp = new("put_imp", this);
  endfunction

  task put(mini_bus_item tr);
    `uvm_info("PUT", tr.convert2string(), UVM_MEDIUM)
  endtask
endclass
```

The producer declares `uvm_blocking_put_port #(mini_bus_item) put_port`, connects
it to `consumer.put_imp`, then calls `put_port.put(tr)`.

## Interface families and timing semantics

| Family | Blocking behavior | Direction/use |
|---|---|---|
| `put` | Producer may wait | Push item into consumer |
| `get` | Consumer may wait and removes item | Pull next item |
| `peek` | Consumer may wait but does not remove | Inspect next item |
| `transport` | Request and response in one call | Request/response service |
| `try_put/get/peek` | Returns immediately with success bit | Nonblocking control |
| `can_put/get/peek` | Queries readiness only | Scheduling decision |
| `analysis` | `write()` is a function; cannot consume time | Broadcast observations |

Blocking methods are tasks; nonblocking and analysis methods are functions. A
blocking call can provide backpressure. An analysis subscriber must copy/store
quickly and must not wait inside `write()`.

## Analysis fanout and object ownership

```systemverilog
uvm_analysis_port #(mini_bus_item) ap;
// monitor:
ap.write(observed);
```

Every connected subscriber receives the **same object handle**. If the monitor
reuses or edits that object, stored subscriber data silently changes. Publish a
fresh object per transfer, or clone before retaining it:

```systemverilog
mini_bus_item saved;
$cast(saved, tr.clone());
pending_q.push_back(saved);
```

When one component needs several `write()` methods of the same type, declare
distinct implementation suffixes:

```systemverilog
`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)
// Implements write_expected(tr) and write_actual(tr).
```

## `uvm_tlm_fifo`

A TLM FIFO decouples arrival time from checking time and supplies put/get/peek
interfaces plus occupancy methods.

```systemverilog
uvm_tlm_fifo #(mini_bus_item) observed_fifo;

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  observed_fifo = new("observed_fifo", this, 16); // bounded depth
endfunction

task run_phase(uvm_phase phase);
  mini_bus_item tr;
  forever begin
    observed_fifo.get(tr);       // blocks until an item exists
    check_one(tr);
  end
endtask
```

Depth zero creates an unbounded FIFO. A bounded FIFO can apply backpressure with
blocking `put()`. Analysis traffic has no backpressure, so an
`uvm_tlm_analysis_fifo` is useful when a monitor must broadcast into a queue.

## Connection and debug checklist

1. Confirm parameter types match exactly on both endpoints.
2. Construct every port/export/imp/FIFO in the constructor or build phase.
3. Connect endpoints in `connect_phase()` using `producer.port.connect(...)`.
4. Check the min/max connection count in topology output.
5. If items disappear, log at publication and receipt with transaction IDs.
6. If values mutate later, audit handle reuse and clone ownership.
7. If simulation hangs, inspect blocking calls and end-of-test drain conditions.

## Where this repository demonstrates it

- Monitor analysis publication: [`mini_bus_monitor.svh`](../../tb/uvm/mini_bus_monitor.svh)
- Fanout connections: [`mini_bus_env.svh`](../../tb/uvm/mini_bus_env.svh)
- Analysis implementation: [`mini_bus_scoreboard.svh`](../../tb/uvm/mini_bus_scoreboard.svh)
- Focused FIFO/put example: [`tlm_fifo_example.sv`](../../examples/tlm/tlm_fifo_example.sv)

## Interview-ready answer (60–90 seconds)

“UVM TLM separates transaction communication from component implementation. A
port is the caller, an implementation provides the method, and an export forwards
that interface through hierarchy. I choose blocking put/get when producer and
consumer require synchronization or backpressure, nonblocking methods when the
caller must continue immediately, and an analysis port for zero-time one-to-many
broadcast from a monitor. Analysis subscribers receive the same handle, so I
clone anything I retain. For asynchronous checking I connect into a TLM analysis
FIFO and consume it in a task. When debugging, I verify type parameters,
connection paths, object ownership, and whether a blocking call can ever finish.”

## Interview follow-ups

1. **Can `write()` contain a delay?** No. It is a function and must complete in
   zero simulation time.
2. **What is the difference between `get` and `peek`?** Both may block; `get`
   removes the item while `peek` leaves it queued.
3. **Why use an export?** It exposes/forwards a child's implementation at a
   parent boundary without reimplementing the method.
4. **Does an analysis port guarantee subscriber order?** Do not design correctness
   around callback ordering; each subscriber should be independent.
5. **When is a FIFO dangerous?** An unbounded FIFO can hide a stalled consumer
   and consume memory; a bounded FIFO can deadlock if backpressure is ignored.

## Common traps

- Reversing the connection direction.
- Mixing types that look structurally equal but are different classes.
- Modifying a transaction after `write()`.
- Calling a blocking method from a function phase.
- Using an analysis stream where lossless backpressure is actually required.

## Revision summary

**Port calls, export forwards, imp implements.** Blocking TLM synchronizes;
analysis broadcasts. Always define transaction-handle ownership explicitly.
