class mini_bus_item extends uvm_sequence_item;
  rand bit                       write;
  rand bit [MINI_ADDR_WIDTH-1:0] address;
  rand bit [MINI_DATA_WIDTH-1:0] data;
       bit [MINI_DATA_WIDTH-1:0] response_data;

  constraint operation_c { write dist {1 := 1, 0 := 1}; }

  `uvm_object_utils(mini_bus_item)

  function new(string name = "mini_bus_item");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    mini_bus_item source;
    super.do_copy(rhs);
    if (!$cast(source, rhs))
      `uvm_fatal("COPY", "mini_bus_item::do_copy received an incompatible object")
    write         = source.write;
    address       = source.address;
    data          = source.data;
    response_data = source.response_data;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    mini_bus_item other;
    if (!$cast(other, rhs))
      return 1'b0;
    return super.do_compare(rhs, comparer) &&
           write == other.write && address == other.address &&
           data == other.data && response_data == other.response_data;
  endfunction

  virtual function string convert2string();
    return $sformatf("write=%0b address=0x%0h data=0x%0h response=0x%0h",
                     write, address, data, response_data);
  endfunction
endclass

class boundary_bus_item extends mini_bus_item;
  constraint boundary_address_c {
    address inside {
      MINI_ADDR_WIDTH'(0),
      MINI_ADDR_WIDTH'((1 << MINI_ADDR_WIDTH) - 1)
    };
  }

  `uvm_object_utils(boundary_bus_item)

  function new(string name = "boundary_bus_item");
    super.new(name);
  endfunction
endclass

class mini_bus_driver_callback extends uvm_callback;
  `uvm_object_utils(mini_bus_driver_callback)

  function new(string name = "mini_bus_driver_callback");
    super.new(name);
  endfunction

  virtual function void before_drive(ref mini_bus_item tr);
  endfunction
endclass
