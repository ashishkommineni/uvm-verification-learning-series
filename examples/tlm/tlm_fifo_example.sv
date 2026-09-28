import uvm_pkg::*;
import mini_bus_uvm_pkg::*;

// Implements the callee side of a blocking put interface.
class mini_bus_put_consumer_example extends uvm_component;
  `uvm_component_utils(mini_bus_put_consumer_example)

  uvm_blocking_put_imp #(mini_bus_item, mini_bus_put_consumer_example) put_imp;
  int unsigned received_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    put_imp = new("put_imp", this);
  endfunction

  task put(mini_bus_item tr);
    received_count++;
    `uvm_info("TLM/PUT",
              $sformatf("received[%0d] %s", received_count,
                        tr.convert2string()),
              UVM_HIGH)
  endtask
endclass

// A bounded FIFO provides storage and producer backpressure.
class mini_bus_fifo_holder_example extends uvm_component;
  `uvm_component_utils(mini_bus_fifo_holder_example)

  uvm_tlm_fifo #(mini_bus_item) transaction_fifo;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    transaction_fifo = new("transaction_fifo", this, 8);
  endfunction

  task consume_one();
    mini_bus_item tr;
    transaction_fifo.get(tr);
    `uvm_info("TLM/FIFO", {"consumed ", tr.convert2string()}, UVM_HIGH)
  endtask
endclass
