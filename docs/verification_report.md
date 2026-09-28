# Verification report

Last checked: 2026-09-28.

Status is updated only from commands executed against the current commit.

| Check | Tool | Status | Evidence |
|---|---|---|---|
| Repository structure and depth gate | Bash | PASS | 22 lesson guides, 80 numbered Q&A, and every concept chapter passed the minimum-depth/code/interview checks |
| Markdown link integrity | Bash/Python | PASS | All repository-relative Markdown links resolved |
| Mini-bus RTL plus SVA smoke | Verilator 5.49 | PASS | `MINI_BUS_SMOKE PASS checks=4`; finished at 185 ns |
| Core and seven focused advanced examples lint | Verilator 5.49 + Accellera UVM 2020.3.1 | PASS | Configuration, TLM, response, services, callback, virtual-sequence, and RAL examples linted with the complete UVM package |
| Full `mini_bus_test`, seed 13 | Verilator 5.49 + Accellera UVM 2020.3.1 | PASS | `seen=44 writes=22 reads=22 errors=0`; UVM error/fatal counts are zero |
| Full boundary test, seed 31 | Verilator 5.49 + Accellera UVM 2020.3.1 | PASS | `seen=20 writes=5 reads=15 errors=0`; UVM error/fatal counts are zero |
| Full tests and coverage | Cadence Xcelium | Not run here | Requires installed licensed `xrun` |

The full-UVM scenarios were freshly rerun against the compiled model for the
unchanged RTL/testbench sources; all newly added example sources were compiled
by `uvm-lint`. The portable full-UVM path defines `UVM_NO_DPI`, so library warnings
about DPI and component-name checking are expected. Covergroups are disabled
only on this portable path; functional, code, and assertion coverage remain
Xcelium sign-off items.

## Review contract

- “PASS” means the command completed and its log met stable pass criteria.
- “Not run here” is not a failure and is not silently converted into expected
  output.
- Any source change after a result requires the affected check to be rerun.
