// Minimal SystemVerilog OOP recap - NOT from the source document, added as a
// prerequisite so Chapter 0's concepts have runnable code to point at.

class base;
  int x;
  function new(int x = 0);
    this.x = x;
  endfunction
  virtual function void show();     // 'virtual' enables polymorphism
    $display("base x = %0d", x);
  endfunction
endclass

class derived extends base;         // inheritance
  int y;
  function new(int x = 0, int y = 0);
    super.new(x);                   // must call parent constructor first
    this.y = y;
  endfunction
  virtual function void show();     // overrides base::show()
    $display("derived x = %0d y = %0d", x, y);
  endfunction
endclass

class container #(type T = int);    // parameterized class, like C++ templates
  T value;
  function void set(T v); value = v; endfunction
  function T get(); return value; endfunction
endclass

module tb_oop;
  base b;
  derived d;
  container #(int) c_int;

  initial begin
    d = new(1, 2);
    b = d;          // upcast: base handle pointing to a derived object
    b.show();        // polymorphism -> prints "derived x = 1 y = 2" because show() is virtual

    c_int = new();
    c_int.set(42);
    $display("container holds %0d", c_int.get());
  end
endmodule
