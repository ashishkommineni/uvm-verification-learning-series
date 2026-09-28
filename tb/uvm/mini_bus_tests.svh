class mini_bus_test extends uvm_test;
  `uvm_component_utils(mini_bus_test)
  mini_bus_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    uvm_config_db#(int unsigned)::set(this, "env.scoreboard", "expected_count", 44);
    super.build_phase(phase);
    env = mini_bus_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    mini_bus_directed_sequence directed;
    mini_bus_random_sequence random_sequence;
    phase.raise_objection(this, "starting mini-bus traffic");
    directed = mini_bus_directed_sequence::type_id::create("directed");
    directed.start(env.agent.sequencer);
    random_sequence = mini_bus_random_sequence::type_id::create("random_sequence");
    random_sequence.count = 40;
    random_sequence.start(env.agent.sequencer);
    repeat (4) @(posedge env.agent.monitor.vif.clk);
    phase.drop_objection(this, "mini-bus traffic complete");
  endtask
endclass

class mini_bus_boundary_test extends uvm_test;
  `uvm_component_utils(mini_bus_boundary_test)
  mini_bus_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    mini_bus_item::type_id::set_type_override(boundary_bus_item::get_type());
    uvm_config_db#(int unsigned)::set(this, "env.scoreboard", "expected_count", 20);
    super.build_phase(phase);
    env = mini_bus_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    mini_bus_random_sequence boundary_seq;
    phase.raise_objection(this, "starting factory-override boundary traffic");
    boundary_seq = mini_bus_random_sequence::type_id::create("boundary_seq");
    boundary_seq.count = 20;
    boundary_seq.guarantee_operation_mix = 1'b1;
    boundary_seq.start(env.agent.sequencer);
    repeat (4) @(posedge env.agent.monitor.vif.clk);
    phase.drop_objection(this, "boundary traffic complete");
  endtask
endclass
