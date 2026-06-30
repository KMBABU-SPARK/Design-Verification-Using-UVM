// ex13: Overriding convert2string() to build a custom one-line summary string
`include "uvm_macros.svh"
import uvm_pkg::*;

class obj extends uvm_object;
  `uvm_object_utils(obj)

  function new(string path = "OBJ");
    super.new(path);
  endfunction

  bit [3:0] a = 4;
  string    b = "UVM";
  real      c = 12.34;

  virtual function string convert2string();
    string s = super.convert2string();
    s = {s, $sformatf("a : %0d ", a)};
    s = {s, $sformatf("b : %0s ", b)};
    s = {s, $sformatf("c : %0f ", c)};
    // result e.g: "a : 4 b : UVM c : 12.3400 "
    return s;
  endfunction
endclass

module tb;
  obj o;
  initial begin
    o = obj::type_id::create("o");
    `uvm_info("TB_TOP", $sformatf("%0s", o.convert2string()), UVM_NONE);
  end
endmodule
