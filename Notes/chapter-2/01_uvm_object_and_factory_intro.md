# Chapter 1 — What is `uvm_object` and the UVM Factory?

## Chapter Overview
Introduces the UVM class library's base data class (`uvm_object`), why UVM wraps
plain SystemVerilog classes with macros, and what the "factory" actually is.

## Learning Objectives
- Explain why UVM doesn't just use plain SystemVerilog classes.
- Know what `uvm_object` provides "for free" (name, printing, copying, comparing).
- Understand `uvm_object_utils` registration and the constructor convention.
- Write and simulate your first `uvm_object`-derived class.

## Theory Explanation

### Why does UVM exist on top of plain SystemVerilog classes?
Plain SV classes give you OOP, but in a verification environment you constantly need
to: print an object's fields for debugging, deep-copy it, compare two objects field
by field, and substitute one class for another at run-time without editing the
testbench (the **factory pattern**). Writing all of that by hand for every data class
is repetitive and error-prone. `uvm_object` is UVM's base class that provides this
infrastructure, and the **field macros** (Chapter 3) let you opt fields into it with
one line each instead of writing `print()`/`copy()`/`compare()` by hand.

### `uvm_object` vs `uvm_component`
- `uvm_object`: lightweight, **transient** data — e.g. a packet/transaction. Created
  and destroyed constantly during a test. No hierarchical position in the testbench.
- `uvm_component` (seen briefly in Chapter 6): persistent, **structural** building
  block — e.g. driver, monitor, scoreboard. Lives for the whole simulation and sits
  in a parent/child hierarchy.

This document's examples are about `uvm_object`, the data-class side of UVM.

### The UVM Factory (conceptually)
Think of the factory as a "type registry + override table." Instead of writing
`my_class obj = new();` everywhere, UVM code writes
`my_class obj = my_class::type_id::create("obj");`. Because creation goes through the
factory, you can later say "whenever someone asks for `my_class`, give them
`my_class_extended` instead" — **without changing a single line of existing
testbench code.** That's the whole point, covered fully in Chapter 6.

To participate in the factory at all, a class must be **registered**, which is what
`` `uvm_object_utils(class_name) `` does.

### Anatomy of a minimal `uvm_object`

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

class obj extends uvm_object;
  `uvm_object_utils(obj)              // (1) registers 'obj' with the factory

  function new(string path = "obj");  // (2) constructor — name defaults to "obj"
    super.new(path);                  // (3) MUST call parent constructor first
  endfunction

  rand bit [3:0] a;                   // (4) ordinary class member, randomizable
endclass
```

Line by line:
1. `` `uvm_object_utils(obj) `` — a macro that expands into boilerplate `type_id`,
   `get_type()`, `create()` methods so the factory knows about this class.
2. `function new(string path = "obj")` — by convention every `uvm_object` constructor
   takes a `string` name argument (used for messages/printing), with a sensible default.
3. `super.new(path)` — passes the name up to `uvm_object`'s own constructor, which
   stores it internally (`get_name()` later returns it).
4. A plain `rand` field — `uvm_object` doesn't auto-discover this field; it only
   becomes "factory-aware" for printing/copying once you add field macros (Ch. 3).

## Architecture Diagram
```
        uvm_object  (UVM base class: name, print, copy, compare, clone...)
              ▲
              │  extends
              │
            obj   (your class, registered via `uvm_object_utils)
              │
        instantiated either:
          - directly:  o = new("obj");          (bypasses factory)
          - via factory: o = obj::type_id::create("obj");   (factory-aware, overridable)
```

## Code Example from Source (ex01)
See `source_code/ex01_basic_object_uvm_info.sv`.

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

class obj extends uvm_object;
  `uvm_object_utils(obj)

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
```

### Line-by-Line Explanation
- `` `include "uvm_macros.svh" `` / `import uvm_pkg::*;` — every UVM file needs both:
  the macros (back-tick `` ` `` prefixed) live in a separate header, the classes live
  in the package.
- `o = new("obj");` — here the object is constructed **directly**, not through the
  factory. This is legal (it's still a valid `uvm_object`), but it means the factory
  cannot override `obj` for a different type later. This is intentional in this first
  example to keep things simple before Chapter 6 introduces `create()`.
- `o.randomize()` — fills `a` with a random 4-bit value.
- `` `uvm_info("TB_TOP", $sformatf(...), UVM_NONE) `` — UVM's reporting macro
  (replacement for `$display`) that adds severity levels, ID tagging, and verbosity
  filtering. `UVM_NONE` means "always print regardless of verbosity setting."

## Common Errors and Debugging Tips
| Mistake | Symptom | Fix |
|---|---|---|
| Forgetting `` `include "uvm_macros.svh" `` | Compile error: macro not defined | Always include it before using any back-tick UVM macro |
| Forgetting `` `uvm_object_utils `` | `create()` fails, factory override silently does nothing | Register every UVM class |
| Using `new()` instead of `create()` in real testbenches | Factory overrides won't apply | Use `type_id::create()` once you reach Chapter 6 |

## Interview-Level Points
- *Q: What does `uvm_object` give you that a plain SV class doesn't?*
  A: Built-in `print`, `copy`, `clone`, `compare`, `pack/unpack`, and factory
  integration — without writing that code yourself.
- *Q: Difference between `uvm_object` and `uvm_component`?*
  A: Lifetime and hierarchy — components are structural & persistent, objects are
  transient data with no fixed hierarchy position.
- *Q: Why does the constructor take a `string name`?*
  A: UVM uses names for hierarchical reporting/debug (`get_full_name()`), and to
  identify instances in print/log output.

## Key Takeaways
- `uvm_object` is UVM's base class for transient data (packets/transactions).
- `` `uvm_object_utils `` registers a class with the factory — without it, no
  factory-based create/override is possible.
- The constructor pattern `function new(string path = "...") super.new(path);` is
  fixed UVM convention — memorize it.
