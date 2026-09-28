class mini_bus_directed_sequence extends uvm_sequence #(mini_bus_item);
  `uvm_object_utils(mini_bus_directed_sequence)

  function new(string name = "mini_bus_directed_sequence");
    super.new(name);
  endfunction

  task send_item(bit write_value,
                 bit [MINI_ADDR_WIDTH-1:0] address_value,
                 bit [MINI_DATA_WIDTH-1:0] data_value);
    mini_bus_item tr;
    tr = mini_bus_item::type_id::create("tr");
    start_item(tr);
    tr.write   = write_value;
    tr.address = address_value;
    tr.data    = data_value;
    finish_item(tr);
  endtask

  task body();
    send_item(1'b1, MINI_ADDR_WIDTH'(0), 8'h12);
    send_item(1'b0, MINI_ADDR_WIDTH'(0), '0);
    send_item(1'b1, {MINI_ADDR_WIDTH{1'b1}}, 8'hA5);
    send_item(1'b0, {MINI_ADDR_WIDTH{1'b1}}, '0);
  endtask
endclass

class mini_bus_random_sequence extends uvm_sequence #(mini_bus_item);
  `uvm_object_utils(mini_bus_random_sequence)
  int unsigned count = 40;
  bit guarantee_operation_mix;

  function new(string name = "mini_bus_random_sequence");
    super.new(name);
  endfunction

  task body();
    bit randomize_ok;

    if (guarantee_operation_mix && count < 2)
      `uvm_fatal("COUNT", "At least two items are required to guarantee a read/write mix")

    for (int unsigned index = 0; index < count; index++) begin
      req = mini_bus_item::type_id::create("req");
      start_item(req);
      randomize_ok = req.randomize();
      if (!randomize_ok)
        `uvm_fatal("RAND", $sformatf("mini_bus_item randomization failed at index %0d",
                                     index))
      // Address and data remain constrained-random. The first two operation
      // fields are directed only when a test requires a deterministic mix.
      if (guarantee_operation_mix && index == 0)
        req.write = 1'b1;
      else if (guarantee_operation_mix && index == 1)
        req.write = 1'b0;
      finish_item(req);
    end
  endtask
endclass
