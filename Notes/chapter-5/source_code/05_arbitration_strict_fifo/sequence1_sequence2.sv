class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1)
  transaction trans;

  function new(input string inst = "seq1");
    super.new(inst);
  endfunction

  virtual task body();
    repeat(3) begin
      `uvm_info("SEQ1", "SEQ1 Started" , UVM_NONE);
      trans = transaction::type_id::create("trans");
      start_item(trans);
      assert(trans.randomize);
      finish_item(trans);
      `uvm_info("SEQ1", "SEQ1 Ended" , UVM_NONE);
    end
  endtask
endclass


class sequence2 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence2)
  transaction trans;

  function new(input string inst = "seq2");
    super.new(inst);
  endfunction

  virtual task body();
    repeat(3) begin
      `uvm_info("SEQ2", "SEQ2 Started" , UVM_NONE);
      trans = transaction::type_id::create("trans");
      start_item(trans);
      assert(trans.randomize);
      finish_item(trans);
      `uvm_info("SEQ2", "SEQ2 Ended" , UVM_NONE);
    end
  endtask
endclass
