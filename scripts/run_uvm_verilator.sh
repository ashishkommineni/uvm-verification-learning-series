#!/usr/bin/env bash
set -euo pipefail

verilator_bin=${VERILATOR:-verilator}
test_name=${TEST:-mini_bus_test}
seed=${SEED:-13}
jobs=${JOBS:-2}
: "${UVM_HOME:?Set UVM_HOME to an Accellera UVM source checkout}"
[[ -f "$UVM_HOME/src/uvm_pkg.sv" ]] || {
  echo "UVM_HOME does not contain src/uvm_pkg.sv" >&2
  exit 2
}
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || {
  echo "JOBS must be a positive integer" >&2
  exit 2
}

build_dir="build/uvm_verilator/${test_name}_seed${seed}"
model_dir="build/uvm_verilator/model"
signature_file="$model_dir/source.sha256"
mkdir -p "$build_dir" "$model_dir"

command -v z3 >/dev/null 2>&1 || {
  echo "A z3 executable is required by Verilator constrained randomization." >&2
  exit 127
}

model_signature=$(
  {
    printf '%s\n' 'verilator --cc --exe --main --timing --assert UVM_NO_DPI C++20'
    "$verilator_bin" --version
    find "$UVM_HOME/src" rtl tb -type f \
      \( -name '*.sv' -o -name '*.svh' \) -print0 \
      | sort -z | xargs -0 sha256sum
    sha256sum sim/files_verilator.f "$0"
  } | sha256sum | awk '{print $1}'
)

stored_signature=''
[[ -f "$signature_file" ]] && stored_signature=$(<"$signature_file")

if [[ ! -f "$model_dir/obj/Vtb_top.mk" ||
      ! -x "$model_dir/obj/Vtb_top" ||
      "$model_signature" != "$stored_signature" ]]; then
  "$verilator_bin" --cc --exe --main --timing --assert -Wall -Wno-fatal \
    -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-CASTCONST \
    --top-module tb_top --Mdir "$model_dir/obj" \
    -DUVM_NO_DPI -I"$UVM_HOME/src" \
    "$UVM_HOME/src/uvm_pkg.sv" -f sim/files_verilator.f \
    >"$model_dir/generate.log" 2>&1
  printf '%s\n' "$model_signature" >"$signature_file"
fi

make -C "$model_dir/obj" -f Vtb_top.mk -j "$jobs" \
  CXX=c++ LINK=c++ AR=ar \
  OPT_FAST=-O0 OPT_SLOW=-O0 OPT_GLOBAL=-O0 \
  CFG_CXXFLAGS_STD='--std=c++20' \
  CFG_CXXFLAGS_PCH_I=-include \
  CFG_LDLIBS_THREADS=-pthread \
  >"$model_dir/build.log" 2>&1

"$model_dir/obj/Vtb_top" \
  +UVM_TESTNAME="$test_name" +UVM_NO_RELNOTES +ntb_random_seed="$seed" \
  | tee "$build_dir/run.log"

grep -Eq '\[SCOREBOARD\].*errors=0' "$build_dir/run.log"
grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0' "$build_dir/run.log"
grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0' "$build_dir/run.log"
echo "Portable full-UVM run: PASS ($test_name, seed=$seed)"
