# Chapter 5 — `uvm_sequence` Basics: `body()`, `pre_body()`, `post_body()`

## Chapter Overview
This chapter isolates the very first sequence example in the notes
("Topic-1"), which does nothing but print messages from three lifecycle
tasks — the perfect minimal example to learn sequence execution order before
any real stimulus is involved.

## Learning Objectives
- Explain what a `uvm_sequence` is and how it differs from a `uvm_sequence_item`.
- Name the three lifecycle tasks (`pre_body`, `body`, `post_body`) and their execution order.
- Explain what `T` in `uvm_sequence#(T)` means.

## Theory Explanation

### `uvm_sequence` vs `uvm_sequence_item`
A `uvm_sequence_item` (Chapter 3) is **one piece of data** (a transaction).
A `uvm_sequence` is **the generator/orchestrator** that creates one or more
transactions and sends them, in whatever order/pattern the test scenario
requires. Think of the item as a "letter" and the sequence as "the person
writing and mailing a series of letters."

```systemverilog
class sequence1 extends uvm_sequence#(transaction);
```
The parameter `transaction` tells `uvm_sequence` what type of item this
sequence will generate and send — it constrains and types the sequence's
internal request/response handling to that item type.

### The Lifecycle: `pre_body → body → post_body`
When you call `seq.start(sequencer)`, UVM internally calls these three tasks
**in this fixed order**, but only if the sequence was started directly (as
the "parent" — not as a sub-sequence called from inside another sequence's
`body()`; `pre_body`/`post_body` are skipped for sub-sequences).

```systemverilog
virtual task pre_body();
  `uvm_info("SEQ1", "PRE-BODY EXECUTED", UVM_NONE);
endtask

virtual task body();
  `uvm_info("SEQ1", "BODY EXECUTED", UVM_NONE);
endtask

virtual task post_body();
  `uvm_info("SEQ1", "POST-BODY EXECUTED", UVM_NONE);
endtask
```
- **`pre_body()`** — runs once before `body()`. Typically used for
  raising an objection if the sequence itself needs to guarantee the
  simulation stays alive (an alternative to raising it in the test).
- **`body()`** — the actual scenario: create item(s), randomize, send to
  driver. **This is the only mandatory task** — everything meaningful in
  later chapters happens here.
- **`post_body()`** — runs once after `body()` completes; typically used to
  drop the objection raised in `pre_body()`, or for cleanup/logging.

## Architecture Diagram
```
   test::run_phase
        │
        │ seq1.start(sequencer)
        ▼
 ┌─────────────────┐
 │   pre_body()    │  "PRE-BODY EXECUTED"
 └────────┬────────┘
          ▼
 ┌─────────────────┐
 │     body()      │  "BODY EXECUTED"   <-- your scenario logic lives here
 └────────┬────────┘
          ▼
 ┌─────────────────┐
 │   post_body()   │  "POST-BODY EXECUTED"
 └─────────────────┘
```

## Code Example from the Notes (Topic-1, full sequence class)
```systemverilog
class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1)

  function new(input string path = "sequence1");
    super.new(path);
  endfunction

  virtual task pre_body();
    `uvm_info("SEQ1", "PRE-BODY EXECUTED", UVM_NONE);
  endtask

  virtual task body();
    `uvm_info("SEQ1", "BODY EXECUTED", UVM_NONE);
  endtask

  virtual task post_body();
    `uvm_info("SEQ1", "POST-BODY EXECUTED", UVM_NONE);
  endtask
endclass
```

## Line-by-Line Code Explanation
1. `class sequence1 extends uvm_sequence#(transaction);` — this sequence will produce `transaction` items.
2. `` `uvm_object_utils(sequence1) `` — factory registration (Chapter 2); note **no field macros needed** here since a sequence has no data fields worth printing/copying.
3. Constructor — standard `uvm_object` pattern (name only, no parent).
4–6. `pre_body()` — logs a message; in this minimal example does nothing functionally important.
7–9. `body()` — logs a message; **in a real sequence this is where transactions get created and sent** .
10–12. `post_body()` — logs a message; mirror of `pre_body()`.

## Common Errors and Debugging Tips
- **Expecting `pre_body`/`post_body` to run for a sub-sequence** (started with `.start()` from inside another sequence's `body()`, with the `call_pre_post` argument left at its default) → they are intentionally skipped for sub-sequences to avoid nested objections; verify with `` `uvm_info `` prints if unsure.
- **Putting real stimulus logic in `pre_body()` instead of `body()`** → confuses the scenario's intent and often breaks reuse if this sequence is later called as a sub-sequence (where `pre_body`/`post_body` won't run).
- **Forgetting `virtual` on `task body()`** → base class polymorphism doesn't kick in correctly and your override may not be called as intended; always keep `virtual`.

## Key Takeaways
- A `uvm_sequence#(T)` generates and sends `T`-typed transactions; it is the "brain," while the item is the "letter."
- Execution order is always `pre_body → body → post_body` for a top-level (directly started) sequence.
- `body()` is the only task you are required to implement — it's where every real sequence in this repo does its actual work.
