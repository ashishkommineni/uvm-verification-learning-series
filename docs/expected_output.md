# Expected output

This file defines stable markers. It is not evidence of execution.

## Portable RTL/SVA smoke

```text
MINI_BUS_SMOKE PASS checks=4
RTL and SVA smoke: PASS
```

## `mini_bus_test`

```text
UVM_INFO ... [SCOREBOARD] seen=44 writes=<non-zero> reads=<non-zero> errors=0
UVM_ERROR :    0
UVM_FATAL :    0
```

## `mini_bus_boundary_test`

```text
UVM_INFO ... [SCOREBOARD] seen=20 writes=<non-zero> reads=<non-zero> errors=0
UVM_ERROR :    0
UVM_FATAL :    0
```

The exact read/write split is seed-dependent, but each test guarantees at least
one of each operation. Exact total counts and zero errors are the stable pass
criteria.
