# Chapter 4: UVM Base Components
### uvm_component, uvm_driver, uvm_monitor, uvm_env

---

## Chapter Overview

UVM provides a set of ready-made base classes for each role in a
testbench. You extend these base classes to create your own components.
This chapter covers the three core component types introduced in the
document's code examples: `uvm_driver`, `uvm_monitor`, and `uvm_env`.

---

## Learning Objectives

After this chapter you will be able to:
- Explain what `uvm_component` is and what it provides
- Write a minimal driver class that extends `uvm_driver`
- Write a minimal monitor class that extends `uvm_monitor`
- Write an environment class that contains and instantiates both
- Explain the parent-child relationship in UVM components
- Use `this` correctly as a parent argument

---

## 4.1 `uvm_component` — The Base of All Components

### Theory

`uvm_component` is the abstract base class for everything in the UVM
hierarchy that has a persistent existence during simulation (as opposed
to transient objects like sequence items). It provides:

- A **name** and **parent** reference (builds the component tree)
- The **phasing** system (build, connect, run, check, report phases)
- The **reporting** system (`uvm_info`, `uvm_error`, etc.)
- Factory registration support

Every component you write will ultimately inherit from `uvm_component`,
either directly or through one of its specializations (uvm_driver,
uvm_monitor, uvm_env, etc.).

### Constructor Signature — Always the Same

Every `uvm_component`-derived class must have exactly this constructor:

```systemverilog
function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction
```

| Argument | Meaning |
|----------|---------|
| `name`   | String label for this instance (used in messages, hierarchy path) |
| `parent` | The UVM component that contains this one (null for top-level) |

---

## 4.2 `uvm_driver` — Driving Stimulus to the DUT

### Theory

The driver's job is to receive transactions (sequence items) from the
sequencer and translate them into pin-level signal activity on the DUT
interface. It is an active component — it drives signals.

### Anatomy

```systemverilog
class driver extends uvm_driver;

    // Step 1: Register with the factory
    `uvm_component_utils(driver)

    // Step 2: Standard constructor
    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction

    // Step 3: Implement the run task (simulation behaviour)
    task run();
        `uvm_info("DRV1", "Executed Driver1 Code", UVM_HIGH);
        `uvm_info("DRV2", "Executed Driver2 Code", UVM_HIGH);
    endtask

endclass
```

### Notes on the `run()` Task

In full UVM, the driver implements the UVM `run_phase(uvm_phase phase)`
task (not a plain `task run()`). The code in the document uses a
simplified `task run()` for teaching purposes. The correct UVM-phase
version is:

```systemverilog
task run_phase(uvm_phase phase);
    // drive DUT signals here
endtask
```

Both forms work; the phase-based form integrates with UVM's automatic
phase scheduling.

---

## 4.3 `uvm_monitor` — Observing DUT Output

### Theory

The monitor passively observes the DUT's output pins, converts the
pin-level activity back into transactions, and broadcasts those
transactions to other components (typically the scoreboard) via TLM
ports. It never drives signals.

```systemverilog
class monitor extends uvm_monitor;

    `uvm_component_utils(monitor)

    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction

    task run();
        `uvm_info("MON", "Executed Monitor Code", UVM_HIGH);
    endtask

endclass
```

### Driver vs Monitor — Side-by-Side

```
  DRIVER                         MONITOR
  ──────                         ───────
  Extends uvm_driver             Extends uvm_monitor
  Receives from sequencer        Observes DUT outputs
  DRIVES signals → DUT           READS signals ← DUT
  Active component               Passive component
  Creates stimulus               Creates transactions for checking
```

---

## 4.4 `uvm_env` — The Container Environment

### Theory

The environment (`uvm_env`) is a container class. It instantiates and
holds all the agents (which contain drivers and monitors), the
scoreboard, and any other components needed for the testbench. Think
of it as the "manager" that organizes all the verification components.

### Key Pattern: Instantiation Inside `run()` (simplified form)

The document uses a simplified pattern where components are instantiated
inside the `run()` task. In production UVM, instantiation happens in
`build_phase()`. Both patterns are shown below.

#### Simplified Pattern (from document)

```systemverilog
class env extends uvm_env;

    `uvm_component_utils(env)

    driver  drv;    // handles declared as class-level
    monitor mon;

    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction

    task run();
        drv = new("DRV", this);   // 'this' = env is the parent of drv
        mon = new("MON", this);   // 'this' = env is the parent of mon
        drv.run();
        mon.run();
    endtask

endclass
```

#### Production Pattern (using build_phase)

