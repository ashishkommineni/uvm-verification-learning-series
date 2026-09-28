import uvm_pkg::*;
import mini_bus_uvm_pkg::*;

class mini_bus_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(mini_bus_virtual_sequencer)
  mini_bus_sequencer control_sequencer;
  mini_bus_sequencer data_sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class coordinated_bus_sequence extends uvm_sequence;
  `uvm_object_utils(coordinated_bus_sequence)
  `uvm_declare_p_sequencer(mini_bus_virtual_sequencer)

  function new(string name = "coordinated_bus_sequence");
    super.new(name);
  endfunction

  task body();
    mini_bus_directed_sequence control;
    mini_bus_random_sequence data;
    control = mini_bus_directed_sequence::type_id::create("control");
    data = mini_bus_random_sequence::type_id::create("data");
    data.count = 8;
    fork
      control.start(p_sequencer.control_sequencer);
      data.start(p_sequencer.data_sequencer);
    join
  endtask
endclass
