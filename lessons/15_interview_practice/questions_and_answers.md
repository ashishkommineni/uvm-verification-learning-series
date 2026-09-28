# 80 UVM interview questions and practical answers

These answers focus on ownership, data flow, timing, and failure modes rather
than memorized definitions.

## Foundations

### 1. What problem does UVM solve?

UVM standardizes verification architecture: component hierarchy, phases,
factory construction, configuration, TLM communication, reporting, and
reusable stimulus. It lowers the effort to move VIP from block to subsystem and
SoC level. It does not define protocol behavior; the project still writes its
own items, driver, monitor, checks, and coverage.

### 2. `uvm_object` versus `uvm_component`?

An object is lightweight, dynamic, and has no parented component hierarchy or
automatic component phases. Items, sequences, configs, callbacks, and RAL
objects are objects. A component is a persistent hierarchy node with parent,
full name, phases, and report context; drivers, monitors, agents, envs, and
tests are components.

### 3. Why does a component constructor need a parent?

The parent establishes hierarchy. That path controls topology, phase traversal,
report names, config lookup, and instance overrides. Passing null is normally
reserved for components created directly under the UVM root.

### 4. `new` versus `type_id::create`?

`new` constructs the named concrete class directly. `create` asks the factory
which registered type should satisfy the request, allowing type or instance
override. Registration alone is insufficient when construction still uses
plain `new`.

### 5. What does `run_test()` do?

It asks `uvm_root` to factory-create the requested test, starts phasing, and
produces the final UVM report summary. With no argument, the name comes from
`+UVM_TESTNAME`, letting one compiled image run many tests.

### 6. What is `uvm_root`?

It is the implicit top of UVM component hierarchy. It owns test creation,
global phase execution, topology traversal, timeout behavior, and end-of-test
control. The created test normally appears as `uvm_test_top`.

### 7. What do UVM utility macros do?

Type macros register classes with the factory and add type information. Field
macros additionally automate copy, compare, print, pack, and record operations.
Explicit `do_*` methods are clearer when ownership or performance matters.

### 8. Why is UVM a methodology, not only a library?

The library supplies mechanisms; the methodology assigns responsibility:
tests select scenarios, drivers own timing, monitors observe, scoreboards
predict, and coverage measures the plan. Using UVM classes without those
boundaries does not automatically create reusable verification.

### 9. What is the factory internally?

It is a run-time type construction service. Registered wrappers map a requested
base type and optional instance path to the concrete wrapper that constructs an
object/component. Factory debug reveals the requested type, overrides, and
final result.

### 10. Why is UVM not synthesizable?

It relies on dynamic classes, inheritance, constrained randomization, queues,
process control, and simulator services intended for verification. The DUT
remains synthesizable RTL; UVM executes in simulation or supported acceleration
flows.

## Transactions, sequences, and drivers

### 11. What belongs in a sequence item?

Fields describing one protocol operation: command, address, payload,
attributes, IDs, status, and observed response data. Clock-edge timing belongs
in the driver and monitor, not the transaction.

### 12. `rand` versus `randc`?

`rand` makes a legal solver choice each successful randomization. `randc`
cycles through a small domain before repeating, subject to constraints and tool
limits. Cyclic generation does not prove functional coverage.

### 13. What happens when `randomize()` fails?

It returns zero and no valid new solution is produced; fields may retain their
previous values. The testbench should report fatal/error immediately. Sending
the object can reuse stale stimulus and create misleading coverage.

### 14. What are inline constraints?

An inline `with` clause adds scenario intent for one randomization call. It
combines with class constraints; it does not replace a conflicting hard
constraint. Named constraints can be disabled deliberately for a negative test.

### 15. What is a soft constraint?

It is a default that yields to a stronger conflicting constraint. It helps a
reusable base item express normal behavior while a test selects a different
legal scenario. A normal hard conflict causes solve failure.

### 16. Shallow copy versus deep copy?

Handle assignment aliases one object. A shallow object copy duplicates scalar
fields but can share nested handles. A deep copy recursively duplicates owned
nested objects. Ownership must be explicit; service handles may be intended to
remain shared.

### 17. Why should a monitor create a fresh transaction?

