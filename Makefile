VERILATOR ?= verilator
TEST ?= mini_bus_test
SEED ?= 13
JOBS ?= 2

.PHONY: check structure links smoke uvm uvm-lint uvm-portable regress clean

check: structure links smoke

structure:
	@bash scripts/check_structure.sh

links:
	@bash scripts/check_links.sh

smoke:
	@VERILATOR="$(VERILATOR)" bash scripts/run_rtl_smoke.sh

uvm:
	@TEST="$(TEST)" SEED="$(SEED)" bash scripts/run_xcelium.sh

uvm-lint:
	@VERILATOR="$(VERILATOR)" bash scripts/lint_uvm_examples.sh

uvm-portable:
	@VERILATOR="$(VERILATOR)" TEST="$(TEST)" SEED="$(SEED)" JOBS="$(JOBS)" \
	  bash scripts/run_uvm_verilator.sh

regress:
	@for test in mini_bus_test mini_bus_boundary_test; do \
	  for seed in 13 31 47; do \
	    $(MAKE) uvm TEST=$$test SEED=$$seed || exit 1; \
	  done; \
	done

clean:
	@echo "Remove build/ and results/ only after preserving any logs you need."
