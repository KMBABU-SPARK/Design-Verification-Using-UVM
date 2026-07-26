# Project 1 — Phase Logger Testbench

## Goal
Build a small UVM testbench, from scratch, that proves you understand every concept in
this repo — without looking at the notes. Then compare your version against the provided
solution files in this folder.

## Requirements
1. Create `driver`, `monitor`, `env`, `test` classes with the standard hierarchy
   (`test → env → {driver, monitor}`), using the factory correctly throughout.
2. In `driver`, override `reset_phase` and `main_phase` as time-consuming tasks (pick
   your own delays, e.g. `#50` and `#80`), each properly bracketed with
   `raise_objection`/`drop_objection` and an `` `uvm_info `` message at start and end.
3. In `monitor`, do the same, but pick **different** delays than `driver` so you can
   observe the "phase waits for the slowest component" rule.
4. In `test`, set a **centralized drain time of 75 time units** on `main_phase`, using
   `phase.find_by_name("main", 0)` inside `end_of_elaboration_phase` — do not set it
   locally inside `driver` or `monitor`.
5. In the top module, set a **global timeout of 2000ns** with `uvm_top.set_timeout()`
   before calling `run_test("test")`.
6. Before running, hand-write the expected timeline (reset end time, main phase
   objections-zero time, main phase actual end time including drain, when
   `post_main_phase`/next phase would start) — exactly like the worked examples in
   `notes/06_run_time_phases_multi_component.md` and `notes/08_drain_time.md`.
7. Compare your hand-written prediction against the actual simulated log order once you
   run it (any simulator with UVM support — Questa, VCS, Xcelium, or a free/open
   alternative).

## Files to Create
- `driver.sv`
- `monitor.sv`
- `env.sv`
- `test.sv`
- `tb_top.sv`

## Self-Check Questions (answer before looking at the solution)
1. What time does `reset_phase` end, and why?
2. What time do main-phase objections all reach zero?
3. What time does `main_phase` actually end, once drain time is included?
4. If you had set the drain time locally inside `monitor` instead of centrally from
   `test`, would the outcome differ? Why or why not?
5. What would happen to your testbench if you deleted the `drop_objection` call inside
   `monitor.main_phase`? Would your 2000ns timeout catch it, and what would the log show
   right before the `UVM_FATAL`?

## Solution
A worked solution is provided in the sibling `.sv` files in this same directory — write
your own version first, then diff.