Analysis ports pass object handles. If the monitor reuses and mutates one item,
subscribers that stored the handle see later values instead of history. Create
a new item per observed transfer or clone before retaining it.

### 18. What is the sequence–sequencer–driver handshake?

The sequence calls `start_item`, waits for arbitration, fills the item, then
calls `finish_item`. The driver blocks on `get_next_item`, drives the complete
protocol operation, and calls `item_done` exactly once. Broken pairing normally
causes deadlock or duplicated completion.

### 19. Does a sequencer generate stimulus?

No. A sequence generates scenario items; the sequencer arbitrates and transports
them to a driver. Keeping policy in sequences lets the same driver serve many
tests and lets several sequences share one interface.

### 20. When do you use `lock` or `grab`?

Use them when a multi-item sequence requires exclusive access to a sequencer.
`grab` takes higher priority than normal arbitration; `lock` waits through the
normal arbitration path. Both must be released, or other sequences can starve.

### 21. How are sequence responses returned?

A driver can pass a response in `item_done(response)` or put it on the response
path. The sequence uses `get_response` or a response handler. Preserve the
request transaction ID so responses are routed to the correct sequence.

### 22. Where should protocol timing live?

In the driver and monitor, normally through interface clocking blocks. A
sequence should say “perform this read,” not “toggle request at this absolute
time.” That separation allows the same transaction sequence to work with a
different timing implementation.

## Components, configuration, and phases

### 23. Why use a virtual interface?

Classes cannot directly contain an elaborated interface instance. A virtual
interface is a class handle to that instance, letting driver and monitor access
signals and clocking blocks while the top retains structural ownership.

### 24. Why fail fatally when the VIF is missing?

Without the VIF, a driver or monitor cannot perform meaningful work. Continuing
would cause null-handle errors or an empty false pass. A build-phase fatal gives
a precise configuration diagnosis.

### 25. What is `uvm_config_db` lookup based on?

It is typed and considers the setter context, instance path/pattern, field name,
phase/precedence, and set order. A wildcard can match more instances than
intended, so full topology and narrow paths are important debug tools.

### 26. `config_db` versus `resource_db`?

`config_db` is a hierarchy-oriented convenience layer used for component
configuration. `resource_db` is a broader named/type resource pool with wider
scope. Use `config_db` by default for VIFs and agent configuration; use
`resource_db` only when hierarchy-independent sharing is intentional.

### 27. What happens in `build_phase`?

Components create child components through the factory and retrieve values
needed for construction. It is a function phase and must not consume time.
Build usually traverses top-down, enabling parent configuration before child
construction.

### 28. What happens in `connect_phase`?

Already-created ports, exports, implementations, and sequencer-driver channels
are connected. It is also a function phase. Creating major hierarchy here is
usually too late and makes topology harder to reason about.

### 29. How do run-phase objections work?

An objection indicates that a component still needs the task phase alive. A
test raises before starting traffic and drops after traffic and response drain.
When all objections drop, the phase can advance. Objections do not themselves
create time or wait for DUT completion.

### 30. Why avoid raising objections in every sequence/component?

Distributed ownership makes end-of-test unpredictable and a forgotten drop
hangs the regression. Prefer a test or top-level virtual sequence to own the
scenario lifetime; lower-level components should run continuously and react to
phase termination.

### 31. What are drain time and timeout?

Drain time lets in-flight responses complete after the final objection drops,
but an explicit protocol completion condition is clearer. A timeout bounds a
deadlock and converts it into a reproducible failure. Neither should hide a
monitor pending-queue bug.

### 32. Active versus passive agent?

An active agent contains sequencer, driver, and monitor; a passive agent contains
only observation. Passive mode enables reuse at subsystem/SoC level when another
master drives the bus. Both modes should provide the same monitor output.

## TLM, monitor, scoreboard, and coverage

### 33. Port, export, and implementation in TLM?

A port initiates an interface call, an implementation terminates it in a method,
and an export forwards it through hierarchy. For analysis TLM, the monitor's
port broadcasts `write`, and scoreboard/coverage implementations receive it.

### 34. Why is an analysis port nonblocking?

