class mini_bus_env extends uvm_env;
  `uvm_component_utils(mini_bus_env)
  mini_bus_agent agent;
  mini_bus_scoreboard scoreboard;
  mini_bus_coverage coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = mini_bus_agent::type_id::create("agent", this);
    scoreboard = mini_bus_scoreboard::type_id::create("scoreboard", this);
    coverage   = mini_bus_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.analysis_port.connect(scoreboard.analysis_export);
    agent.monitor.analysis_port.connect(coverage.analysis_export);
  endfunction
endclass
