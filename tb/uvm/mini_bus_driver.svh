class mini_bus_driver extends uvm_driver #(mini_bus_item);
  `uvm_component_utils(mini_bus_driver)
  `uvm_register_cb(mini_bus_driver, mini_bus_driver_callback)
  virtual mini_bus_if #(MINI_ADDR_WIDTH, MINI_DATA_WIDTH) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual mini_bus_if #(MINI_ADDR_WIDTH, MINI_DATA_WIDTH))::get(
          this, "", "vif", vif))
      `uvm_fatal("NOVIF", "mini_bus_driver did not receive the virtual interface")
  endfunction

  task run_phase(uvm_phase phase);
    vif.driver_cb.req        <= 1'b0;
    vif.driver_cb.write      <= 1'b0;
    vif.driver_cb.address    <= '0;
    vif.driver_cb.write_data <= '0;
    wait (vif.reset_n === 1'b1);

    forever begin
      seq_item_port.get_next_item(req);
      drive_one(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_one(mini_bus_item tr);
    `uvm_do_callbacks(mini_bus_driver, mini_bus_driver_callback, before_drive(tr))
    @(vif.driver_cb);
    vif.driver_cb.req        <= 1'b1;
    vif.driver_cb.write      <= tr.write;
    vif.driver_cb.address    <= tr.address;
    vif.driver_cb.write_data <= tr.data;

    // This mini-bus is always ready.  The request is accepted on this edge,
    // and the DUT returns its response one clock later.  Release the request
    // after acceptance, then sample the response on the next clocking event;
    // checking on the acceptance edge would see the pre-NBA value.
    @(vif.driver_cb);
    vif.driver_cb.req        <= 1'b0;
    vif.driver_cb.write      <= 1'b0;
    vif.driver_cb.address    <= '0;
    vif.driver_cb.write_data <= '0;

    @(vif.driver_cb);
    if (vif.driver_cb.response_valid !== 1'b1)
      `uvm_error("NO_RSP", $sformatf("No response for %s", tr.convert2string()))
  endtask
endclass
