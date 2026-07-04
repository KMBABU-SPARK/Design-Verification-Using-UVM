# Chapter 11 — Running Multiple Sequences in Parallel

## Chapter Overview
"Topic-4" ("multiple sequence in parallel") introduces a second sequence
class and starts both on the *same* sequencer concurrently using `fork/join`.
This is the gateway topic into arbitration (Chapter 12).

## Learning Objectives
- Start two independent sequences on the same sequencer at the same time.
- Explain what happens when two sequences compete for one sequencer/driver.
- Recognize this pattern as the setup that makes arbitration mode (Chapter 12) actually matter.

## Theory Explanation

### Why run sequences in parallel at all?
Real DUTs are often stimulated by more than one independent traffic pattern
at once (e.g., a "normal traffic" sequence plus an "error injection"
sequence, or two independent protocol layers). Starting sequences
concurrently on the same sequencer models this realistically.

### The mechanism: `fork ... join` (from Chapter 0)
```systemverilog
fork
  s2.start(e.a.seq);
  s1.start(e.a.seq);
join
```
Both `s1` and `s2` are independent `uvm_sequence` objects. `fork` starts
both `.start()` tasks as concurrent processes; `join` waits until **both**
have completed before continuing (here, before `drop_objection` runs).

### What actually happens on the sequencer
Even though `s1` and `s2` run "in parallel" from the testbench's point of
view, the **driver can only physically process one transaction at a time**
(it's a single `forever` loop calling `get_next_item` once per iteration).
So the sequencer must **decide, every time it has a free slot, which
sequence's pending item to grant next.** That decision process is exactly
**arbitration** — the subject of Chapter 12. Without understanding parallel
sequences first, arbitration modes would have nothing to arbitrate between.

## Architecture Diagram
```
        test::run_phase
              │
     ┌────────┴─────────┐
     │       fork          │
     ▼                    ▼
 s1.start(seq)        s2.start(seq)      <- both run concurrently
     │                    │
     └─────────┬──────────┘
               ▼
         uvm_sequencer            <- must arbitrate: whose item goes next?
               │
               ▼
            driver                <- processes exactly one item at a time
```

## Code Example from the Notes (Topic-4, key parts)
```systemverilog
class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1)
  transaction trans;
  function new(input string inst = "seq1");
    super.new(inst);
  endfunction
  virtual task body();
    trans = transaction::type_id::create("trans");
    `uvm_info("SEQ1", "SEQ1 Started" , UVM_NONE);
    start_item(trans);
    trans.randomize();
    finish_item(trans);
    `uvm_info("SEQ1", "SEQ1 Ended" , UVM_NONE);
  endtask
endclass

class sequence2 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence2)
  transaction trans;
  function new(input string inst = "seq2");
    super.new(inst);
  endfunction
  virtual task body();
    trans = transaction::type_id::create("trans");
    `uvm_info("SEQ2", "SEQ2 Started" , UVM_NONE);
    start_item(trans);
    trans.randomize();
    finish_item(trans);
    `uvm_info("SEQ2", "SEQ2 Ended" , UVM_NONE);
  endtask
endclass

// inside test:
sequence1 s1;
sequence2 s2;
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  fork
    s2.start(e.a.seq);
    s1.start(e.a.seq);
  join
  phase.drop_objection(this);
endtask
```

## Line-by-Line Code Explanation
- `sequence1`/`sequence2` are structurally identical apart from their `` `uvm_info `` tag strings — deliberately, so the *only* variable in this experiment is "which one wins arbitration," not "which one has different logic."
- `s1 = sequence1::type_id::create("s1");` / `s2 = sequence2::type_id::create("s2");` (in the test's `build_phase`, not shown above but present in the source) — both created before `run_phase` starts either.
- `fork ... join` — starts both `.start()` calls as concurrent UVM sequence processes on the *same* sequencer (`e.a.seq`).
- Order of `s2.start(...)` then `s1.start(...)` inside `fork` **does not** guarantee `s2` runs first — `fork` starts both essentially simultaneously; actual ordering is determined by the sequencer's arbitration mode (Chapter 12), not by textual order inside `fork`.

## Common Errors and Debugging Tips
- **Assuming `fork` order = execution order** → a very common beginner misconception; the sequencer's arbitration mode governs actual grant order, not the order written in the `fork` block.
- **Using `join_none` instead of `join`** → `drop_objection` would run before either sequence finishes, risking premature phase termination.
- **Two sequences accidentally sharing the same transaction handle** → if `trans` were declared once and shared (e.g., as a `static` or environment-level variable) instead of per-sequence, you'd get race conditions and corrupted stimulus; each sequence must own its own item handle (as done correctly here).
- **Forgetting both sequences must be created in `build_phase` (as `uvm_object`s, no parent)** before being started in `run_phase`.

## Key Takeaways
- `fork/join` lets multiple sequences run concurrently and target the same sequencer.
- The driver still processes one item at a time — parallel sequences create *contention*, which the sequencer must resolve.
- This chapter is the direct setup for Chapter 12 (Arbitration): without two competing sequences, arbitration modes have nothing to demonstrate.
