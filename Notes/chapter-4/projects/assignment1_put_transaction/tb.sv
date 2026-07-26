// ASSIGNMENT 1
// Task: Send transaction data from COMPA to COMPB using TLM put port -> put imp.
// This upgrades earlier examples from a plain `int` payload to a real
// uvm_sequence_item-derived transaction object (the pattern real UVM
// testbenches use for driver/monitor/scoreboard communication).
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;

  bit [3:0] a = 12;
  bit [4:0] b = 24;
  int       c = 256;

  function new(string inst = "transaction");
    super.new(inst);
  endfunction

  `uvm_object_utils_begin(transaction)
    `uvm_field_int(a, UVM_DEFAULT | UVM_DEC);
    `uvm_field_int(b, UVM_DEFAULT | UVM_DEC);
    `uvm_field_int(c, UVM_DEFAULT | UVM_DEC);
  `uvm_object_utils_end

endclass

class COMPA extends uvm_component;
  `uvm_component_utils(COMPA)
  transaction tr;
  uvm_blocking_put_port #(transaction) send;

  function new(input string path = "COMPA", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    send  = new("send", this);
    tr = transaction::type_id::create("tr",this);
  endfunction

  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("COMPA", $sformatf("Data Sent :a-> %0d,b->%0d,c->%0d", tr.a,tr.b,tr.c), UVM_NONE);
    send.put(tr);
    phase.drop_objection(this);
  endtask
endclass

class COMPB extends uvm_component;
  `uvm_component_utils(COMPB)
  uvm_blocking_put_imp#(transaction, COMPB) imp;

  function new(input string path = "COMPB", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp  = new("imp", this);
  endfunction

  function void put(transaction tr);
    `uvm_info("COMPB", $sformatf("Data received :a-> %0d,b->%0d,c->%0d",tr.a,tr.b,tr.c), UVM_NONE);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env)
  COMPA p;
  COMPB c;

  function new(input string inst = "env", uvm_component c);
    super.new(inst, c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    p = COMPA::type_id::create("p",this);
    c = COMPB::type_id::create("c", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    p.send.connect(c.imp);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test)
  env e;

  function new(input string inst = "test", uvm_component c);
    super.new(inst, c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e",this);
  endfunction
endclass

module tb;
  initial begin
    run_test("test");
  end
endmodule

/*
OUTPUT:
UVM_INFO ... [COMPA] Data Sent :a-> 12,b->24,c->256
UVM_INFO ... [COMPB] Data received :a-> 12,b->24,c->256
*/
