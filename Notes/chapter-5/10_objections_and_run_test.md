# Chapter 10 — Objections & `run_test()`

## Chapter Overview
Every `test::run_phase` in the source notes brackets its work with
`phase.raise_objection(this)` / `phase.drop_objection(this)`. This chapter
explains why, since without it the simulation would exit before doing
anything useful.

## Learning Objectives
- Explain why UVM's `run_phase` needs an explicit "stay alive" signal.
- Explain what happens if objections are never raised, or never dropped.
- Explain `run_test()`'s role as the single simulation entry point.

## Theory Explanation

### The problem objections solve
`run_phase` is a **task**, and many components can each have their own
`run_phase` running concurrently (driver, sequencer, monitor, scoreboard,
test...). By default, UVM's phasing engine would consider the `run_phase`
"complete" the instant *any* one of these tasks returns — which for most
components (like an idle driver's `forever` loop) never happens on its own.
Without a mechanism to say "wait, don't end yet, real work is still
happening," the simulation could end after only a few time units.

**Objections solve this**: any component can "raise an objection" to say "I
have unfinished work," and the phase will not officially end until *all*
raised objections are dropped again.

```systemverilog
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);   // "don't end run_phase yet"
  seq1.start(e.a.seqr);          // do the actual test work (may take real sim time)
  phase.drop_objection(this);    // "okay, I'm done, you can end run_phase now"
endtask
```

Because `seq1.start(...)` is a blocking task call, `drop_objection` is only
reached after the entire sequence (and therefore all its `body()` logic,
including every `finish_item`/`wait_for_item_done`) has completed.

### What happens if you get it wrong
| Mistake | Consequence |
|---|---|
| Never call `raise_objection` | `run_phase` may end almost immediately; sequence gets killed mid-flight |
| Call `raise_objection` but never `drop_objection` | Simulation hangs forever ("test never finishes") |
| Drop objection before the sequence actually finishes | Same as never raising it — premature termination |

### `run_test()` — the single entry point
```systemverilog
module ram_tb;
  initial begin
    run_test("test");
  end
endmodule
```
`run_test("test")` is a UVM built-in task that:
1. Looks up `"test"` in the factory.
2. Constructs it as the (single) top-level `uvm_component`.
3. Automatically drives it (and its entire child hierarchy) through every
   UVM phase in order (`build_phase → connect_phase → ... → run_phase →
   ... → report_phase`).
4. Ends the simulation once all objections across all phases are resolved
   and `report_phase` completes.

You never manually call `build_phase()`/`run_phase()` yourself — `run_test`
does that for the entire tree automatically.

## Architecture Diagram
```
   run_test("test")
        │
        ▼
  build_phase (all components, top-down)
        │
        ▼
  connect_phase (all components, bottom-up)
        │
        ▼
  run_phase (all components' run_phase tasks run concurrently)
   ┌───────────────────────────────────────────┐
   │ test::run_phase:                             │
   │   raise_objection ──┐                        │
   │   seq1.start(...)    │  phase stays "alive"    │
   │   drop_objection ───┘  while objection is up  │
   └───────────────────────────────────────────┘
        │  (once ALL objections across ALL run_phase tasks are dropped)
        ▼
  remaining phases → simulation ends
```

## Code Example from the Notes
```systemverilog
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  seq1.start(e.a.seqr);
  phase.drop_objection(this);
endtask
```

## Line-by-Line Code Explanation
- `phase.raise_objection(this)` — `this` identifies which component raised it (useful in debug reports showing "who's still objecting").
- `seq1.start(e.a.seqr);` — blocking call; execution pauses here until the entire sequence's `pre_body/body/post_body` completes.
- `phase.drop_objection(this)` — releases the hold, allowing `run_phase` to conclude once no other component still objects.

## Common Errors and Debugging Tips
- **"My test ends instantly with no output"** → almost always a missing `raise_objection`.
- **"My simulation never finishes / times out"** → almost always a missing or mismatched `drop_objection` (raised twice, dropped once, etc. — objections are counted, not boolean).
- **Raising an objection in a component whose parent never gets its own `run_phase` called** (rare, but possible with certain phase overrides) → objection appears to have no effect; check the actual phase hierarchy.
- **Typo in `run_test("Test")` vs. the registered class name `"test"`** → UVM_FATAL: "not found in factory" at time 0.

## Key Takeaways
- Objections are a counted, not boolean, mechanism to keep a phase alive while asynchronous/concurrent work is in progress.
- `raise_objection` and `drop_objection` must always be paired, and dropped only after the real work is truly finished.
- `run_test()` is UVM's single simulation entry point; it drives every phase for the entire component tree automatically.
