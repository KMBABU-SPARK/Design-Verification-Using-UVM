# Chapter 4 — The `env` `build_phase` Pattern

## Chapter Overview
This chapter covers the single most repeated pattern in all of UVM: a container
component (`env`) using its own `build_phase` to construct its children via the factory.
This is the "Format for using connect_phase" example from the source material (the
example itself is really about `build_phase`; `connect_phase` is mentioned because it's
the very next phase where you would wire the children's ports together, though this
particular snippet doesn't yet do any wiring).

## Learning Objectives
- Write an `env` class that owns `driver` and `monitor` handles
- Correctly declare and construct child components inside `build_phase`
- Explain why this must happen in `build_phase` and not in `new()` or `connect_phase`

## Theory Explanation
A `uvm_env` is just a container `uvm_component`. Its job is to own handles to the actual
functional components (drivers, monitors, scoreboards, agents) and instantiate them.
Declaring the handle and constructing the object are two separate steps, same as any
SystemVerilog class:

```systemverilog
driver d;   // declare handle (class-scope, happens at elaboration, not yet an object)
...
d = driver::type_id::create("d", this);   // construct the object (inside build_phase)
```

**Why must construction happen in `build_phase` and not in `new()`?** Two reasons:
1. Factory overrides (Chapter 1) are only guaranteed to be registered and resolvable
   once elaboration begins — using `create()` inside `build_phase` is the point in the
   flow UVM designed for this.
2. `build_phase` runs top-down through the whole tree in a controlled sequence
   (Chapter 2) — this guarantees `env`'s children exist by the time `connect_phase` runs
   for any component, letting you safely wire ports in `connect_phase` immediately after.

## Code Example From Source
`source_code/02_env_build_phase.sv`

```systemverilog
class env extends uvm_env;
  `uvm_component_utils(env)

  driver d;
  monitor m;

  function new(string path = "env", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d = driver::type_id::create("d", this);
    m = monitor::type_id::create("m", this);
  endfunction
endclass
```

## Line-by-Line Code Explanation
- `class env extends uvm_env;` — inherits the full `uvm_component` phase machinery
  through `uvm_env`.
- `` `uvm_component_utils(env) `` — registers `env` with the factory (Chapter 0/1);
  required for `env::type_id::create()` to work when `test` builds this env.
- `driver d; monitor m;` — handle declarations only; both are `null` until constructed.
- `function new(...)` — standard UVM component constructor boilerplate; **always**
  forwards `path` (instance name) and `parent` to `super.new()`.
- `d = driver::type_id::create("d", this);` — constructs the driver as a factory object,
  names it `"d"`, and sets `this` (the env) as its parent, wiring it into the hierarchy.
- Same pattern repeated for `monitor`.

## Architecture Diagram
```
env::build_phase()
  │
  ├── d = driver::type_id::create("d", this)  ──▶  new "driver" child under env
  │
  └── m = monitor::type_id::create("m", this) ──▶  new "monitor" child under env

Resulting tree:
   env
    ├── d  (driver)
    └── m  (monitor)
```

## Common Errors and Debugging Tips
- **Constructing children in `new()` instead of `build_phase`** — this is a classic
  anti-pattern; it bypasses factory override resolution and can break if any test tries
  to override `driver` with a derived type.
- **Forgetting the constructor boilerplate** (`function new` + `super.new(path, parent)`)
  — without it, the default constructor won't correctly propagate the instance name and
  parent, breaking the tree and log messages like `get_full_name()`.
- **Typo in the instance-name string vs the variable name** (e.g.
  `create("driver", this)` assigned to a handle named `d`) — not an error, but makes
  waveform/log navigation confusing since the name in the hierarchy won't match your
  variable name. Convention: keep them consistent (`d` ↔ `"d"`).

## Interview-Level Points
- "Why not just say `d = new("d", this)`?" — bypasses the factory, so `set_type_override`
  / `set_inst_override` calls in your test will have no effect on this component.
- "What phase would you wire `d`'s output port to `m`'s input port in?" —
  `connect_phase`, immediately after `build_phase`, precisely because `build_phase` is
  guaranteed complete for the whole tree by then.

## Key Takeaways
- Container components (`env`) declare child handles as class properties, then construct
  them with `type_id::create("name", this)` inside `build_phase`.
- Always write the constructor boilerplate (`function new` + `super.new`).
- This pattern is the backbone of every UVM environment you will ever write.
