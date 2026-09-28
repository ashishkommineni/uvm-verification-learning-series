class mini_bus_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mini_bus_scoreboard)
  uvm_analysis_imp #(mini_bus_item, mini_bus_scoreboard) analysis_export;
  bit [MINI_DATA_WIDTH-1:0] model [1 << MINI_ADDR_WIDTH];
  int unsigned expected_count;
  int unsigned seen;
  int unsigned writes;
  int unsigned reads;
  int unsigned errors;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
    foreach (model[index]) model[index] = '0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(int unsigned)::get(this, "", "expected_count", expected_count))
      `uvm_fatal("NOCNT", "Expected transaction count was not configured")
  endfunction

  function void write(mini_bus_item tr);
    seen++;
    if (tr.write) begin
      model[tr.address] = tr.data;
      writes++;
    end else begin
      reads++;
      if (tr.response_data !== model[tr.address]) begin
        errors++;
        `uvm_error("DATA", $sformatf(
          "address=0x%0h expected=0x%0h actual=0x%0h",
          tr.address, model[tr.address], tr.response_data))
      end
    end
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (seen != expected_count) begin
      errors++;
      `uvm_error("COUNT", $sformatf("Expected %0d transactions, observed %0d",
                                    expected_count, seen))
    end
    if (writes == 0 || reads == 0) begin
      errors++;
      `uvm_error("TRAFFIC", "Both read and write traffic must be observed")
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", $sformatf(
      "seen=%0d writes=%0d reads=%0d errors=%0d",
      seen, writes, reads, errors), UVM_NONE)
  endfunction
endclass
