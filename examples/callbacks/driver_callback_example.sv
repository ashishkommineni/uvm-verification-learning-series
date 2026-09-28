import uvm_pkg::*;
import mini_bus_uvm_pkg::*;

class mini_bus_trace_callback extends mini_bus_driver_callback;
  `uvm_object_utils(mini_bus_trace_callback)

  function new(string name = "mini_bus_trace_callback");
    super.new(name);
  endfunction

  virtual function void before_drive(ref mini_bus_item tr);
    `uvm_info("CALLBACK", $sformatf("about to drive %s", tr.convert2string()),
              UVM_HIGH)
  endfunction
endclass

class mini_bus_callback_test extends mini_bus_test;
  `uvm_component_utils(mini_bus_callback_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    mini_bus_trace_callback trace;
    super.end_of_elaboration_phase(phase);
    trace = mini_bus_trace_callback::type_id::create("trace");
    uvm_callbacks#(mini_bus_driver, mini_bus_driver_callback)::add(env.agent.driver,
                                                                  trace);
  endfunction
endclass
