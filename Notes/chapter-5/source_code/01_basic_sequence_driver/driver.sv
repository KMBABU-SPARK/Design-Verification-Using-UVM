class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)

  transaction t;

  function new(input string path = "DRV", uvm_component parent = null);
    super.new(path,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(t);
      //////apply seq to DUT
      seq_item_port.item_done();
    end
  endtask

endclass
