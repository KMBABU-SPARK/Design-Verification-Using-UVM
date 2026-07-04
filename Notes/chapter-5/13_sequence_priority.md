# Chapter 13 — Sequence Priority

## Chapter Overview
Chapter 12 mentioned the `priority` argument to `.start()` without fully
explaining it. This short chapter isolates that concept using the notes'
dedicated "priority method" example.

## Learning Objectives
- Explain what the `priority` argument to `seq.start()` controls.
- Predict which sequence wins under `STRICT_FIFO` when priorities differ.
- Know the full signature of `uvm_sequence_base::start()`.

## Theory Explanation

### The `start()` method signature
```systemverilog
function void start(uvm_sequencer_base sequencer,
                     uvm_sequence_base parent_sequence = null,
                     int this_priority = 100,
                     bit call_pre_post = 1);
```
| Argument | Meaning |
|---|---|
| `sequencer` | which sequencer to run on |
| `parent_sequence` | `null` for a top-level sequence, or a handle if this is a sub-sequence |
| `this_priority` | the priority value used by weighted/strict arbitration modes (default 100) |
| `call_pre_post` | whether `pre_body()`/`post_body()` should run (Chapter 7) — defaults on, but is automatically skipped for sub-sequences regardless |

### Priority in practice
> "Each sequence can be assigned a priority. Higher-priority sequences are
> selected before lower-priority sequences (depending on arbitration mode).
> Example: Seq1 Priority = 200, Seq2 Priority = 100 → Seq1 gets preference
> over Seq2."

## Architecture Diagram
```
       arbitration mode = SEQ_ARB_STRICT_FIFO
   ┌───────────────────────────────────────────┐
   │ s1.start(seq, null, 100)   priority = 100     │
   │ s2.start(seq, null, 200)   priority = 200     │
   └───────────────────────────────────────────┘
                       │
                       ▼
        s2 (higher priority) wins ALL its
        transactions granted first, then s1
```

## Code Example from the Notes
```systemverilog
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_FIFO);
  fork
    s1.start(e.a.seq, null, 100);
    s2.start(e.a.seq, null, 200);
  join
  phase.drop_objection(this);
endtask
```
This matches the notes' explicit conclusion: with `STRICT_FIFO` and s2's
priority (200) higher than s1's (100), **s2 gets priority** and all of its
transactions are serviced before s1's.

## Line-by-Line Code Explanation
- `e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_FIFO);` — must be set **before** `fork`/`start`, since arbitration decisions happen the moment requests arrive.
- `s1.start(e.a.seq, null, 100);` — priority 100.
- `s2.start(e.a.seq, null, 200);` — priority 200, strictly higher, so under `STRICT_FIFO` it wins every grant decision while it still has pending items.

## Common Errors and Debugging Tips
- **Using `SEQ_ARB_FIFO` or `SEQ_ARB_RANDOM` and expecting priority to matter** → these two modes ignore priority entirely (Chapter 12); switch to `WEIGHTED`/`STRICT_FIFO`/`STRICT_RANDOM`.
- **Assigning the same priority to two sequences and expecting a deterministic winner under `STRICT_FIFO`** → ties are broken by arrival order (FIFO), not by any other implicit rule.
- **Confusing "priority" with "arbitration mode"** → priority is a per-sequence numeric value; arbitration mode is the sequencer-wide algorithm that decides *how* to use that value (or ignore it).

## Key Takeaways
- `priority` is the third argument to `.start()`, defaulting to 100.
- Priority only affects scheduling under `WEIGHTED`, `STRICT_FIFO`, and `STRICT_RANDOM` — it's meaningless under `FIFO`/`RANDOM`.
- Higher numeric priority wins under strict modes; ties fall back to FIFO or random selection depending on which strict mode is active.
