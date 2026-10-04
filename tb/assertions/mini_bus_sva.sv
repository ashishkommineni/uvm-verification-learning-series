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

  request_gets_response:
    assert property (disable iff (!reset_n)
                     req && ready |=> response_valid)
      else $error("Accepted request did not receive a next-cycle response");

  response_has_request:
    assert property (disable iff (!reset_n)
                     response_valid |-> $past(req && ready))
      else $error("Response appeared without a prior accepted request");

  request_stable_while_waiting:
    assert property (disable iff (!reset_n)
                     req && !ready |=>
                     req && $stable({write, address, write_data}))
      else $error("Request changed while stalled");

  known_control:
    assert property (disable iff (!reset_n)
                     !$isunknown({req, write, ready, response_valid}))
      else $error("Unknown mini-bus control signal after reset");

  cover_read:
    cover property (disable iff (!reset_n) req && ready && !write);

  cover_write:
    cover property (disable iff (!reset_n) req && ready && write);

  // Keep read_data in the port list so future response-data properties can be
  // added without changing the binding interface.
  observed_known_read_data:
    cover property (disable iff (!reset_n)
                    response_valid && !$isunknown(read_data));
endmodule
