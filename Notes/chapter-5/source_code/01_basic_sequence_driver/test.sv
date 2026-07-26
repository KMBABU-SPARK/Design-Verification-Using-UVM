class test extends uvm_test;
  `uvm_component_utils(test)

  function new(input string path = "test", uvm_component parent = null);
    super.new(path,parent);
  endfunction

  sequence1 seq1;
  env e;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e",this);
    seq1 = sequence1::type_id::create("seq1");
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq1.start(e.a.seqr);
    phase.drop_objection(this);
  endtask

endclass
