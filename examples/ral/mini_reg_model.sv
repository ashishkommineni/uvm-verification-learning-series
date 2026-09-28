import uvm_pkg::*;
import mini_bus_uvm_pkg::*;

class mini_control_reg extends uvm_reg;
  `uvm_object_utils(mini_control_reg)
  rand uvm_reg_field enable;
  rand uvm_reg_field mode;

  function new(string name = "mini_control_reg");
    super.new(name, 8, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    enable = uvm_reg_field::type_id::create("enable");
    mode   = uvm_reg_field::type_id::create("mode");
    enable.configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 0);
    mode.configure(this, 2, 1, "RW", 0, 2'b00, 1, 1, 0);
  endfunction
endclass

class mini_reg_block extends uvm_reg_block;
  `uvm_object_utils(mini_reg_block)
  rand mini_control_reg control;

  function new(string name = "mini_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    control = mini_control_reg::type_id::create("control");
    control.configure(this);
    control.build();
    default_map = create_map("default_map", 'h0, 1, UVM_LITTLE_ENDIAN);
    default_map.add_reg(control, 'h0, "RW");
    lock_model();
  endfunction
endclass

class mini_bus_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(mini_bus_reg_adapter)

  function new(string name = "mini_bus_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 0;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    mini_bus_item tr;
    tr = mini_bus_item::type_id::create("tr");
    tr.write   = (rw.kind == UVM_WRITE);
    tr.address = MINI_ADDR_WIDTH'(rw.addr);
    tr.data    = MINI_DATA_WIDTH'(rw.data);
    return tr;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item,
                                ref uvm_reg_bus_op rw);
    mini_bus_item tr;
    if (!$cast(tr, bus_item)) begin
      rw.status = UVM_NOT_OK;
      return;
    end
    rw.kind   = tr.write ? UVM_WRITE : UVM_READ;
    rw.addr   = tr.address;
    rw.data   = tr.write ? tr.data : tr.response_data;
    rw.status = UVM_IS_OK;
  endfunction
endclass
