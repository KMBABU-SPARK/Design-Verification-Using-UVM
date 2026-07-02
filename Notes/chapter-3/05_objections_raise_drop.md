# Chapter 5 — Objections: `raise_objection` / `drop_objection`

## Chapter Overview
This is the concept that makes run-time phases (Chapter 2's "task" group) actually work
correctly with multiple components. It's the exact "3: use of phase raise and drop
objection" section from the source material.

## Learning Objectives
- Explain, precisely, why run-time phases would end prematurely without objections
- Write correct `raise_objection`/`drop_objection` bracketing around time-consuming work
- Explain what happens if an objection is raised but never dropped

## Theory Explanation

### Why does this exist?
Recall from Chapter 2: run-time phases (`reset_phase`, `main_phase`, etc.) are `task`s
that run **in parallel** across every component in the tree. UVM has to decide, for the
whole tree, when a given phase (say, `reset_phase`) is "done" and it's safe to move on to
the next one. But UVM has no idea, on its own, how long your `reset_phase` task body is
supposed to take — a `task` with no blocking statements would look "instantly done" to
the scheduler even if you intended it to model a 100ns reset pulse.

**The objection mechanism solves this**: a component explicitly tells UVM "don't end this
phase yet, I'm still working" (`raise_objection`) and later "okay, I'm done"
(`drop_objection`). UVM ends a run-time phase only once the **total objection count across
every component in that phase reaches zero** (plus any drain time — Chapter 8).

### Syntax
```systemverilog
task reset_phase(uvm_phase phase);
  phase.raise_objection(this);
  `uvm_info("comp","Reset Started", UVM_NONE);
  #10;
  `uvm_info("comp","Reset Completed", UVM_NONE);
  phase.drop_objection(this);
endtask
```
`this` is passed to both calls purely for **debug bookkeeping** — UVM's objection report
(`+UVM_OBJECTION_TRACE` or similar) can tell you exactly which component's objection is
still outstanding if the simulation seems to hang.

## Code Example From Source
`source_code/03_objection_reset_phase.sv`

```systemverilog
task reset_phase(uvm_phase phase);
  phase.raise_objection(this);
  `uvm_info("comp","Reset Started", UVM_NONE);
  #10;
  `uvm_info("comp","Reset Completed", UVM_NONE);
  phase.drop_objection(this);
endtask
```

## Line-by-Line Code Explanation
- `phase.raise_objection(this);` — increments the global objection count for
  `reset_phase`. UVM will **not** advance to the next phase while this count is > 0.
- `#10;` — models 10 time units of "work" (e.g. asserting a DUT reset line).
- `phase.drop_objection(this);` — decrements the objection count. Once **every**
  component's `reset_phase` objections reach zero, UVM proceeds to `configure_phase`.

## Architecture / Timing Diagram
```
t=0                                          t=10
 │                                              │
 ├── raise_objection(this)  [count: 0→1]        │
 │        "Reset Started"                       │
 │        ......... #10 .........               │
 │                                              ├── "Reset Completed"
 │                                              ├── drop_objection(this) [count: 1→0]
 │                                              │
 │                                              └──▶ phase ends, next phase begins
```

## Common Errors and Debugging Tips
- **Forgetting `drop_objection`** — the objection count never reaches zero, and the
  simulation **hangs forever** in that phase (unless a global timeout is set — Chapter 7).
  This is the single most common UVM beginner bug.
- **Raising an objection in a `function` phase** — meaningless/illegal in this context;
  objections are a run-time-phase concept tied to time-consuming `task`s.
- **Raising twice, dropping once** — leaves a phantom outstanding objection; always
  bracket exactly one `raise_objection` with exactly one `drop_objection` per logical
  unit of work (or track counts carefully if you must call either multiple times).
- **Only one component raises an objection, but you meant for the whole env to wait** —
  each component's objections are independent; if you need the *env* to hold the phase
  open, either raise the objection from within the env itself, or make sure the specific
  child components doing the time-consuming work are the ones raising it (Chapter 6 shows
  multiple components all raising objections in the same phase).

## Interview-Level Points
- "What ends a run-time phase in UVM?" — the total objection count for that phase across
  all components dropping to zero (plus any drain time).
- "What happens if no component ever raises an objection in `main_phase`?" — UVM
  considers the phase immediately complete (zero simulation time), which is a common
  cause of a testbench that "runs" but does nothing.
- "Difference between an objection and a semaphore/mutex?" — objections don't grant
  exclusive access to anything; they are a purely additive counter used only to delay
  phase-ending, not to serialize access to a resource.

## Key Takeaways
- `raise_objection` / `drop_objection` tell UVM's phasing engine when a run-time phase is
  actually finished, since parallel `task`s give UVM no other way to know.
- The phase ends only when the *combined* objection count across the whole tree hits
  zero.
- Unbalanced raise/drop calls are the #1 cause of "my simulation just hangs" bugs.
