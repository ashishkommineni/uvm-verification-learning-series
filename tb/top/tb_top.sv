module tb_top;
  import uvm_pkg::*;
  import mini_bus_uvm_pkg::*;

  logic clk = 1'b0;
  always #5ns clk = ~clk;

  mini_bus_if #(MINI_ADDR_WIDTH, MINI_DATA_WIDTH) bus(clk);

  mini_bus_memory #(
    .ADDR_WIDTH(MINI_ADDR_WIDTH),
    .DATA_WIDTH(MINI_DATA_WIDTH)
  ) dut (
    .clk(bus.clk),
    .reset_n(bus.reset_n),
    .req(bus.req),
    .write(bus.write),
    .address(bus.address),
    .write_data(bus.write_data),
    .ready(bus.ready),
    .response_valid(bus.response_valid),
    .read_data(bus.read_data)
  );

  mini_bus_sva #(
    .ADDR_WIDTH(MINI_ADDR_WIDTH),
    .DATA_WIDTH(MINI_DATA_WIDTH)
  ) protocol_checks (
    .clk(bus.clk),
    .reset_n(bus.reset_n),
    .req(bus.req),
    .write(bus.write),
    .address(bus.address),
    .write_data(bus.write_data),
    .ready(bus.ready),
    .response_valid(bus.response_valid),
    .read_data(bus.read_data)
  );

  initial begin
    bus.reset_n = 1'b0;
    bus.req = 1'b0;
    bus.write = 1'b0;
    bus.address = '0;
    bus.write_data = '0;
    repeat (4) @(posedge clk);
    bus.reset_n = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual mini_bus_if #(MINI_ADDR_WIDTH, MINI_DATA_WIDTH))::set(
      null, "uvm_test_top.env.agent.*", "vif", bus);
    run_test();
  end
endmodule
