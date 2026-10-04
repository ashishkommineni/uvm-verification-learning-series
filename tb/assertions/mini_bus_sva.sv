module mini_bus_sva #(
  parameter int unsigned ADDR_WIDTH = 4,
  parameter int unsigned DATA_WIDTH = 8
) (
  input logic                  clk,
  input logic                  reset_n,
  input logic                  req,
  input logic                  write,
  input logic [ADDR_WIDTH-1:0] address,
  input logic [DATA_WIDTH-1:0] write_data,
  input logic                  ready,
  input logic                  response_valid,
  input logic [DATA_WIDTH-1:0] read_data
);
  default clocking cb @(posedge clk); endclocking
  default disable iff (!reset_n);

  request_gets_response:
    assert property (req && ready |=> response_valid)
      else $error("Accepted request did not receive a next-cycle response");

  response_has_request:
    assert property (response_valid |-> $past(req && ready))
      else $error("Response appeared without a prior accepted request");

  request_stable_while_waiting:
    assert property (req && !ready |=>
                     req && $stable({write, address, write_data}))
      else $error("Request changed while stalled");

  known_control:
    assert property (!$isunknown({req, write, ready, response_valid}))
      else $error("Unknown mini-bus control signal after reset");

  cover_read:  cover property (req && ready && !write);
  cover_write: cover property (req && ready &&  write);

  // Keep read_data in the port list so future response-data properties can be
  // added without changing the binding interface.
  unused_read_data_known:
    cover property (response_valid && !$isunknown(read_data));
endmodule
