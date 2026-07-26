// Demonstrates priority (Chapter 13): s2 (priority 200) wins over s1 (priority 100)
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_FIFO);
  fork
    s1.start(e.a.seq, null, 100);
    s2.start(e.a.seq, null, 200);
  join
  phase.drop_objection(this);
endtask
