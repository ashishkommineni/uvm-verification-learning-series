import uvm_pkg::*;
import mini_bus_uvm_pkg::*;

// Events represent occurrences; barriers join a known number of participants.
class mini_bus_sync_services_example extends uvm_object;
  `uvm_object_utils(mini_bus_sync_services_example)

  uvm_event   reset_done;
  uvm_barrier workers_done;

  function new(string name = "mini_bus_sync_services_example");
    super.new(name);
    reset_done   = new("reset_done");
    workers_done = new("workers_done", 2);
  endfunction

  task wait_until_reset_done();
    reset_done.wait_trigger();
  endtask

  function void announce_reset_done();
    reset_done.trigger();
  endfunction

  task rendezvous_after_worker();
    workers_done.wait_for();
  endtask
endclass
