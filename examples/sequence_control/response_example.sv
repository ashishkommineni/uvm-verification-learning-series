import uvm_pkg::*;
import mini_bus_uvm_pkg::*;

// Sequence side of an explicit request/response exchange.
class mini_bus_response_sequence_example extends uvm_sequence #(mini_bus_item);
  `uvm_object_utils(mini_bus_response_sequence_example)

  function new(string name = "mini_bus_response_sequence_example");
    super.new(name);
  endfunction

  task body();
    mini_bus_item req;
    mini_bus_item rsp;

    req = mini_bus_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { write == 1'b0; })
      `uvm_fatal("SEQ/RAND", "read request randomization failed")
    finish_item(req);

    // The driver must copy request ID information into its response.
    get_response(rsp);
    `uvm_info("SEQ/RSP", rsp.convert2string(), UVM_MEDIUM)
  endtask
endclass

// This object isolates the driver-side response construction rule. A real
// driver calls item_done(rsp) after the protocol operation completes.
class mini_bus_response_builder_example extends uvm_object;
  `uvm_object_utils(mini_bus_response_builder_example)

  function new(string name = "mini_bus_response_builder_example");
    super.new(name);
  endfunction

  function mini_bus_item make_response(mini_bus_item req,
                                       bit [MINI_DATA_WIDTH-1:0] read_data);
    mini_bus_item rsp;
    rsp = mini_bus_item::type_id::create("rsp");
    rsp.copy(req);
    rsp.response_data = read_data;
    rsp.set_id_info(req);
    return rsp;
  endfunction
endclass
