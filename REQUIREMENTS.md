# Requirements

## Primary sign-off path

- Cadence Xcelium with an active license and `xrun` on `PATH`.
- SystemVerilog and UVM support supplied by the simulator.
- GNU Make and Bash.

## Portable learning path

- A recent Verilator release with class/UVM support.
- Accellera UVM 2020.3.1 source checkout; set `UVM_HOME` to its root.
- Z3 on `PATH` for constrained randomization.
- A C++20 compiler.

The portable path disables DPI and covergroups because those features are not
the sign-off target here. Functional coverage and code coverage are enabled by
the Xcelium command. The repository never claims an Xcelium run unless `xrun`
was actually available and executed.
