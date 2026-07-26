// Example 2: uvm_blocking_put_port connected DIRECTLY to uvm_blocking_put_imp
// (no export in between). Port is created/allocated in build_phase (recommended
// pattern, unlike Example 1 which allocated it in new()).
`include "uvm_macros.svh"
import uvm_pkg::*;

class producer extends uvm_component;
  `uvm_component_utils(producer)

  int data = 12;
  uvm_blocking_put_port #(int) send;

  function new(input string path = "producer", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    send  = new("send", this);
  endfunction

  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("PROD", $sformatf("Data Sent : %0d", data), UVM_NONE);
    send.put(data);
    phase.drop_objection(this);
  endtask
endclass

class consumer extends uvm_component;
  `uvm_component_utils(consumer)

  uvm_blocking_put_imp#(int, consumer) imp;

  function new(input string path = "consumer", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp  = new("imp", this);
  endfunction

  // NOTE: implemented as a `function`, not a `task`, because put() here does
  // no time-consuming work. uvm_blocking_put_imp only requires the method
  // signature to match; it can be function or task depending on your need.
  function void put(int datar);
    `uvm_info("Cons", $sformatf("Data Rcvd : %0d", datar), UVM_NONE);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env)
  producer p;
  consumer c;

  function new(input string inst = "env", uvm_component c);
    super.new(inst, c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    p = producer::type_id::create("p",this);
    c = consumer::type_id::create("c", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    p.send.connect(c.imp);   // direct port -> imp
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
NOTE: env's and test's new() signature above (uvm_component c) is unusual;
the idiomatic UVM signature is:
  function new(string name, uvm_component parent);
Both work because 'c' is just a parameter name here, but for consistency and
readability always name the parent argument 'parent'. See notes/00 prerequisites.

DATA FLOW: Producer --port--> Imp --calls--> Consumer.put()
OUTPUT:
UVM_INFO ... [PROD] Data Sent : 12
UVM_INFO ... [Cons] Data Rcvd : 12
*/
