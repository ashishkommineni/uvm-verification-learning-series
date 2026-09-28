class mini_bus_coverage extends uvm_subscriber #(mini_bus_item);
  `uvm_component_utils(mini_bus_coverage)
  mini_bus_item sample;
  int unsigned samples;

`ifndef VERILATOR
  covergroup mini_bus_cg;
    option.per_instance = 1;
    cp_operation: coverpoint sample.write {
      bins read  = {0};
      bins write = {1};
    }
    cp_address: coverpoint sample.address {
      bins first  = {0};
      bins middle = {[1:(1 << MINI_ADDR_WIDTH)-2]};
      bins last   = {(1 << MINI_ADDR_WIDTH)-1};
    }
    cp_data: coverpoint sample.data {
      bins zero  = {0};
      bins ones  = {{MINI_DATA_WIDTH{1'b1}}};
      bins other = default;
    }
    operation_x_address: cross cp_operation, cp_address;
  endgroup
`endif

  function new(string name, uvm_component parent);
    super.new(name, parent);
`ifndef VERILATOR
    mini_bus_cg = new;
`endif
  endfunction

  function void write(mini_bus_item tr);
    sample = tr;
    samples++;
`ifndef VERILATOR
    mini_bus_cg.sample();
`endif
  endfunction
endclass
