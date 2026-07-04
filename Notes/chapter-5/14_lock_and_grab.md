# Chapter 14 — Holding the Sequencer: `lock()`/`unlock()` and `grab()`/`ungrab()`

## Chapter Overview
The final topic in the source notes: what if priority/arbitration isn't
enough, and a sequence needs **guaranteed, exclusive** access to the driver
for a stretch of transactions? This chapter covers the "Holding Sequencer"
concept and its two mechanisms.

## Learning Objectives
- Explain the difference between arbitration-based priority and exclusive access.
- Use `lock()`/`unlock()` for cooperative exclusive access.
- Use `grab()`/`ungrab()` for immediate, non-cooperative exclusive access.
- State precisely how `lock()` and `grab()` differ.

## Theory Explanation

### Why priority alone isn't always enough
Priority and arbitration modes (Chapters 12–13) influence *who is more
likely* to be granted next, but they still let arbitration run every single
time. Sometimes a sequence needs a stronger guarantee: "let me finish this
whole burst of transactions, uninterrupted, no matter what else is
requesting." That's what **locking** the sequencer provides.

### `lock()` / `unlock()` — cooperative exclusive access
```systemverilog
virtual task body();
  lock(m_sequencer);
  repeat(3) begin
    trans = transaction::type_id::create("trans");
    start_item(trans);
    assert(trans.randomize);
    finish_item(trans);
  end
  unlock(m_sequencer);
endtask
```
- `lock(m_sequencer)` requests exclusive access **through the normal
  arbitration mechanism** — it waits its turn like anyone else, but once
  granted, it holds the sequencer until `unlock()` is called.
- **"Whichever sequence gets first access will complete all its
  transactions first."**
- `m_sequencer` is a built-in handle every `uvm_sequence` automatically has,
  pointing to the sequencer it's running on — you don't declare it yourself.

### `grab()` / `ungrab()` — immediate exclusive access
```systemverilog
virtual task body();
  grab(m_sequencer);
  repeat(3) begin
    trans = transaction::type_id::create("trans");
    start_item(trans);
    assert(trans.randomize);
    finish_item(trans);
  end
  ungrab(m_sequencer);
endtask
```
- `grab()` **bypasses the arbitration queue entirely** and immediately takes
  control with the highest possible priority.
- Other sequences are blocked **instantly**, even mid-transaction-sequence,
  unlike `lock()` which waits its turn first.

### `lock()` vs `grab()` — the exact distinction (verbatim from the notes)
> "`lock()` requests exclusive access through the normal arbitration
> mechanism, while `grab()` bypasses the arbitration queue and gets the
> highest priority for exclusive access to the sequencer. Therefore,
> `grab()` is more immediate and aggressive than `lock()`."

### Example flows from the notes
**Lock** (Seq1 already in progress, Seq2 calls `lock()` and must still wait
its turn under normal arbitration):
```
Seq1-Tx1
Seq1-Tx2
Seq1-Tx3
Seq2-Tx1
Seq2-Tx2
Seq2-Tx3
```
**Grab** (Seq1 in progress, Seq1 calls `grab()` mid-stream and instantly cuts in):
```
Seq1-Tx1
Seq2-Tx1
Seq1 calls grab()
Seq1-Tx2
Seq1-Tx3
Seq2-Tx2
Seq2-Tx3
```

## Architecture Diagram
```
              lock()                              grab()
   ┌─────────────────────────┐      ┌─────────────────────────────┐
   │ join arbitration queue     │      │ SKIP arbitration queue          │
   │ wait for normal turn       │      │ seize sequencer IMMEDIATELY     │
   │ once granted: hold until    │      │ other sequences blocked         │
   │ unlock()                   │      │ instantly, mid-sequence          │
   └─────────────────────────┘      └─────────────────────────────┘
        cooperative                          aggressive / preemptive
```

## Code Examples from the Notes
```systemverilog
class sequence2 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence2)
  transaction trans;
  function new(input string inst = "seq2");
    super.new(inst);
  endfunction
  virtual task body();
    lock(m_sequencer);
    repeat(3) begin
      `uvm_info("SEQ2", "SEQ2 Started" , UVM_NONE);
      trans = transaction::type_id::create("trans");
      start_item(trans);
      assert(trans.randomize);
      finish_item(trans);
      `uvm_info("SEQ2", "SEQ2 Ended" , UVM_NONE);
    end
    unlock(m_sequencer);
  endtask
endclass
```

```systemverilog
class sequence2 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence2)
  transaction trans;
  function new(input string inst = "seq2");
    super.new(inst);
  endfunction
  virtual task body();
    grab(m_sequencer);
    repeat(3) begin
      `uvm_info("SEQ2", "SEQ2 Started" , UVM_NONE);
      trans = transaction::type_id::create("trans");
      start_item(trans);
      assert(trans.randomize);
      finish_item(trans);
      `uvm_info("SEQ2", "SEQ2 Ended" , UVM_NONE);
    end
    ungrab(m_sequencer);
  endtask
endclass
```

## Line-by-Line Code Explanation
- `lock(m_sequencer);` / `grab(m_sequencer);` — must be called on the sequencer handle the sequence is actually running on; `m_sequencer` is UVM's built-in reference to exactly that, set automatically when `.start()` runs.
- The `repeat(3)` body is identical to the high-level API pattern from Chapter 9 — the *only* difference introduced in this chapter is the surrounding `lock`/`unlock` or `grab`/`ungrab` pair.
- `unlock(m_sequencer);` / `ungrab(m_sequencer);` — **mandatory** release; without it the sequencer remains held for the rest of the simulation and every other sequence starves.

## Common Errors and Debugging Tips
- **Forgetting `unlock()`/`ungrab()`** → deadlocks the entire testbench; every other sequence waits forever for a lock that never releases. This is the single most dangerous mistake in this chapter.
- **Calling `grab()` when `lock()` would suffice** → unnecessarily starves other sequences instantly instead of letting them finish their current burst; reserve `grab()` for true emergencies (e.g., error injection that must happen *now*).
- **Nesting multiple `lock()`/`grab()` calls from different sequences without careful design** → can produce priority-inversion-like deadlocks if not planned; keep lock/grab regions short and always paired.
- **Calling `unlock()`/`ungrab()` on the wrong sequencer handle** → silently does nothing meaningful; always match the exact `m_sequencer` (or explicit sequencer handle) used in the corresponding lock/grab call.

## Key Takeaways
- `lock()` = wait your turn via normal arbitration, then hold exclusively until `unlock()`.
- `grab()` = seize control immediately, bypassing arbitration and preempting everyone else, until `ungrab()`.
- `grab()` is strictly more aggressive/immediate than `lock()`.
- Every `lock`/`grab` must be paired with its release call, or the testbench deadlocks — treat this like any other "acquire/release" resource pattern (mutex-like discipline).

---

**This concludes the core learning path.** Proceed to
`../projects/project1_ram_sequence_project.md` to apply everything from
Chapters 0–14 in one consolidated exercise.
