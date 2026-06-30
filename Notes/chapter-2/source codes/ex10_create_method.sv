// ex08: Demonstrates DEEP copy using clone() (copy() works the same way)
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

class second extends uvm_object;
  first f;
  function new(string path = "second");
    super.new(path);
    f = new("first");
  endfunction
  `uvm_object_utils_begin(second)
    `uvm_field_object(f, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

module tb;
  second s1, s2;
  initial begin
    s1 = new("s1");
    s1.f.randomize();

    // s2.copy(s1);       // alternative deep copy approach (needs s2 pre-allocated)
    $cast(s2, s1.clone()); // DEEP copy: s2 gets its OWN independent 'first' object

    s1.print();
    s2.print();

    s2.f.data = 12;        // modifying s2's nested object...
    s1.print();             // ...s1 is UNCHANGED, proving independence
    s2.print();
  end
endmodule
