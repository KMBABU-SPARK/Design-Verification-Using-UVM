class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1)

  function new(input string path = "sequence1");
    super.new(path);
  endfunction

  virtual task pre_body();
    `uvm_info("SEQ1", "PRE-BODY EXECUTED", UVM_NONE);
  endtask

  virtual task body();
    `uvm_info("SEQ1", "BODY EXECUTED", UVM_NONE);
  endtask

  virtual task post_body();
    `uvm_info("SEQ1", "POST-BODY EXECUTED", UVM_NONE);
  endtask

endclass
