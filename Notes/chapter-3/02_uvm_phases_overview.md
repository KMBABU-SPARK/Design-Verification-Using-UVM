# Chapter 2 — UVM Phasing: What It Is and Why It Exists

## Chapter Overview
This is the core concept of the entire repository. Every other chapter is either a
prerequisite for this one or a deep dive into one piece of it. Get this chapter right
and everything downstream (objections, timeout, drain time) becomes obvious instead of
memorized.

## Learning Objectives
- Define "phase" in the UVM sense
- Explain why a fixed, predictable phase order is necessary in verification
- Recite the standard phase list in order and classify each as construction, run-time,
  or cleanup
- Know which phases are `function`-based and which are `task`-based

## Theory Explanation

### What problem does phasing solve?
Imagine dozens of components — drivers, monitors, scoreboards, agents — all needing to:
build their sub-components, connect TLM ports to each other, check that configuration is
consistent, run stimulus, and finally check results and report a pass/fail. If every
component did this on its own schedule, you'd get race conditions: a monitor could start
sampling before the driver it's connected to even exists.

**UVM Phasing is a fixed, globally synchronized sequence of callback methods.** UVM
calls the same-named method (e.g. `build_phase`) on *every* component in the tree before
moving on to the next phase (e.g. `connect_phase`) on *every* component. This guarantees,
for example, that **all** components finish `build_phase` (and therefore exist) before
**any** component's `connect_phase` runs — so wiring ports together is always safe.

### The Phase List
UVM phases fall into three groups. This mirrors the diagram in the source material.

| Group | Phase | Type | Purpose |
|---|---|---|---|
| **Construction** | `build_phase` | function | Create child components via the factory |
| | `connect_phase` | function | Connect TLM ports/exports between components |
| | `end_of_elaboration_phase` | function | Final tweaks after the full hierarchy exists |
| | `start_of_simulation_phase` | function | Last chance to act just before time starts moving |
| **Run-Time** | `reset_phase` | task | DUT reset sequences |
| | `configure_phase` | task | Apply DUT/env configuration |
| | `main_phase` | task | Primary stimulus generation and checking |
| | `shutdown_phase` | task | Wind down outstanding activity |
| *(the four above are UVM's default "run-time schedule" — collectively also reachable as one umbrella `run_phase`)* | `run_phase` | task | Umbrella task phase — runs in parallel with reset/configure/main/shutdown |
| **Cleanup** | `extract_phase` | function | Pull final data out of scoreboards/components |
| | `check_phase` | function | Perform final correctness checks |
| | `report_phase` | function | Print pass/fail summary |
| | `final_phase` | function | Absolute last cleanup, no simulation activity |

> The source PDF's diagram groups these into exactly this three-tier structure:
> **Construction Phases → Main (run-time) Phases → Cleanup Phases** — matching the
> three code blocks it shows in sequence.

### Why `function` vs `task` matters here (ties back to Chapter 0)
Construction and Cleanup phases are all `function` — they happen in **zero simulation
time**, back-to-back, with a hard guarantee of ordering across the whole tree. Run-Time
phases are `task` — they **consume simulation time** and, critically, **run in parallel
across all components** rather than waiting for each component one at a time. That
parallelism is exactly what makes Chapter 5 (objections) necessary: if run-time phases
for different components can finish at different simulated times, something has to tell
UVM when the *phase itself* (not just one component) is actually done.

## Architecture Diagram — Full Phase Flow

```
 CONSTRUCTION (function, zero-time, strictly sequential across the tree)
 ┌───────────┐  ┌─────────────┐  ┌───────────────────────┐  ┌─────────────────────────┐
    build     ─▶  connect      ─▶  end_of_elaboration    ─▶  start_of_simulation    
 └───────────┘  └─────────────┘  └───────────────────────┘  └─────────────────────────┘
                                                                        │
                                                                        ▼
 RUN-TIME (task, consumes sim time, runs in parallel per component)
 ┌───────────┐  ┌─────────────┐  ┌───────────┐  ┌────────────┐
    reset     ─▶  configure   ─▶  main       ─▶  shutdown      (all wrapped by run_phase)
 └───────────┘  └─────────────┘  └───────────┘  └────────────┘
                                                                        │
                                                                        ▼
 CLEANUP (function, zero-time, strictly sequential across the tree)
 ┌───────────┐  ┌───────────┐  ┌────────────┐  ┌───────────┐
    extract   ─▶   check    ─▶   report     ─▶  final     
 └───────────┘  └───────────┘  └────────────┘  └───────────┘
```

## Code Example From Source
The source material overrides every one of these phases in a single component to prove
the flow, using `` `uvm_info `` to print when each fires — see
`source_code/01_all_phases_override.sv`.

## Common Mistakes
- Assuming phases run "per component, start to finish" — they don't. UVM runs
  `build_phase` on **every** component before **any** component's `connect_phase` starts.
- Trying to add a `#delay` inside a construction/cleanup `function` phase — illegal.
- Confusing `run_phase` with `main_phase` — `run_phase` is the umbrella task; `main_phase`
  is one of four sub-phases UVM runs inside it by default.

## Interview-Level Points
- "Why is phasing 'domain-based' instead of just calling methods in `initial` blocks?" —
  it guarantees hierarchy-wide ordering guarantees (all `build` before any `connect`,
  etc.) that manual `initial` blocks cannot give you across dozens of independently
  written components.
- "Which phases can consume simulation time?" — only the run-time schedule
  (`reset_phase` through `shutdown_phase`, and `run_phase` itself); everything else is a
  zero-time `function`.

## Key Takeaways
- A phase is a globally synchronized callback executed on every component in the tree.
- Three groups: Construction (function) → Run-Time (task) → Cleanup (function).
- Run-time phases run in parallel across components — this is why objections (Chapter 5)
  exist at all.
