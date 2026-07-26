// Low-level sequence API: wait_for_grant / send_request / wait_for_item_done
class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1)

  transaction trans;

  function new(input string inst = "seq1");
    super.new(inst);
  endfunction

  virtual task body();
    `uvm_info("SEQ1", "Trans obj Created" , UVM_NONE);
    trans = transaction::type_id::create("trans");
    `uvm_info("SEQ1", "Waiting for Grant from Driver" , UVM_NONE);
    wait_for_grant();
    `uvm_info("SEQ1", "Rcvd Grant..Randomizing Data" , UVM_NONE);
    assert(trans.randomize());
    `uvm_info("SEQ1", "Randomization Done -> Sent Req to Drv" , UVM_NONE);
    send_request(trans);
    `uvm_info("SEQ1", "Waiting for Item Done Resp from Driver" , UVM_NONE);
    wait_for_item_done();
    `uvm_info("SEQ1", "SEQ1 Ended" , UVM_NONE);
  endtask

endclass
