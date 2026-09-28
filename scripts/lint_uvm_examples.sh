#!/usr/bin/env bash
set -euo pipefail

verilator_bin=${VERILATOR:-verilator}
: "${UVM_HOME:?Set UVM_HOME to an Accellera UVM source checkout}"
[[ -f "$UVM_HOME/src/uvm_pkg.sv" ]] || {
  echo "UVM_HOME does not contain src/uvm_pkg.sv" >&2
  exit 2
}

build_dir=build/uvm_lint
mkdir -p "$build_dir"

"$verilator_bin" --lint-only --timing --assert -Wall -Wno-fatal \
  -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-CASTCONST \
  -DUVM_NO_DPI -I"$UVM_HOME/src" -Itb/uvm \
  "$UVM_HOME/src/uvm_pkg.sv" \
  tb/interfaces/mini_bus_if.sv \
  rtl/mini_bus_memory.sv \
  tb/assertions/mini_bus_sva.sv \
  tb/pkg/mini_bus_uvm_pkg.sv \
  examples/configuration/agent_config_example.sv \
  examples/tlm/tlm_fifo_example.sv \
  examples/sequence_control/response_example.sv \
  examples/services/sync_services_example.sv \
  examples/callbacks/driver_callback_example.sv \
  examples/virtual_sequences/coordination_example.sv \
  examples/ral/mini_reg_model.sv \
  >"$build_dir/lint.log" 2>&1

echo "Core and advanced UVM examples lint: PASS"