Its `write` is a function, so the publisher cannot consume simulation time while
notifying subscribers. A subscriber that needs time should enqueue a copy into a
FIFO and process it in a task.

### 35. What is a `uvm_tlm_analysis_fifo` useful for?

It decouples a nonblocking analysis producer from task-based consumption and
provides ordered buffering. It is common when a scoreboard must pair independent
expected and actual streams. Queue depth and end-of-test emptiness still need
checking.

### 36. Why is the monitor the source of truth?

The driver describes intent; the interface shows what the DUT accepted. A
scoreboard fed by driver items can miss a driver timing bug or ignored request.
Monitor-based checking validates the complete path.

### 37. How does an in-order scoreboard work?

It predicts state from completed observed inputs, then compares completed
outputs in protocol order. For this memory, writes update an address-indexed
model and reads compare response data. It also checks counts and pending work.

### 38. How would an AXI scoreboard differ?

AXI address, data, and response channels handshake independently, and responses
can interleave or reorder by ID. The monitor and scoreboard need per-channel
state, burst/beat tracking, ID-keyed queues, byte-strobe modeling, and legal
ordering rules rather than one FIFO.

### 39. Scoreboard versus assertion?

A scoreboard is strong for transaction data and long-lived reference state.
SVA is strong for cycle-level temporal rules such as VALID stability and
request-to-response timing. Both are needed because a correct final value can
still arrive through an illegal protocol sequence.

### 40. Functional coverage versus code coverage?

Functional coverage measures verification intent expressed as coverpoints,
bins, and crosses. Code coverage measures executed RTL structures. High code
coverage can miss an unmodeled feature, and high functional coverage can coexist
with untested implementation branches.

### 41. When should a covergroup sample?

At a semantically complete event, typically a monitor-published accepted or
completed transaction. Sampling every clock or sequence intent can count
illegal, retried, or unaccepted activity and inflate closure.

### 42. What is a meaningful coverage cross?

A cross represents an interaction required by the plan, such as read/write ×
boundary/middle address. Avoid combinatorial crosses with no closure decision;
they create large unreachable spaces and distract from risk.

### 43. How do you handle coverage holes?

Classify each hole: missing legal stimulus, monitor/sampling bug, constraint
conflict, unreachable design state, or legitimate exclusion. Add targeted
stimulus for reachable important bins and document exclusions instead of
weakening bin definitions to improve a number.

## Factory, virtual sequences, and RAL

### 44. Type override versus instance override?

Type override replaces all factory requests for a base type. Instance override
applies to a matching construction path and is more targeted. It also depends on
accurate hierarchy paths, so print topology and factory debug when it misses.

### 45. Can the factory override an object created with `new`?

No. The factory only participates when construction goes through its create
mechanism. This is a common reason an apparently registered override has no
effect.

### 46. What is a virtual sequence?

It coordinates lower-level sequences across multiple sequencers to express a
system scenario. It owns ordering/concurrency policy but does not drive pins.
A virtual sequencer is an optional holder for the physical sequencer handles.

### 47. Do you always need a virtual sequencer?

No. With one agent, a test can start a normal sequence directly. Even with
multiple agents, a virtual sequence may receive sequencer handles through
configuration. Add a virtual sequencer when central coordination and reuse make
the extra hierarchy worthwhile.

### 48. Desired, mirrored, and actual RAL values?

Desired is the value the model wants to place in the DUT. Mirrored is the
model's prediction of current DUT state. Actual is hardware state, known through
frontdoor/backdoor access or observed prediction. Confusing them causes
misleading RAL checks.

### 49. What does a RAL adapter do?

It translates between generic `uvm_reg_bus_op` and the protocol's sequence item
in both directions. It defines address/data mapping, read/write kind, byte
enables, response policy, and status conversion.

### 50. Auto-predict versus explicit predictor?

Auto-predict updates the mirror after model-initiated operations. An explicit
predictor listens to monitor traffic and also sees accesses from other masters,
making it safer in shared-bus systems when connected correctly.

## Reporting, callbacks, debug, and reuse

### 51. Severity versus verbosity?

Severity is info, warning, error, or fatal and affects pass/fail/action.
Verbosity filters informational reports by detail level. Raising verbosity does
not suppress UVM errors or fatals.

