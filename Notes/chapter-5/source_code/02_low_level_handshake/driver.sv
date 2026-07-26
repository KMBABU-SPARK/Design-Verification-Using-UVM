class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)

  transaction t;
  virtual adder_if aif;

  function new(input string inst = "DRV", uvm_component c);
    super.new(inst,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("TRANS");
    // this line is used for the creation of the interface btw driver and dut
    if(!uvm_config_db#(virtual adder_if)::get(this,"","aif",aif))
      `uvm_info("DRV", "Unable to access Interface", UVM_NONE);
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      `uvm_info("Drv", "Sending Grant for Sequence" , UVM_NONE);
      seq_item_port.get_next_item(t);
      `uvm_info("Drv", "Applying Seq to DUT" , UVM_NONE);
      `uvm_info("Drv", "Sending Item Done Resp for Sequence" , UVM_NONE);
      seq_item_port.item_done();
    end
  endtask

endclass
