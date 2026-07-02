# Chapter 0 — Prerequisites: SystemVerilog OOP You Need Before UVM

## Chapter Overview
Every UVM code snippet you will ever read leans on five SystemVerilog language features.
None of them are UVM-specific, but if you don't already have them cold, every later
chapter will feel like memorization instead of understanding. This chapter is here
because the source material used all five without explaining any of them.

## Learning Objectives
By the end of this chapter you can:
- Explain what a `class`, `extends`, and `super` do in SystemVerilog
- Explain the difference between a `function` and a `task`, and why UVM cares
- Read a `` `uvm_info `` macro call and a `` `uvm_component_utils `` macro call
- Explain what `#100;` does inside a `task`

## Theory Explanation

### 1. Classes and Inheritance
SystemVerilog classes work like classes in Java/C++/Python: they bundle data (properties)
and behavior (methods). UVM is a **class library** — `uvm_component`, `uvm_driver`,
`uvm_monitor`, `uvm_env`, `uvm_test` are all pre-written classes that ship with UVM. You
never edit them; you **extend** them.

```systemverilog
class driver extends uvm_driver;   // "driver" IS-A uvm_driver, plus whatever you add
  ...
endclass
```

`extends` gives your class every method and property `uvm_driver` already has (including,
critically, all the phase methods you'll override starting in Chapter 3).

### 2. `super` — Calling the Parent's Version
When you override a method (like `build_phase`) inside your class, SystemVerilog does
**not** automatically also run the parent class's version of that method. If the parent
class does important setup in that method (and UVM's base classes always do), you must
call it explicitly:

```systemverilog
function void build_phase(uvm_phase phase);
  super.build_phase(phase);   // run uvm_component's build_phase logic first
  // ... your code ...
endfunction
```

**Why this exists:** UVM's base-class `build_phase` does internal bookkeeping (e.g.
resolving configuration). Skip `super.build_phase(phase)` and that bookkeeping silently
never happens — one of the most common beginner bugs in all of UVM.

### 3. `function` vs `task` — the single most important distinction in this repo
| | `function` | `task` |
|---|---|---|
| Can consume simulation time? | **No** — must return in zero time | **Yes** — can contain `#delay`, `@(posedge clk)`, `wait`, etc. |
| Can call another `task`? | No | Yes |
| Used for | Structural/setup phases (`build`, `connect`) | Behavioral/run-time phases (`run`, `main`, `reset`) |

This is *why* `build_phase` is declared `function void build_phase(...)` but `run_phase`
is declared `task run_phase(...)` — it's not a stylistic choice, it's a language rule.
You cannot put a `#100;` delay inside a `function`-based phase; the compiler will not
allow it.

### 4. Macros: `` `uvm_info `` and `` `uvm_component_utils ``
Both start with a backtick (`` ` ``) — that means "text macro," expanded by the
preprocessor before compilation, exactly like `#define` in C.

```systemverilog
`uvm_info("test", "Build Phase Executed", UVM_NONE);
```
Arguments: **(1)** a string "ID" tag used for filtering/searching logs, **(2)** the
message, **(3)** a verbosity level (`UVM_NONE`, `UVM_LOW`, `UVM_MEDIUM`, `UVM_HIGH`,
`UVM_FULL` — lower is *more* likely to print). This is UVM's replacement for `$display`;
prefer it always because it's filterable, has severity levels, and is the standard.

```systemverilog
`uvm_component_utils(driver)
```
This registers the class `driver` with the **UVM factory** (Chapter 1). Without this
line, `type_id::create()` cannot construct the class, and it will not show up in
`uvm_component_utils`-based overrides or config lookups. Treat it as mandatory
boilerplate that goes right after every `class ... extends uvm_component` (or any
subtype) declaration.

### 5. Delays: `#100;`
Inside a `task`, `#100;` pauses that task for 100 time units (units defined by
`` `timescale ``, commonly 1ns). This is how the example code in this repo simulates
"work taking time" — e.g. a driver spending 100ns resetting the DUT.

## Common Mistakes
- Forgetting `super.build_phase(phase)` — silently breaks configuration resolution.
- Writing `function` when you meant `task` (or vice versa) — compile error the moment you
  add a delay to a `function`.
- Forgetting `` `uvm_component_utils(classname) `` — factory `create()` calls fail or
  silently construct the wrong type.
- Forgetting `` `include "uvm_macros.svh" `` and `import uvm_pkg::*;` at the top of the
  file — every macro and base class becomes "undeclared identifier."

## Interview-Level Points
- "Why does `build_phase` take a `uvm_phase phase` argument if it's a function that
  can't consume time?" — because the argument is used to call phase-control APIs like
  `phase.raise_objection()` (only meaningful in task phases) and because all phase
  callbacks share one signature by convention/interface (`uvm_phase phase`), even the
  ones that never call time-consuming APIs.
- "What happens if you forget `super.new()` in the constructor?" — `uvm_component`'s
  constructor sets the component's name and parent in the hierarchy; skip it and the
  component will not register correctly in the component tree.

## Key Takeaways
- UVM = SystemVerilog classes you extend, never edit.
- `super.<phase>(phase)` is not optional — always call it first.
- `function` phases = zero time, structural. `task` phases = can consume time, behavioral.
- `` `uvm_info `` and `` `uvm_component_utils `` are macros; memorize their argument order.
