#!/usr/bin/env bash
set -euo pipefail

verilator_bin=${VERILATOR:-verilator}
build_dir=build/rtl_smoke
mkdir -p "$build_dir"

"$verilator_bin" --binary --timing --assert -Wall -Wno-fatal \
  --top-module mini_bus_smoke --Mdir "$build_dir/obj" \
  tb/interfaces/mini_bus_if.sv \
  rtl/mini_bus_memory.sv \
  tb/assertions/mini_bus_sva.sv \
  tb/smoke/mini_bus_smoke.sv \
  >"$build_dir/build.log" 2>&1

"$build_dir/obj/Vmini_bus_smoke" | tee "$build_dir/run.log"
grep -q 'MINI_BUS_SMOKE PASS checks=4' "$build_dir/run.log"
echo "RTL and SVA smoke: PASS"
