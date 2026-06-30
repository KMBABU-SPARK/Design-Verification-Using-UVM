// ex01: Registering a uvm_object and printing a value with `uvm_info
`include "uvm_macros.svh"
import uvm_pkg::*;

class obj extends uvm_object;
  `uvm_object_utils(obj)          // registers 'obj' with the UVM factory

  function new(string path = "obj");
    super.new(path);
  endfunction

  rand bit [3:0] a;
endclass

module tb;
  obj o;
  initial begin
    o = new("obj");
    o.randomize();
    `uvm_info("TB_TOP", $sformatf("Value of a : %0d", o.a), UVM_NONE);
  end
endmodule
