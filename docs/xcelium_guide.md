# Cadence Xcelium guide

Confirm `xrun -version` in a shell configured for the Cadence installation and
license. Site-specific license variables must never be committed.

```sh
make uvm TEST=mini_bus_test SEED=13
make uvm TEST=mini_bus_boundary_test SEED=31
```

The script compiles in `sim/files.f` order, uses command-line test selection,
enables full coverage, and writes an isolated result directory for each test
and seed.

Review in IMC:

- operation and address coverpoints;
- operation × address cross;
- read/write assertion cover properties;
- assertion attempts/failures;
- useful RTL statement, branch, toggle, and FSM metrics.

Coverage exclusions require a written reason. Reachable important holes should
be closed by targeted stimulus, not by weakening the model.

For a failure, retain test, seed, simulator version, command, and first error.
Trace the first divergent request through sequence, driver, pins, monitor, and
scoreboard before inspecting later cascades.