### 52. What is a report catcher?

It intercepts reports before final action and can modify severity/message or
catch expected reports. Use it for deliberate policy, not to demote real design
failures just to make a regression pass.

### 53. Factory override versus callback?

Factory override replaces the constructed implementation. A callback injects
narrow policy at an explicit hook in an existing component. Config fields are
better for simple data knobs. Choose the least-coupled mechanism that matches
the change.

### 54. What callback problems can occur?

Registration may target the wrong instance/type, the invocation hook may be
missing, multiple callback order may conflict, or a callback may mutate an item
into an illegal state. Add/remove policy and hook contracts must be explicit.

### 55. How do you debug a UVM topology problem?

Print topology after elaboration, inspect full names and active/passive modes,
then compare config/override paths with actual hierarchy. Do not guess a path
from source variable names.

### 56. How do you debug a sequence deadlock?

Find the last grant/request log. Check `start_item/finish_item`, driver
`get_next_item/item_done`, lock/grab release, reset waits, response waits, and
whether the correct sequencer-driver connection exists.

### 57. How do you debug a scoreboard mismatch?

Reproduce the same seed and trace the first divergent completed transaction:
sequence item, driven waveform, monitor observation, and model state before the
operation. Check sampling region and object reuse before blaming the DUT.

### 58. What causes an intermittent UVM failure?

Race-prone signal access, uninitialized fields, shared transaction handles,
uncontrolled forked processes, random-stream changes, objection timing, or a
model assuming fixed response order. Stable seed reproduction and first-error
tracing isolate it.

### 59. What prevents a false pass?

Exact expected transaction counts, non-zero meaningful activity, end-to-end
comparisons, assertion attempt coverage, pending-queue checks, timeout, and a
pass decision based on final UVM severities—not an unconditional `$display`.

### 60. How would you present this project in an interview?

State the mini-bus latency and reset specification, then trace one transaction
from sequence through sequencer, driver, pins, monitor, scoreboard, and coverage.
Explain SVA responsibility, factory/config examples, objection/end-of-test, one
bug caught, and which simulator results were actually executed. That proves
understanding beyond repository file count.

## Advanced integration and signoff

### 61. What are TLM port, export, and implementation endpoints?

A port is the caller that requires an interface method, an implementation
(`imp`) is the consumer that implements it, and an export forwards that
implementation through hierarchy. The normal connection direction is
port-to-export-to-imp or port-to-imp. A port declaration alone contains no
consumer behavior.

### 62. Blocking versus nonblocking TLM?

Blocking put/get/peek/transport methods are tasks and may wait, providing
synchronization or backpressure. `try_*` and `can_*` methods are functions that
return immediately. Analysis `write()` is also a zero-time function and is a
one-to-many broadcast, so a subscriber must not delay inside it.

### 63. When do you use `uvm_tlm_analysis_fifo`?

Use it between an analysis producer and a task-based consumer when arrivals must
be queued and processed asynchronously. Its analysis export accepts zero-time
`write()` calls and its get/peek interface lets the consumer wait. Monitor object
ownership and unbounded growth still need an explicit policy.

### 64. How do you implement two analysis inputs of the same item type?

Declare named implementation classes with `uvm_analysis_imp_decl` suffixes,
then implement methods such as `write_expected()` and `write_actual()`. Separate
analysis FIFOs are another clear option, especially when comparison is timed or
the two streams arrive independently.

### 65. `lock()` versus `grab()` on a sequencer?

Both reserve sequencer access across a group of items. `lock()` enters normal
arbitration order; `grab()` requests ahead of ordinary queued requests. Neither
preempts an item already granted. Keep the region short and never wait for work
that itself needs the locked sequencer.

### 66. Why call `set_id_info()` on a response?

It copies sequence and transaction routing IDs from the request so the sequencer
can return the response to the originating sequence. The sequence then calls
`get_response()`. Protocol IDs used for DUT out-of-order matching remain a
separate item field and responsibility.

### 67. How do you build an out-of-order scoreboard?

Store expected and actual items by a stable protocol key such as transaction ID,
compare whenever both sides for a key are available, and preserve any ordering
rule within that ID. Support repeated outstanding IDs when legal, detect
duplicates, and report every unmatched entry during check phase.

