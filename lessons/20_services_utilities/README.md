# UVM reporting, command line, synchronization, and object utilities

## Why UVM services matter

The component hierarchy moves stimulus and observations, while UVM services make
that environment controllable and diagnosable. Reporting creates searchable
evidence, the command-line processor selects behavior without recompilation,
events/barriers coordinate independent processes, and object utilities define
safe transaction ownership and recording.

## Reporting: severity, verbosity, action, and ID

```systemverilog
`uvm_info("DRV/REQ", req.convert2string(), UVM_HIGH)
`uvm_warning("CFG/DEFAULT", "Using default timeout")
`uvm_error("SB/MISMATCH", mismatch_text)
`uvm_fatal("CFG/VIF", "Virtual interface is null")
```

- **Severity** (`INFO`, `WARNING`, `ERROR`, `FATAL`) states impact.
- **Verbosity** filters `uvm_info` detail; it does not suppress errors/fatals.
- **ID** groups a message family so actions/verbosity can be targeted.
- **Action** controls display, log, count, stop, exit, or recording behavior.

```systemverilog
set_report_id_verbosity_hier("DRV/REQ", UVM_HIGH);
set_report_severity_id_action_hier(UVM_WARNING, "CFG/DEFAULT",
                                   UVM_DISPLAY | UVM_COUNT);
```

Use stable IDs and include instance, transaction ID, expected value, actual
value, and time in failure messages. A generic “mismatch” is not debug evidence.

## Report catcher versus callback

A report catcher intercepts report messages and may modify severity/action or
suppress a known message. A component callback inserts behavior at an explicit
hook designed by that component. Catchers should be narrowly scoped; suppressing
all errors can turn a real failure into a false pass.

## Command-line processor

```systemverilog
uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();
string value;
if (clp.get_arg_value("+traffic_count=", value)) begin
  if ($sscanf(value, "%0d", traffic_count) != 1)
    `uvm_fatal("CMD/COUNT", {"Invalid +traffic_count=", value})
end
```

Standard switches such as `+UVM_TESTNAME`, `+UVM_VERBOSITY`, config-db setters,
and factory overrides are handled by UVM. Validate project-specific plusargs and
print the resolved configuration once so regressions are reproducible.

## `uvm_event`

An event coordinates a one-to-many occurrence and can carry optional data.

```systemverilog
uvm_event reset_done = uvm_event_pool::get_global("reset_done");

// waiter
reset_done.wait_trigger();

// trigger owner
reset_done.trigger();
```

`wait_trigger()` can miss a trigger that happened earlier in the same timestep;
`wait_ptrigger()` uses a persistent-trigger interpretation for that delta cycle.
For persistent state such as “reset has completed”, also maintain an explicit
state bit rather than treating an event as storage.

## `uvm_barrier`

A barrier releases waiters when a threshold number have arrived:

```systemverilog
uvm_barrier workers_done = new("workers_done", 2);
fork
  begin run_bus_work(); workers_done.wait_for(); end
  begin run_irq_work(); workers_done.wait_for(); end
join
```

Set/reset threshold deliberately when processes can be cancelled; otherwise one
missing waiter can deadlock the test.

## Pools and queues

`uvm_pool #(KEY,T)` is an associative key-to-value utility with UVM methods.
Global pools are convenient registries but introduce hidden shared state. Prefer
instance-owned pools or configuration handles, and document who may insert,
replace, and delete entries.

## Transaction object utilities

UVM field macros can automate basic operations, but hand-written methods make
semantics explicit for large or nested objects.

```systemverilog
function void do_copy(uvm_object rhs);
  mini_bus_item other;
  if (!$cast(other, rhs))
    `uvm_fatal("COPY/TYPE", "Expected mini_bus_item")
  super.do_copy(rhs);
  addr  = other.addr;
  data  = other.data;
  write = other.write;
endfunction

function bit do_compare(uvm_object rhs, uvm_comparer comparer);
  mini_bus_item other;
  if (!$cast(other, rhs)) return 0;
  return super.do_compare(rhs, comparer) &&
         (addr == other.addr) && (data == other.data) &&
         (write == other.write);
endfunction
```

- `copy()` copies into an existing destination and calls `do_copy()`.
- `clone()` allocates a same-type object through factory semantics, then copies.
- `compare()` delegates policy/reporting to a `uvm_comparer`.
- `print/sprint()` use a printer and `do_print()` or registered fields.
- `pack/unpack()` serialize fields in an explicitly agreed order.
- Recording attaches transaction attributes and begin/end times to a recorder.

Do not pack derived debug-only state into a wire transaction accidentally. Do
not shallow-copy nested mutable objects when independent ownership is required.

## Transaction recording

Use `begin_tr()`/`end_tr()` or the driver's recording support around the actual
protocol operation. Record stable IDs, addresses, kind, response, and relation
between request and response. Recording is for waveform/database debug; the
scoreboard remains the correctness authority.

## Where this repository demonstrates it

- Reporting and debug policy: [Chapter 14](../14_reporting_callbacks_debug/README.md)
- Driver callback hook: [`driver_callback_example.sv`](../../examples/callbacks/driver_callback_example.sv)
- Event/barrier reference: [`sync_services_example.sv`](../../examples/services/sync_services_example.sv)
- Transaction formatting: [`mini_bus_item.svh`](../../tb/uvm/mini_bus_item.svh)

## Interview-ready answer (60–90 seconds)

“UVM services make a bench configurable and debuggable without coupling its
components. I use stable report IDs, severity for impact, verbosity for optional
detail, and targeted report actions; I never globally suppress errors. The
command-line processor parses scenario settings and I validate and print the
resolved values. `uvm_event` signals an occurrence, a barrier waits for a defined
number of participants, and a pool maps keys to shared objects, though I avoid
hidden global state. For transactions I define clear copy, compare, pack, print,
and record behavior and clone objects whenever a subscriber retains a handle.”

## Interview follow-ups

1. **Does verbosity affect `uvm_error`?** No; verbosity applies to info messages.
2. **Why are stable report IDs useful?** They enable targeted filtering/actions
   and make regression log triage searchable.
3. **Event versus state bit?** An event represents an occurrence; a bit represents
   persistent state. Many protocols need both.
4. **`copy` versus `clone`?** `copy` needs an existing destination; `clone`
   allocates a new dynamic-type object then copies.
5. **Why avoid blanket report catchers?** They can hide unexpected DUT or bench
   errors and create false passes.

## Common traps

- Expensive string formatting at low verbosity in high-volume paths.
- A report ID whose spelling changes across components.
- Parsing plusargs without checking conversion success.
- Missing an event trigger or waiting forever at a barrier.
- Relying on field macros without considering nested-handle ownership.

## Revision summary

**Reports explain, command-line settings control, synchronization services
coordinate, and object methods define ownership.** Each service needs explicit
scope and failure behavior.
