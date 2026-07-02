# Chapter 1 — UVM Testbench Architecture (Prerequisite)

## Chapter Overview
Every phasing example in this repo uses four classes — `driver`, `monitor`, `env`,
`test` — and two mechanisms — the **factory** and `run_test()`. This chapter explains
what they are and why the hierarchy looks the way it does, before we ever touch a phase
callback.

## Learning Objectives
- Draw and explain the standard UVM component hierarchy
- Explain why components are created through the factory instead of `new()`
- Explain what `run_test()` does and why it's the only line in the top module

## Theory Explanation

### Why a component hierarchy?
A real verification environment has many pieces that must be created, connected, run,
and torn down **in a predictable order**, and that order must work the same way whether
you have 2 components or 200. UVM solves this with a **tree of components**, each
extending `uvm_component`, each with an automatically-managed parent/child relationship.
The phasing engine (Chapter 2) walks this tree automatically — you never manually call
`driver.build_phase()`; UVM does it for you, for every component in the tree, in
topological order.

### The standard hierarchy used throughout this repo

```
test
 └── env
      ├── driver
      └── monitor
```

- **driver** — extends `uvm_driver`; drives stimulus onto the DUT interface.
- **monitor** — extends `uvm_monitor`; passively observes DUT signals.
- **env** — extends `uvm_env`; a container that instantiates and wires together driver,
  monitor, and (in a fuller TB) scoreboard, agents, etc.
- **test** — extends `uvm_test`; the top of the tree, instantiates the env and configures
  the specific test scenario.

### The Factory
```systemverilog
d = driver::type_id::create("d", this);
```
Instead of `d = new("d", this)`, UVM components are built through `type_id::create()`.
This indirection is what lets you later **override** `driver` with `driver_error_inject`
for a single test, with zero changes to `env`'s code — the factory looks up which type
to actually build at elaboration time. `` `uvm_component_utils(driver) `` is what
registers `driver` with the factory so `create()` knows how to build it.

Arguments to `create()`: `(instance_name_string, parent_handle)`. The parent handle
(`this`) is what wires the component into the tree — this is how UVM knows `d` is a
child of `env`, and therefore should have its phases run as part of `env`'s subtree.

### `run_test()`
```systemverilog
module tb;
  initial begin
    run_test("test");
  end
endmodule
```
This single line is the entire top-level testbench module. `run_test("test")`:
1. Looks up `"test"` in the factory
2. Constructs the top-level test component (which, via its own `build_phase`, constructs
   everything beneath it)
3. Hands control to the **UVM phasing engine**, which then drives every phase, on every
   component in the tree, automatically, until the last phase (`final`) completes.

You never write `#delay` or explicit calls to `build_phase()`/`run_phase()` in the top
module — the phasing engine (next chapter) is the thing driving all of that.

## Architecture Diagram

```
                     run_test("test")
                            │
                            ▼
                   ┌─────────────────┐
                   │       test      │
                   └────────┬────────┘
                            │ build_phase() creates
                            ▼
                   ┌─────────────────┐
                   │        env      │
                   └────────┬────────┘
                 build_phase() creates both
                    ┌───────┴────────┐
                    ▼                ▼
            ┌───────────────┐ ┌───────────────┐
            │     driver    │ │    monitor    │
            └───────────────┘ └───────────────┘
```

## Common Mistakes
- Calling `new()` directly instead of `type_id::create()` — breaks factory overrides and
  is considered a serious style violation in real UVM codebases.
- Forgetting to pass `this` as the parent in `create()` — orphans the component from the
  tree, which breaks phasing, `get_full_name()`, and config_db lookups.
- Putting testbench logic directly in the `module tb` block instead of inside UVM
  components — defeats the entire purpose of using UVM.

## Interview-Level Points
- "Why factory instead of `new`?" — enables type overrides for verification reuse
  (e.g. swap in an error-injecting driver for one test) without touching the env/test
  hierarchy.
- "What does `run_test()` actually do under the hood?" — constructs the named top-level
  component via the factory, then starts the phasing engine which recursively executes
  each phase across the entire component tree.

## Key Takeaways
- The hierarchy `test → env → {driver, monitor}` is the backbone every later example
  builds on.
- `type_id::create("name", this)` = factory-based construction; always use it for UVM
  components.
- `run_test("test")` is the single entry point that hands control to UVM's phasing engine.
