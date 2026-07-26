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
    // e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_RANDOM);  UVM_SEQ_ARB_FIFO
    fork
      s2.start(e.a.seq);
      s1.start(e.a.seq);
    join
    phase.drop_objection(this);
  endtask

endclass
