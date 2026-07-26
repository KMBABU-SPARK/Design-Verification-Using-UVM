class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  transaction trans;

  function new(input string inst = "DRV", uvm_component c);
    super.new(inst,c);
  endfunction

  virtual task run_phase(uvm_phase phase);
    trans = transaction::type_id::create("trans");
    forever begin
      seq_item_port.get_next_item(trans);
      `uvm_info("DRV", $sformatf("a : %0d b:%0d", trans.a, trans.b), UVM_NONE);
      seq_item_port.item_done();
    end
  endtask

endclass
