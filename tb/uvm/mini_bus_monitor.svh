class mini_bus_monitor extends uvm_monitor;
  `uvm_component_utils(mini_bus_monitor)
  virtual mini_bus_if #(MINI_ADDR_WIDTH, MINI_DATA_WIDTH) vif;
  uvm_analysis_port #(mini_bus_item) analysis_port;
  mini_bus_item pending[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual mini_bus_if #(MINI_ADDR_WIDTH, MINI_DATA_WIDTH))::get(
          this, "", "vif", vif))
      `uvm_fatal("NOVIF", "mini_bus_monitor did not receive the virtual interface")
  endfunction

  task run_phase(uvm_phase phase);
    mini_bus_item tr;
    wait (vif.monitor_cb.reset_n === 1'b1);
    forever begin
      @(vif.monitor_cb);

      if (vif.monitor_cb.response_valid) begin
        if (pending.size() == 0) begin
          `uvm_error("SPURIOUS", "Response observed with no pending request")
        end else begin
          tr = pending.pop_front();
          tr.response_data = vif.monitor_cb.read_data;
          analysis_port.write(tr);
        end
      end

      if (vif.monitor_cb.req && vif.monitor_cb.ready) begin
        tr = mini_bus_item::type_id::create("observed_request");
        tr.write   = vif.monitor_cb.write;
        tr.address = vif.monitor_cb.address;
        tr.data    = vif.monitor_cb.write_data;
        pending.push_back(tr);
      end
    end
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (pending.size() != 0)
      `uvm_error("PENDING", $sformatf("%0d request(s) had no response", pending.size()))
  endfunction
endclass
