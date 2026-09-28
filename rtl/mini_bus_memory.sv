module mini_bus_memory #(
  parameter int unsigned ADDR_WIDTH = 4,
  parameter int unsigned DATA_WIDTH = 8
) (
  input  logic                  clk,
  input  logic                  reset_n,
  input  logic                  req,
  input  logic                  write,
  input  logic [ADDR_WIDTH-1:0] address,
  input  logic [DATA_WIDTH-1:0] write_data,
  output logic                  ready,
  output logic                  response_valid,
  output logic [DATA_WIDTH-1:0] read_data
);
  logic [DATA_WIDTH-1:0] memory [0:(1 << ADDR_WIDTH)-1];

  assign ready = 1'b1;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      response_valid <= 1'b0;
      read_data      <= '0;
      foreach (memory[index])
        memory[index] <= '0;
    end else begin
      response_valid <= req && ready;
      if (req && ready) begin
        if (write)
          memory[address] <= write_data;
        else
          read_data <= memory[address];
      end
    end
  end
endmodule