```systemverilog
class env extends uvm_env;
    `uvm_component_utils(env)
    driver  drv;
    monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = driver::type_id::create("DRV", this);
        mon = monitor::type_id::create("MON", this);
    endfunction

    task run_phase(uvm_phase phase);
        // sequencer-driver connection, etc.
    endtask
endclass
```

---

## 4.5 The Parent-Child Relationship

### Theory

When you call `new("DRV", this)` inside the environment, you are saying:
"Create a driver object, name it 'DRV', and its parent is `this` (the env)."

This builds a **component tree** (hierarchy) in memory:

```
  null
   │
  env (name="ENV", parent=null)
   ├── driver  (name="DRV", parent=env)
   └── monitor (name="MON", parent=env)
```

This tree is what makes `set_report_verbosity_level_hier` work — UVM
walks the tree from the node you call it on, down to all children.

### Why Does the Parent Matter?

1. **Hierarchy paths in messages** — UVM prefixes messages with the
   full path (e.g., `uvm_test_top.env.DRV`), making it easy to know
   which component emitted each message.
2. **Hierarchical reporting** — `_hier` methods traverse this tree.
3. **Phase propagation** — UVM runs phases on all components in the
   tree automatically.

### `null` as Parent

The top-most component (usually the test or, in simplified examples,
the first object created in the module) has `null` as its parent. This
tells UVM "this is a root component; there is no parent above it."

```systemverilog
env e = new("ENV", null);   // null → e is at the root
```

---

## 4.6 Complete Environment Example (from document)

This is the full Example 3 from the document with complete annotation:

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

//─────────────────── DRIVER ───────────────────
class driver extends uvm_driver;
    `uvm_component_utils(driver)          // (1) factory registration

    function new(string path, uvm_component parent);
        super.new(path, parent);          // (2) init parent class
    endfunction

    task run();
        `uvm_info("DRV", "Executed Driver Code", UVM_HIGH); // (3)
    endtask
endclass

//─────────────────── MONITOR ───────────────────
class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)

    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction

    task run();
        `uvm_info("MON", "Executed Monitor Code", UVM_HIGH);
    endtask
endclass

//─────────────────── ENVIRONMENT ───────────────────
class env extends uvm_env;
    `uvm_component_utils(env)

    driver  drv;                          // (4) handles, not objects yet
    monitor mon;

    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction

    task run();
        drv = new("DRV", this);           // (5) create with env as parent
        mon = new("MON", this);
        drv.run();
        mon.run();
    endtask
endclass

//─────────────────── TESTBENCH TOP ───────────────────
module tb;
    env e;

    initial begin
        e = new("ENV", null);                        // (6) root object
        e.set_report_verbosity_level_hier(UVM_HIGH); // (7) propagate to drv+mon
        e.run();
    end
endmodule
```

| Label | Explanation |
|-------|-------------|
| (1) | Registers `driver` class with the UVM factory — covered in Chapter 5 |
| (2) | Calls parent (`uvm_driver`) constructor — mandatory |
| (3) | UVM_HIGH message — only prints if verbosity ≥ HIGH |
| (4) | Class-level handles declared; no objects exist yet |
| (5) | Objects created at runtime; `this` makes env the parent |
| (6) | env is root, parent = null |
| (7) | Raises verbosity for env, drv, and mon all at once |

---

## Common Errors and Debugging Tips

| Error | Cause | Fix |
|-------|-------|-----|
| `uvm_driver is not defined` | Missing `import uvm_pkg::*` | Add the import line |
| Constructor signature mismatch | Wrote `new(string name)` instead of `new(string name, uvm_component parent)` | Always use two-arg form |
| Messages not printing | Verbosity not set | Use `set_report_verbosity_level_hier` on parent |
| Null pointer on `drv.run()` | `drv = new(...)` not called before `drv.run()` | Ensure instantiation happens before use |
| `super.new()` not first | Compiler warning or runtime error | Move `super.new()` to be the first statement |

---

## Key Takeaways

- `uvm_driver`, `uvm_monitor`, and `uvm_env` are UVM-provided base classes you extend.
- Every component constructor signature is `new(string name, uvm_component parent)`.
- `super.new(name, parent)` must be the first call in any constructor.
- `this` passes the current object as the parent when creating children inside a component.
- `null` is the parent for root-level components.
- The parent-child tree is what enables hierarchical reporting and phase propagation.

---

## Interview Questions

1. What is the difference between `uvm_driver` and `uvm_monitor`?
2. What does `this` refer to when used as the parent argument inside `uvm_env`?
3. Why is the constructor signature always `new(string name, uvm_component parent)`?
4. What does passing `null` as the parent argument mean?
5. Why do we declare component handles at the class level rather than inside the `run()` task?
6. In production UVM, which phase should component instantiation happen in?
