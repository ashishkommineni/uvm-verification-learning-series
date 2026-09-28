interface mini_bus_if #(
  parameter int unsigned ADDR_WIDTH = 4,
  parameter int unsigned DATA_WIDTH = 8
) (input logic clk);
  logic                  reset_n;
  logic                  req;
  logic                  write;
  logic [ADDR_WIDTH-1:0] address;
  logic [DATA_WIDTH-1:0] write_data;
  logic                  ready;
  logic                  response_valid;
  logic [DATA_WIDTH-1:0] read_data;

  clocking driver_cb @(posedge clk);
    default input #1step output #0;
    output req, write, address, write_data;
    input  reset_n, ready, response_valid, read_data;
  endclocking

  clocking monitor_cb @(posedge clk);
    default input #1step;
    input reset_n, req, write, address, write_data;
    input ready, response_valid, read_data;
  endclocking

  modport dut (
    input clk, reset_n, req, write, address, write_data,
    output ready, response_valid, read_data
  );
endinterface
