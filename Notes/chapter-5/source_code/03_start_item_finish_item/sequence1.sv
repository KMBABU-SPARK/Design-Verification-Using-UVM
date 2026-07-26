// High-level sequence API: start_item / finish_item
class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1)
  transaction trans;

  function new(string path = "sequence1");
    super.new(path);
  endfunction

  virtual task body();
    repeat(5) begin
      trans = transaction::type_id::create("trans");
      // simplest way to use the sequence to generate and send the data to driver class
      start_item(trans);
      assert(trans.randomize);
      finish_item(trans);
      `uvm_info("SEQ", $sformatf("a : %0d b:%0d", trans.a, trans.b), UVM_NONE);
    end
  endtask
endclass
