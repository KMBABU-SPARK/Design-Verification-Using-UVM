// ex09: Using the built-in compare() method (auto-generated from field macros)
`include "uvm_macros.svh"
import uvm_pkg::*;

class first extends uvm_object;
  rand bit [3:0] data;
  function new(string path = "first");
    super.new(path);
  endfunction
  `uvm_object_utils_begin(first)
    `uvm_field_int(data, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

module tb;
  first f1, f2;
  int status = 0;
  initial begin
    f1 = new("f1");
    f2 = new("f2");
    f1.randomize();
    f2.copy(f1);
    f1.print();
    f2.print();
    status = f1.compare(f2);            // returns 1 if equal, 0 if different
    $display("Value of status : %0d", status);
  end
endmodule
