# Chapter 9 — Full Integrated Example, Debugging Guide & Interview Prep

## Chapter Overview
This closing chapter ties every previous chapter together into one integrated testbench
(the source material's final full multi-component drain-time example), then gives you a
consolidated debugging playbook and interview question bank spanning the whole repo.

## Learning Objectives
- Read a complete driver/monitor/env/test/top testbench and correctly predict its full
  timeline without running a simulator
- Diagnose the four classic UVM phasing bugs from symptoms alone
- Answer rapid-fire interview questions on phasing, objections, timeout, and drain time

## Theory Explanation — Reading the Full File
`source_code/07_drain_time_multi_component_full.sv` is the capstone file of this repo. It
combines:
- Testbench architecture (Chapter 1): `driver`, `monitor`, `env`, `test` hierarchy
- Construction phases (Chapter 3/4): `env.build_phase` creating `driver`/`monitor`
- Objections (Chapter 5) and multi-component synchronization (Chapter 6): `reset_phase`
  and `main_phase` on both `driver` and `monitor`
- A new phase, `post_main_phase`, appearing on both components with no delay/objection
  (just a log message) — proof the run-time schedule continues past `main_phase`
- Centralized drain time (Chapter 8): set once, in `test.end_of_elaboration_phase`, via
  `phase.find_by_name("main", 0)`

## Full Code (as given in source)
See `source_code/07_drain_time_multi_component_full.sv` for the complete, compilable
listing. The full worked timeline for this exact file is in Chapter 8's "Line-by-Line
Timeline Walkthrough" — reset ends at t=150, main ends (with drain) at t=450,
`post_main_phase` starts only after t=450.

## Common Errors and Debugging Tips — Consolidated Playbook

| Symptom | Likely Cause | Chapter |
|---|---|---|
| Simulation hangs forever, never reaches `report_phase` | An objection was raised but never dropped somewhere in the tree | 5 |
| A phase ends immediately with zero time elapsed, even though you expected delays | No component raised an objection in that phase at all | 5 |
| Simulation ends abruptly with `UVM_FATAL` around a suspicious round number of ns | Global timeout (`set_timeout`) was hit — go find the unbalanced objection it caught | 5, 7 |
| A phase seems to end later than any single component's delay would suggest | Correct behavior — phase end is gated by the *last* component to drop its objection | 6 |
| A phase ends even later than that, by a fixed extra amount | Drain time is set on that phase somewhere — search for `set_drain_time` | 8 |
| `build_phase` logic silently doesn't run / config lookups fail oddly | Missing `super.build_phase(phase)` | 0, 3 |
| `create()` returns the wrong type / factory override has no effect | Missing `` `uvm_component_utils(classname) `` on that class | 0, 1 |
| Component's log messages show the wrong / blank hierarchical name | Forgot `super.new(path, parent)` in the constructor, or forgot to pass `this` to `create()` | 1, 4 |

## Interview-Level Points — Rapid Fire

1. **List the 12 standard UVM phases in order, grouped by construction/run-time/cleanup.**
   (Chapter 2)
2. **Why are construction/cleanup phases `function` while run-time phases are `task`?**
   (Chapter 0/2 — only `task`s can consume simulation time.)
3. **What ends a run-time phase?** The combined objection count across all components
   reaching zero, plus any configured drain time. (Chapters 5, 8)
4. **What happens if two components in the same phase have different objection
   durations?** The phase waits for the slower one; it is *not* an average or the first
   to finish. (Chapter 6)
5. **Difference between `set_timeout` and drain time?** Timeout = global hard ceiling,
   fatal error if exceeded. Drain time = local, per-phase grace period, not an error.
   (Chapter 7 vs 8)
6. **How do you apply drain time to a phase from a different component than the one
   running it?** `phase.find_by_name("phase_name", 0)` then
   `.phase_done.set_drain_time(this, value)` — typically done once, centrally, from
   `test.end_of_elaboration_phase`. (Chapter 8)
7. **Why use the factory (`type_id::create`) instead of `new()`?** Enables type/instance
   overrides for verification reuse without touching env/test code. (Chapter 1)
8. **What's the very first line that should appear in almost every phase override you
   write (except `run_phase`/the run-time schedule phases, which usually don't call
   `super`)?** `super.<phase_name>(phase);` (Chapter 0/3)

## Key Takeaways
- Every phasing behavior in this repo reduces to three interacting rules: (1) phases run
  in a fixed global order, (2) run-time phases end only when all objections in that phase
  are dropped, and (3) drain time adds a fixed delay after that point.
- When debugging any "wrong timing" issue in a UVM testbench, always hand-trace: who
  raised, when, for how long, who dropped last, and is there any drain time configured.
- You now have every piece needed to build `projects/project1_phase_logger_testbench/`
  from scratch — go do that next.
