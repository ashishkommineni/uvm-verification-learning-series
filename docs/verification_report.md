# Verification report

Last checked: 2026-09-28.

Status is updated only from commands executed against the current commit.

| Check | Tool | Status | Evidence |
|---|---|---|---|
| Repository structure and 60-question count | Bash | PASS | 16 lesson guides and 60 numbered Q&A found |
| Markdown link integrity | Bash/Python | PASS | All repository-relative Markdown links resolved |
| Mini-bus RTL plus SVA smoke | Verilator 5.49 | PASS | `MINI_BUS_SMOKE PASS checks=4`; finished at 185 ns |
| Core, callback, virtual-sequence, and RAL lint | Verilator 5.49 + Accellera UVM 2020.3.1 | PASS | Core and all three focused advanced examples linted |
| Full `mini_bus_test`, seed 13 | Verilator 5.49 + Accellera UVM 2020.3.1 | PASS | `seen=44 writes=22 reads=22 errors=0`; UVM error/fatal counts are zero |
| Full boundary test, seed 31 | Verilator 5.49 + Accellera UVM 2020.3.1 | PASS | `seen=20 writes=5 reads=15 errors=0`; UVM error/fatal counts are zero |
| Full tests and coverage | Cadence Xcelium | Not run here | Requires installed licensed `xrun` |

The portable full-UVM runs define `UVM_NO_DPI`, so the two library warnings
about DPI and component-name checking are expected. Covergroups are disabled
only on this portable path; functional, code, and assertion coverage remain
Xcelium sign-off items.

## Review contract

- “PASS” means the command completed and its log met stable pass criteria.
- “Not run here” is not a failure and is not silently converted into expected
  output.
- Any source change after a result requires the affected check to be rerun.
