# Verification report

Last checked: 2026-10-04.

This report distinguishes checks executed on the current commit from older
recorded results that still need a full rerun.

| Check | Tool | Status | Evidence |
|---|---|---|---|
| Repository structure and depth gate | Hosted Bash/ripgrep | PASS on current commit | 22 lesson guides, 80 numbered Q&A, and every concept chapter passed the minimum-depth/code/interview checks |
| Markdown link integrity | Hosted Bash/Python | PASS on current commit | All repository-relative Markdown links resolved |
| Mini-bus RTL plus live SVA smoke | Hosted Verilator 5.020 | PASS on current commit | `MINI_BUS_SMOKE PASS checks=4`; GitHub Actions run [#4](https://github.com/ashishkommineni/uvm-verification-learning-series/actions/runs/37199365116) |
| Core and seven focused advanced examples lint | Verilator 5.49 + Accellera UVM 2020.3.1 | Recorded PASS on 2026-09-28 | Configuration, TLM, response, services, callback, virtual-sequence, and RAL examples linted with the complete UVM package; not rerun after the SVA portability edit |
| Full `mini_bus_test`, seed 13 | Verilator 5.49 + Accellera UVM 2020.3.1 | Recorded PASS on 2026-09-28 | `seen=44 writes=22 reads=22 errors=0`; rerun required before treating this as current-commit evidence |
| Full boundary test, seed 31 | Verilator 5.49 + Accellera UVM 2020.3.1 | Recorded PASS on 2026-09-28 | `seen=20 writes=5 reads=15 errors=0`; rerun required before treating this as current-commit evidence |
| Full tests and coverage | Cadence Xcelium | Not run here | Requires installed licensed `xrun` |

## Portability defects found in hosted CI

The first hosted runs failed before simulation for three separate portability
reasons:

1. The repository-depth check used `rg`, but the runner installed only
   Verilator. The workflow now installs `ripgrep` explicitly.
2. Verilator 5.020 did not accept a parameterized interface type as the SVA
   module port. The property module now receives explicit typed signals, while
   both the UVM top and portable smoke connect those signals by name.
3. Verilator 5.020 did not support module-level `default disable iff`. Reset
   disabling now appears inside each property, preserving the assertion intent.

The smoke script was also changed to print its saved build log when compilation
fails. That diagnostic change exposed the two language-support issues instead
of leaving only a generic Make error. After these corrections, the current
hosted run passed the structure gate, link check, RTL build, live assertions,
self-checking data comparisons, and PASS-token check.

## Full-UVM boundary

The earlier portable full-UVM runs define `UVM_NO_DPI`, so warnings about DPI
and component-name checking are expected. Covergroups are disabled only on that
portable path. Functional, code, and assertion coverage remain Xcelium sign-off
items and are not represented by an estimated percentage.

## Review contract

- “PASS on current commit” means the command completed against the current
  source and its log met stable pass criteria.
- “Recorded PASS” preserves useful history but is not silently promoted to
  current-commit proof after an affected source change.
- “Not run here” is a stated tool boundary, not a passing result.
- Any source change requires the affected check to be rerun before sign-off.
