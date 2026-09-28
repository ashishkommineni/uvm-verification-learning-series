class mini_bus_sequencer extends uvm_sequencer #(mini_bus_item);
  `uvm_component_utils(mini_bus_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class mini_bus_agent extends uvm_agent;
  `uvm_component_utils(mini_bus_agent)
  mini_bus_sequencer sequencer;
  mini_bus_driver driver;
  mini_bus_monitor monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = mini_bus_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = mini_bus_sequencer::type_id::create("sequencer", this);
      driver    = mini_bus_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass
