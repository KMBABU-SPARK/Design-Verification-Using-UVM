# Chapter 7 — Simulation Timeout: `uvm_top.set_timeout()`

## Chapter Overview
A short but essential safety-net chapter, directly from the source's "Setting Time out"
section. This is the global insurance policy against the #1 bug from Chapter 5
(forgetting a `drop_objection`).

## Learning Objectives
- Explain what happens by default if no component ever drops its objections
- Use `uvm_top.set_timeout()` correctly
- Understand the "overridable" second argument

## Theory Explanation
As covered in Chapter 5, if any component raises an objection and never drops it, the
run-time phase's objection count never reaches zero, and — with no other safeguard — the
simulation would run **forever** (or until you hit a simulator-level default limit,
which varies by tool and is not something you should rely on). `uvm_top.set_timeout()`
lets you set a hard global ceiling: if the entire simulation is still running past this
time, UVM forcibly ends it and reports a `UVM_FATAL`.

`uvm_top` is UVM's implicit singleton root of the entire component tree (the invisible
parent above your top-level `test`) — `set_timeout()` is a method on it, so it applies
globally, not to a single component.

## Syntax
```systemverilog
uvm_top.set_timeout(100ns, 0);
```
- **Argument 1** — the timeout value (`100ns` here).
- **Argument 2** — `overridable` flag. `0` means this call takes priority even if another
  part of the code (or command-line plusarg) tries to change it later; `1` (default)
  means a later call can still override it.

## Code Example From Source
`source_code/05_set_timeout.sv`
```systemverilog
module tb;
  initial begin
    uvm_top.set_timeout(100ns, 0);
    run_test("comp");
  end
endmodule
```

## Line-by-Line Code Explanation
- `uvm_top.set_timeout(100ns, 0);` — must be called **before** `run_test()`, since the
  timeout needs to be in effect from t=0.
- `run_test("comp");` — starts phasing as usual; if total simulation time exceeds 100ns
  before all phases naturally complete, UVM issues a fatal error and stops.

## Common Errors and Debugging Tips
- **Calling `set_timeout()` after `run_test()`** — has no effect for that run; `run_test`
  is (in effect) a blocking call that only returns when simulation is already ending.
- **Relying on the default timeout instead of setting one explicitly** — UVM does have a
  built-in default (commonly 9200 seconds of simulation time in many implementations),
  but do not depend on tool-specific defaults; set it explicitly for predictable CI runs.
- **Using timeout as your primary correctness mechanism instead of fixing unbalanced
  objections** — treat this purely as a safety net for infra/CI (so a broken test fails
  fast instead of hanging a regression farm), not a substitute for correct
  raise/drop discipline.

## Interview-Level Points
- "What's the difference between `set_timeout` and drain time (next chapter)?" —
  `set_timeout` is a **global, hard ceiling** on the *entire* simulation, causing a fatal
  error if exceeded. Drain time is a **local, per-phase grace period** that intentionally
  extends a specific phase's natural end — not an error condition at all.
- "Where must `set_timeout` be called?" — before `run_test()`, typically as the very
  first statement in the top-level `initial` block.

## Key Takeaways
- `uvm_top.set_timeout(value, overridable)` sets a global simulation time ceiling.
- It's a safety net against unbalanced objections (Chapter 5), not a design feature.
- Always call it before `run_test()`.
