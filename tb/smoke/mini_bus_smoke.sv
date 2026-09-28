module mini_bus_smoke;
  localparam int unsigned ADDR_WIDTH = 4;
  localparam int unsigned DATA_WIDTH = 8;

  logic clk = 1'b0;
  int unsigned checks;
  always #5ns clk = ~clk;

  mini_bus_if #(ADDR_WIDTH, DATA_WIDTH) bus(clk);

  mini_bus_memory #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
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
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) protocol_checks(bus);

  task automatic transfer(
    input bit write_value,
    input bit [ADDR_WIDTH-1:0] address_value,
    input bit [DATA_WIDTH-1:0] data_value,
    input bit [DATA_WIDTH-1:0] expected_read
  );
    @(negedge clk);
    bus.req        = 1'b1;
    bus.write      = write_value;
    bus.address    = address_value;
    bus.write_data = data_value;
    @(posedge clk);
    @(negedge clk);
    bus.req        = 1'b0;
    bus.write      = 1'b0;
    bus.address    = '0;
    bus.write_data = '0;
    @(posedge clk);
    if (bus.response_valid !== 1'b1)
      $fatal(1, "Missing response at address 0x%0h", address_value);
    if (!write_value) begin
      checks++;
      if (bus.read_data !== expected_read)
        $fatal(1, "Read mismatch address=0x%0h expected=0x%0h actual=0x%0h",
               address_value, expected_read, bus.read_data);
    end
  endtask

  initial begin
    bus.reset_n    = 1'b0;
    bus.req        = 1'b0;
    bus.write      = 1'b0;
    bus.address    = '0;
    bus.write_data = '0;
    repeat (4) @(posedge clk);
    @(negedge clk);
    bus.reset_n = 1'b1;

    transfer(1'b0, 4'h0, 8'h00, 8'h00);
    transfer(1'b1, 4'h0, 8'h12, 8'h00);
    transfer(1'b0, 4'h0, 8'h00, 8'h12);
    transfer(1'b1, 4'hF, 8'hA5, 8'h00);
    transfer(1'b0, 4'hF, 8'h00, 8'hA5);
    transfer(1'b1, 4'h7, 8'h3C, 8'h00);
    transfer(1'b0, 4'h7, 8'h00, 8'h3C);

    $display("MINI_BUS_SMOKE PASS checks=%0d", checks);
    $finish;
  end
endmodule
