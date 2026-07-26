// Demonstrates arbitration modes (Chapter 12).
// Uncomment ONE set_arbitration line at a time to observe the difference.
class test extends uvm_test;
  `uvm_component_utils(test)

  function new(input string inst = "TEST", uvm_component c);
    super.new(inst,c);
  endfunction

  sequence1 s1;
  sequence2 s2;
  env e;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("ENV",this);
    s1 = sequence1::type_id::create("s1");
    s2 = sequence2::type_id::create("s2");
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    // NOTE: IF NO ARBITRATION MENTIONED, SEQ_ARB_FIFO IS DEFAULT
    // e.a.seq.set_arbitration(UVM_SEQ_ARB_WEIGHTED);
    // e.a.seq.set_arbitration(UVM_SEQ_ARB_RANDOM);
    e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_FIFO);
    // e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_RANDOM);
    fork
      repeat(5) s2.start(e.a.seq, null, 100); // sequencer, parent sequence, priority, call_pre_post
      repeat(5) s1.start(e.a.seq, null, 100); // equal priority -> FIFO tie-break
    join
    phase.drop_objection(this);
  endtask

endclass
