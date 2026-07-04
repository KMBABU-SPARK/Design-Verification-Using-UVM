# Chapter 10 — Sequence Arbitration

## Learning Objectives
- Name all six `UVM_SEQ_ARB_*` modes and describe each one's selection rule.
- Set a sequencer's arbitration mode with `set_arbitration()`.
- Predict, given a mode, which sequence's transactions will be granted first.

## Theory Explanation

### What arbitration is
> "When you have multiple sequences running on the same sequencer, the
> sequencer must decide which sequence gets to send the next transaction to
> the driver. This decision process is called **arbitration**."

The sequencer exposes `set_arbitration(mode)` to configure this behavior.

### The Six Modes
| Mode | Rule | Priority used? |
|---|---|---|
| `SEQ_ARB_FIFO` (**default**) | First Come First Serve — earliest requester serviced first | No |
| `SEQ_ARB_WEIGHTED` | Selection weighted by sequence priority | Yes |
| `SEQ_ARB_RANDOM` | Pure random selection among requesters | No |
| `SEQ_ARB_STRICT_FIFO` | Highest priority wins; ties broken by FIFO order | Yes |
| `SEQ_ARB_STRICT_RANDOM` | Highest priority wins; ties broken randomly | Yes |
| `SEQ_ARB_USER` | User overrides `user_priority_arbitration()` for a fully custom algorithm (e.g., round-robin, fair scheduling) | Custom |

Setting the mode:
```systemverilog
e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_FIFO);
```
If never called, the sequencer defaults to `SEQ_ARB_FIFO`.

### Worked Example from the Notes
```systemverilog
fork
  repeat(5) s2.start(e.a.seq, null, 100); // sequencer, parent sequence, priority, call_pre_post
  repeat(5) s1.start(e.a.seq, null, 100);
join
```
Both sequences here are started with **equal priority (100)**, repeated 5
times each. With `SEQ_ARB_STRICT_FIFO` set beforehand, the notes report:
> "It based on the weight given to sequence gives the priority and it allows
> all transactions of the sequence to finish first then it allows the second
> one — as here s2 gets the priority."

This demonstrates the FIFO tie-break rule of `STRICT_FIFO`: with equal
priority, whichever sequence's request arrived at the sequencer first (in
this run, `s2`, since it appears first inside the `fork` block and was
serviced first) completes **all** of its repeated transactions before the
other sequence gets any.

> **Important nuance**: `fork` does not guarantee textual order determines
> which process's first statement actually executes first in simulation —
> but in this specific worked example from the notes, `s2` was observed to
> win. Treat this as "arbitration decided a winner based on arrival order
> under STRICT_FIFO," not as "textual position in `fork` always wins."

## Architecture Diagram
```
                 Sequencer arbitration queue
        ┌───────────────────────────────────────┐
        │  request(s1, priority=100)            │
        │  request(s2, priority=100)            │
        └───────────────────────────────────────┘
                          │
             mode = SEQ_ARB_STRICT_FIFO
                          │
                          ▼
        Equal priority -> earliest arrival wins tie
                          │
                          ▼
        s2's 5 transactions all granted first,
        THEN s1's 5 transactions granted
```

## Code Example from the Notes
```systemverilog
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  //NOTE: IF NO ARBITRATION MENTIONED SO SEQ_ARB_FIFO IS DEFAULT
  //e.a.seq.set_arbitration(UVM_SEQ_ARB_WEIGHTED);
  //e.a.seq.set_arbitration(UVM_SEQ_ARB_RANDOM);
  //e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_FIFO);
  //e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_RANDOM);
  fork
    repeat(5) s2.start(e.a.seq, null, 100);
    repeat(5) s1.start(e.a.seq, null, 100);
  join
  phase.drop_objection(this);
endtask
```

## Line-by-Line Code Explanation
- The commented-out `set_arbitration(...)` lines show the four alternative modes a student is meant to try one at a time, observing different DUT-stimulus interleaving each time — an intentional hands-on experiment in the source material.
- `s2.start(e.a.seq, null, 100)` — the third argument, `100`, is the **priority** used by weighted/strict modes ; `null` means "no parent sequence" (this is a top-level sequence, not a sub-sequence).
- `repeat(5)` wraps each `.start()` call, so each sequence is *restarted* 5 times, each restart competing independently in arbitration.

## Common Errors and Debugging Tips
- **Assuming `SEQ_ARB_FIFO` respects priority** → it explicitly does not; priority is ignored in FIFO and RANDOM modes. Use `WEIGHTED`/`STRICT_FIFO`/`STRICT_RANDOM` if priority must matter.
- **Setting arbitration mode after sequences have already started requesting** → change may not apply retroactively to already-queued requests; set it before `fork`/`start`.
- **Confusing `WEIGHTED` (probabilistic bias) with `STRICT_FIFO`/`STRICT_RANDOM` (deterministic priority-first)** → `WEIGHTED` can still let a lower-priority sequence through occasionally; the STRICT modes never do while a higher-priority request is pending.
- **Forgetting `SEQ_ARB_USER` requires overriding `user_priority_arbitration()`** → simply setting the mode without implementing the method leaves you with undefined/default behavior.

## Key Takeaways
- Arbitration is the sequencer's algorithm for choosing among multiple pending sequence requests.
- `SEQ_ARB_FIFO` is the default and ignores priority entirely.
- `STRICT_FIFO`/`STRICT_RANDOM`/`WEIGHTED` all honor priority; `RANDOM`/`FIFO` do not.
- `SEQ_ARB_USER` is the escape hatch for fully custom scheduling algorithms.
