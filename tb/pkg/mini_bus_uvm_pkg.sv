package mini_bus_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  parameter int unsigned MINI_ADDR_WIDTH = 4;
  parameter int unsigned MINI_DATA_WIDTH = 8;

  `include "mini_bus_item.svh"
  `include "mini_bus_sequences.svh"
  `include "mini_bus_driver.svh"
  `include "mini_bus_monitor.svh"
  `include "mini_bus_agent.svh"
  `include "mini_bus_scoreboard.svh"
  `include "mini_bus_coverage.svh"
  `include "mini_bus_env.svh"
  `include "mini_bus_tests.svh"
endpackage
