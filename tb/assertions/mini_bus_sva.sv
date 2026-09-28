module mini_bus_sva #(
  parameter int unsigned ADDR_WIDTH = 4,
  parameter int unsigned DATA_WIDTH = 8
) (mini_bus_if #(ADDR_WIDTH, DATA_WIDTH) bus);
  default clocking cb @(posedge bus.clk); endclocking
  default disable iff (!bus.reset_n);

  request_gets_response:
    assert property (bus.req && bus.ready |=> bus.response_valid)
      else $error("Accepted request did not receive a next-cycle response");

  response_has_request:
    assert property (bus.response_valid |-> $past(bus.req && bus.ready))
      else $error("Response appeared without a prior accepted request");

  request_stable_while_waiting:
    assert property (bus.req && !bus.ready |=>
                     bus.req && $stable({bus.write, bus.address, bus.write_data}))
      else $error("Request changed while stalled");

  known_control:
    assert property (!$isunknown({bus.req, bus.write, bus.ready,
                                  bus.response_valid}))
      else $error("Unknown mini-bus control signal after reset");

  cover_read:  cover property (bus.req && bus.ready && !bus.write);
  cover_write: cover property (bus.req && bus.ready &&  bus.write);
endmodule
