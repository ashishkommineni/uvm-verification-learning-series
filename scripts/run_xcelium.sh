#!/usr/bin/env bash
set -euo pipefail

test_name=${TEST:-mini_bus_test}
seed=${SEED:-13}
command -v xrun >/dev/null 2>&1 || {
  echo "xrun was not found. Load the Cadence Xcelium environment first." >&2
  exit 127
}

result_dir="results/xcelium/${test_name}_seed${seed}"
mkdir -p "$result_dir"

xrun -64bit -uvm -sv -timescale 1ns/1ps \
  -f sim/files.f -top tb_top \
  +UVM_TESTNAME="$test_name" -svseed "$seed" \
  -coverage all -covoverwrite -covworkdir "$result_dir/cov" \
  -l "$result_dir/xrun.log"

grep -Eq '\[SCOREBOARD\].*errors=0' "$result_dir/xrun.log"
grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0' "$result_dir/xrun.log"
grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0' "$result_dir/xrun.log"
echo "Xcelium UVM run: PASS ($test_name, seed=$seed)"
