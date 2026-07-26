# Project 1 — RAM/Adder Sequence-Driven Testbench (Capstone)

## Goal
Combine everything from Chapters 0–14 into one complete, working testbench,
then extend it beyond what the source notes covered.

## Part A — Rebuild the Baseline (Chapters 0–10)
Using `source_code/01_basic_sequence_driver/` through
`source_code/03_start_item_finish_item/` as reference:
1. Implement `adder_if` and a trivial combinational adder DUT (`y = a + b`).
2. Implement `transaction`, `sequence1`, `driver`, `agent`, `env`, `test`.
3. Wire the virtual interface through `uvm_config_db`.
4. Use the **high-level** `start_item`/`finish_item` API to send 10 random transactions.
5. Confirm in your simulation log that `a`, `b` values change every transaction and that the driver reports them correctly.

**Success criterion:** simulation runs to completion (no hang), and the log
shows 10 distinct `(a, b)` pairs on both SEQ and DRV sides.

## Part B — Add Parallel Sequences & Arbitration (Chapters 11–13)
1. Add a second sequence, `sequence2`, functionally identical but with a distinct `` `uvm_info `` tag.
2. Start both concurrently with `fork/join` on the same sequencer.
3. Run the same test four times, changing only the arbitration mode each
   run: `SEQ_ARB_FIFO` (default), `SEQ_ARB_RANDOM`, `SEQ_ARB_STRICT_FIFO`,
   `SEQ_ARB_STRICT_RANDOM`. Record the resulting interleaving of SEQ1/SEQ2
   log messages for each mode.
4. Repeat with unequal priorities (e.g., 100 vs. 200) under `STRICT_FIFO` and
   confirm the higher-priority sequence's transactions are serviced first.

**Success criterion:** you can explain, from your own log output (not just
this repo's theory), why each mode produced the interleaving it did.

## Part C — Exclusive Access (Chapter 14)
1. Implement a `lock()`/`unlock()` version of `sequence2` and observe that
   whichever sequence starts first completes entirely before the other,
   regardless of arbitration mode.
2. Implement a `grab()`/`ungrab()` version and observe that it preempts a
   sequence **mid-execution**, unlike `lock()`.
3. Deliberately forget an `unlock()` call, run the simulation, and observe
   the resulting deadlock/timeout — then fix it. This exercise builds the
   debugging instinct for one of the most dangerous bug classes in this
   chapter.

## Part D — Stretch Goals (beyond the source notes — for a complete DV skillset)
The original notes stop at sequence/driver/arbitration and never build a
monitor, scoreboard, or coverage model. A real testbench needs these. As a
stretch goal:
1. Add a `uvm_monitor` that samples `aif.a`, `aif.b`, `aif.y` and broadcasts
   a copy of the transaction via an analysis port.
2. Add a simple scoreboard that checks `y == a + b` for every observed
   transaction and reports pass/fail via `` `uvm_info ``/`` `uvm_error ``.
3. Add a `covergroup` sampling `a` and `b` to measure stimulus coverage.

These three additions turn this repo's driver/sequence-only testbench into
a complete, self-checking UVM environment — the natural "what's next"
after mastering this repository.

## Deliverables Checklist
- [ ] Part A simulation log
- [ ] Part B: four arbitration-mode logs + written explanation of each
- [ ] Part C: lock vs. grab logs + one deliberately-reproduced deadlock and its fix
- [ ] (Stretch) monitor + scoreboard + coverage additions
