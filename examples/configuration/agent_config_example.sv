import uvm_pkg::*;
import mini_bus_uvm_pkg::*;

// Focused reference: group related per-agent policy in one typed object.
class mini_bus_agent_cfg_example extends uvm_object;
  `uvm_object_utils(mini_bus_agent_cfg_example)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  virtual mini_bus_if      vif;
  bit                      checks_enable = 1'b1;
  int unsigned             response_timeout_cycles = 20;

  function new(string name = "mini_bus_agent_cfg_example");
    super.new(name);
  endfunction

  function void validate();
    if (vif == null)
      `uvm_fatal("CFG/VIF", "mini_bus_agent_cfg_example.vif is null")
    if (response_timeout_cycles == 0)
      `uvm_fatal("CFG/TIMEOUT", "response_timeout_cycles must be nonzero")
  endfunction
endclass

// A consumer should fail early rather than run with partially resolved policy.
class mini_bus_cfg_consumer_example extends uvm_component;
  `uvm_component_utils(mini_bus_cfg_consumer_example)

  mini_bus_agent_cfg_example cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(mini_bus_agent_cfg_example)::get(this, "", "cfg", cfg))
      `uvm_fatal("CFG/MISSING", {get_full_name(), " requires cfg"})
    cfg.validate();
  endfunction
endclass