### 68. Why use a typed configuration object?

It groups related agent policy such as VIF, active/passive mode, checks, coverage,
and timeout into one factory-aware object. The receiving component performs one
typed config-db lookup and validates the whole contract, avoiding many wildcard
scalar keys and inconsistent partial settings.

### 69. How is `uvm_config_db` lookup resolved?

The requested SystemVerilog type, field name, component context, instance pattern,
hierarchical precedence, and set order all participate. Parameterized VIF types
must match exactly. The most reliable design has one configuration owner, narrow
paths, early sets, fatal checks for required values, and config-db tracing during
debug.

### 70. What are runtime phase subphases and phase domains?

Pre-reset through post-shutdown subphases provide a shared runtime schedule.
A phase domain is an independent schedule that can be synchronized with others.
They help when interfaces have genuinely separate reset/runtime timelines, but
mixing run/main traffic or adding domains without a project-wide policy makes
objection and shutdown behavior hard to reason about.

### 71. Drain time versus `phase_ready_to_end()`?

Drain time adds a fixed grace interval after objections drop. It is simple for a
known bounded pipeline but can hide missing completion. `phase_ready_to_end()`
lets a component postpone completion when it knows work remains, but must be
guarded against repeated raising. An explicit outstanding/queue-empty handshake
is usually the strongest correctness condition.

### 72. What does a UVM phase jump do?

It redirects the affected phase schedule/domain to a target phase, sometimes for
reset recovery. It is not local to one component, and current processes may be
interrupted, so components must tolerate cleanup and restart. Use it only under
a documented environment-wide reset policy.

### 73. `uvm_event` versus `uvm_barrier`?

An event announces an occurrence and optionally carries data; it is not persistent
state unless combined with a state variable. A barrier releases participants
when a configured threshold arrives. Events can be missed under the wrong wait
semantics, and barriers can deadlock if a participant is killed or never arrives.

### 74. How should command-line arguments be handled?

Use standard UVM switches for test, verbosity, factory, and supported config-db
settings. Parse project plusargs through `uvm_cmdline_processor`, validate every
conversion/range, reject invalid values, and print the resolved configuration
once with simulator, test, and seed for reproducibility.

### 75. What is the difference between `copy()` and `clone()`?

`copy(rhs)` transfers fields into an object that already exists. `clone()`
factory-creates a same-dynamic-type object and then copies into it, returning a
`uvm_object` handle that is commonly cast. Neither guarantees a deep copy unless
the field automation or `do_copy()` implements nested ownership correctly.

### 76. What is the correct reset strategy in a UVM bench?

Define how accepted requests, responses, DUT state, driver handshakes, monitor
partial transactions, scoreboard predictions, and assertions behave. Drive idle,
resolve any checked-out sequence item under an abort/retry policy, flush or retain
model state at the same semantic boundary as the DUT, and verify reset outputs
with dedicated properties.

### 77. How does a negative test produce a trustworthy pass?

Inject one documented illegal/error condition, require the exact expected
response or report count, and keep all unrelated checkers clean. Broad report
suppression is not a pass. The scenario should also prove recovery or continued
operation when the specification requires it.

### 78. What information makes a regression reproducible?

Test name, random seed, source commit, simulator and version, full command,
configuration/plusargs, log path, coverage database, timing, and error/fatal
counts. Separate DUT/testbench failures from license, farm, filesystem, and tool
launch infrastructure failures.

### 79. How do you close a functional coverage hole?

Check whether the bin is specified, legal, and reachable; whether constraints
can generate it; whether the DUT accepts it; and whether the monitor samples the
correct event. Add focused legal stimulus only after locating the gap. Exclude a
bin only with a specification-based written justification.

### 80. What is the difference between RAL `set`, `update`, `mirror`, and `reset`?

`set` changes desired model state only. `update` writes fields whose desired and
mirrored values differ. `mirror` reads actual hardware, updates the mirror, and
optionally compares. `reset` resets model values only; it neither drives DUT reset
nor accesses hardware. Confusing these operations is a common source of mirror
drift and false expectations.
