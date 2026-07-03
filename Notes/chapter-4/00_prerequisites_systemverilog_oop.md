# Chapter 0 — Prerequisites: SystemVerilog OOP for UVM

> **Why this chapter exists:** the source material jumps straight into UVM
> `uvm_component` classes, `virtual function`, `#()` parameterization, and
> `task`/`function` overriding. None of these are UVM-specific — they are
> plain SystemVerilog OOP. Without this chapter a beginner cannot read even
> the first code block of the original document. This chapter was **added**
> (not present in the source) as a required prerequisite.

## Chapter Overview
A fast, practical tour of the SystemVerilog class features that every UVM
class silently depends on: classes, constructors, inheritance, virtual
methods/polymorphism, and parameterized (generic) classes.

## Learning Objectives
- Write a SystemVerilog `class` with a constructor (`new`).
- Understand `extends`, `super.new()`, and method overriding.
- Explain why UVM marks almost every method `virtual`.
- Read and write parameterized classes, e.g. `uvm_blocking_put_port #(int)`.
- Distinguish `task` (can consume time / block) from `function` (cannot).

## Theory

**Class & constructor.** A SystemVerilog `class` bundles data (properties)
and behavior (methods). `new()` is the constructor, invoked as
`handle = new(args)`. Class variables are **handles** (references), not
values — `uvm_component c; c = new(...)` — so assignment copies a reference,
not the object.

**Inheritance (`extends`).** A class can extend a parent class, inheriting
its properties/methods. Every UVM component you write extends `uvm_component`
(directly or via `uvm_env`, `uvm_test`, etc., which themselves extend
`uvm_component`). The child's constructor **must** call `super.new(...)`
first, passing along whatever the parent's constructor needs.

**Virtual methods & polymorphism.** A method marked `virtual` can be
overridden by a subclass, and calling it through a *base-class handle* will
still run the *derived-class* version. UVM relies on this constantly: your
`build_phase`, `connect_phase`, `write()`, `put()` etc. are called by UVM
internals through base-class handles, but your overridden versions execute.
If you forget `virtual`, UVM (or your own code) may silently call the base
implementation instead of yours — a classic and hard-to-spot bug.

**Parameterized (generic) classes — `#()`.** A class can take a type or
value parameter, e.g. `class my_port #(type T = int)`. This lets one class
definition work for any data type. Every TLM port/export/imp in UVM is
generic: `uvm_blocking_put_port #(int)`, `uvm_blocking_put_port #(transaction)`,
`uvm_blocking_transport_port #(int, int)` (two type parameters: request and
response types).

**`task` vs `function`.** A `function` executes in zero simulation time and
cannot contain `#delay` or `@event` or blocking calls. A `task` *can* consume
time. This matters directly for TLM: `put()`/`get()` on **blocking** ports
are tasks (they may need to wait), while `write()` on an **analysis** port is
always a `function` (broadcast must be instantaneous/non-blocking).

## Where This Is Used in UVM
Literally everywhere: `uvm_component`, `uvm_object`, all TLM ports, all
phase methods, and every macro like `` `uvm_component_utils`` expand to
ordinary class/method definitions using exactly these features.

## Syntax Reference
```systemverilog
class derived extends base;
  function new(int x = 0);
    super.new(x);      // must be first statement
  endfunction
  virtual function void show(); ... endfunction   // overridable
endclass

class container #(type T = int);
  T value;
endclass
container #(int) c;   // instantiate with T = int
```

## Architecture Diagram (Text)
```
        base (parent)
          |  extends
          v
       derived (child)
          |
  handle of type 'base' -----> can point to a 'derived' object
          |
  base_handle.show()  --(virtual dispatch)--> derived::show() runs
```

## Code Example
See `source_code/00_prereq/oop_recap.sv` — a minimal runnable illustration
of inheritance, virtual dispatch, and a parameterized `container` class
(this file was written for this repository; it is not from the source PDF,
since the source document assumes this knowledge rather than teaching it).

## Line-by-Line Explanation
- `class derived extends base;` — declares inheritance.
- `super.new(x)` — must run before any use of `this` in the child constructor.
- `virtual function void show();` in both classes — enables polymorphism;
  removing `virtual` from `base::show()` would make `b.show()` always call
  `base::show()` even when `b` actually references a `derived` object.
- `container #(type T = int)` — generic class; `c_int = new()` binds `T=int`.

## Common Errors & Debugging Tips
- **Forgetting `super.new()`** → compile error or uninitialized parent state.
- **Forgetting `virtual`** on a method you intend to override → silent wrong
  behavior (base method runs instead of override) with no compile error.
- **Using a `function` where the body needs to block/wait** → compiler error
  ("`function` cannot have a non-blocking timing control" or similar);
  the fix is almost always to make it a `task`.
- **Confusing handle assignment with object copy**: `a = b;` makes `a` point
  to the same object as `b`; it does not clone `b`.

## Interview-Level Points
- Explain the difference between a `class` and a `module` in SystemVerilog.
- Why must UVM phase methods and TLM implementation methods be `virtual`?
- What happens if you call a non-virtual method through a base-class handle
  that references a derived object?
- Why are TLM ports implemented as parameterized classes instead of one
  class per data type?

## Key Takeaways
- UVM is "just" disciplined SystemVerilog OOP with a large pre-built class
  library and macros on top.
- `virtual` + inheritance = the mechanism that lets UVM call *your* code
  through its generic base-class handles.
- `#()` parameterization is why one `uvm_blocking_put_port` class works for
  `int`, `string`, or a custom `transaction` object.
