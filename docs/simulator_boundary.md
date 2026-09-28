# Simulator boundary

The intended full run uses Cadence Xcelium because the project owner has access
to it. Xcelium owns functional/code/assertion coverage sign-off.

The portable path has two roles:

1. `make check` builds the synthesizable RTL, interface, SVA, and self-checking
   module test without requiring a UVM library.
2. With a recent Verilator, Accellera UVM, and Z3, `make uvm-lint` and
   `make uvm-portable` compile and execute the class-based environment.

`UVM_NO_DPI` warnings are expected on the portable route. Covergroups are
conditionally excluded there because they are not portable coverage evidence.
No document may convert an expected command into a claimed result.
