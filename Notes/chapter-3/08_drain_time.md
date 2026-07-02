# Chapter 8 — Drain Time

## Chapter Overview
Drain time is the most nuanced concept in this repo, and the source material spends the
most effort on it — including a fully worked timeline. This chapter covers both the
single-component syntax and the more realistic multi-component pattern where drain time
is set centrally from the `test`.

## Learning Objectives
- Define drain time precisely, and distinguish it from both objections (Chapter 5) and
  timeout (Chapter 7)
- Use `phase.phase_done.set_drain_time()` in a single component
- Use `phase.find_by_name()` + `set_drain_time()` to apply drain time to a *named* phase
  from a different component (typically `test`)
- Hand-compute a full timeline including drain time, replicating the source's summary

## Theory Explanation

### What problem does drain time solve?
Once every component has dropped its objections in a phase, UVM is technically free to
end that phase immediately. But real hardware/verification activity is often not fully
captured by objections — e.g. a response might still be propagating through a pipeline,
or a monitor might want to keep sampling for a few more cycles "just in case" without
holding a formal objection open the whole time. **Drain time is an additional, fixed
grace period UVM waits *after* the objection count reaches zero, before actually ending
the phase.**

### Syntax — single component
```systemverilog
phase.phase_done.set_drain_time(this, 50ns);
```
`phase.phase_done` is a `uvm_objection`-derived handle representing "is this phase's
objection count zero yet." `set_drain_time(this, value)` tells it: once that count hits
zero, wait an extra `value` before actually ending the phase.

### Syntax — applying drain time to a specific phase from elsewhere (e.g. from `test`)
```systemverilog
uvm_phase main_phase;
main_phase = phase.find_by_name("main", 0);
main_phase.phase_done.set_drain_time(this, 100);
```
`phase.find_by_name("main", 0)` looks up the live `uvm_phase` object for the phase named
`"main"` (the second argument, `0`, means "don't search recursively into sub-domains" —
just find the phase by its exact name in the current domain). This pattern is typically
used in `end_of_elaboration_phase` of the `test`, because by then the whole phase graph
exists and can be queried, but no run-time phase has started yet.

## Code Example From Source — Single Component
`source_code/06_drain_time_single_component.sv`
```systemverilog
task main_phase(uvm_phase phase);
  phase.phase_done.set_drain_time(this,200);
  phase.raise_objection(this);
  `uvm_info("mon", " Main Phase Started", UVM_NONE);
  #100;
  `uvm_info("mon", " Main Phase Ended", UVM_NONE);
  phase.drop_objection(this);
endtask
```
This applies a 200-time-unit drain to `main_phase`, for this component only, from within
its own `task`.

## Code Example From Source — Multi-Component, Set Centrally From `test`
`source_code/07_drain_time_multi_component_full.sv` — full listing (driver, monitor,
env, test with drain time, top module).

Key new piece, inside `test`:
```systemverilog
function void end_of_elaboration_phase(uvm_phase phase);
  uvm_phase main_phase;
  super.end_of_elaboration_phase(phase);
  main_phase = phase.find_by_name("main", 0);
  main_phase.phase_done.set_drain_time(this, 100);
endfunction
```
Here `driver` and `monitor` both still raise/drop objections in `reset_phase` and
`main_phase` as in Chapter 6, but neither of them sets a drain time locally — `test`
does it once, centrally, for the whole `main` phase.

Driver and monitor delays used in this example (as given in the source):
| Component | reset_phase delay | main_phase delay |
|---|---|---|
| driver | #100 | #100 |
| monitor | #150 | #200 |

## Line-by-Line Timeline Walkthrough (exactly matching the source's own summary)

**Reset Phase:**
- Driver: raise → `#100` → drop (finishes at t=100)
- Monitor: raise → `#150` → drop (finishes at t=150)
- Reset phase ends at **t=150** — UVM waits for **all** objections (Chapter 6's rule),
  and there is no drain time set on `reset_phase` in this example, so it ends exactly
  when the last objection drops.

**Main Phase (starts at t=150):**
- Driver: raise → `#100` → drop → finishes at **t=250**
- Monitor: raise → `#200` → drop → finishes at **t=350**
- Last objection in `main_phase` drops at **t=350**.

**Drain Time:**
```
main_phase.phase_done.set_drain_time(this, 100);
```
This tells UVM: *"after the last objection in `main_phase` is dropped, wait 100 more
time units before actually ending the phase."*
- Last objection dropped: t = 350
- Drain time: + 100
- **Main phase actually ends: t = 450**

**Post-Main Phase:**
Only after **t = 450** does UVM enter `post_main_phase()` on driver and monitor (both of
which, in this example, just print a "Started" message with no further delay/objection).

## Architecture / Timing Diagram
```
RESET PHASE                         MAIN PHASE                                  POST-MAIN
t: 0      100   150                 150        250        350    350+100=450    450
   │       │     │                   │          │          │      │             │
drv├raise──┼drop─┤                   ├─raise────┼──drop────┤      │             │
mon├raise──┼─────┼──drop─────────────┤          ├──raise───┼─────drop           │
                  ▲                                          ▲      ▲            ▲
        reset ends (waits for mon)          objections=0 at 350   drain +100   post_main
                                                                  ends 450      starts
```

## Common Errors and Debugging Tips
- **Confusing drain time with an objection** — drain time only starts counting *after*
  objections hit zero; it is not itself something you raise/drop, and it cannot keep a
  phase open if objections never reach zero in the first place.
- **Setting drain time inside a phase that already ended** — `find_by_name` must be
  called on a phase that still exists in the phase graph and hasn't completed yet;
  calling this logic too late (e.g. inside `main_phase` itself, after time has already
  passed the phase's natural end) can miss the window. The source's pattern — setting it
  in `end_of_elaboration_phase`, long before `main_phase` even starts — is deliberately
  safe.
- **Forgetting the second argument to `find_by_name`** — `find_by_name(name, stay_in_scope)`
  requires both arguments in most UVM versions; passing just the name is a common typo
  that leads to a compile error.
- **Setting drain time redundantly in multiple components for the same phase** — the
  last value set generally wins (implementation-specific); prefer setting it centrally
  once (as in the `test` example) to avoid ambiguity.

## Interview-Level Points
- "What's the exact difference between drain time and an objection?" — an objection
  prevents a phase from being considered "ready to end" at all; drain time adds a fixed
  delay *after* the phase becomes ready to end (all objections at zero) but before it
  actually ends.
- "Why set drain time from `test.end_of_elaboration_phase` instead of inside each
  component's own `main_phase`?" — centralizes the policy in one place (the test, which
  is meant to configure environment-wide behavior) rather than duplicating/potentially
  conflicting drain-time values across every component.
- "If drain time is 100 and a *new* objection gets raised during the drain window, what
  happens?" — the drain timer resets/is cancelled and the phase reopens until objections
  reach zero again, after which the drain timer restarts. (Verify against your specific
  UVM version's LRM for exact semantics if this comes up in an interview — behavior here
  has evolved slightly across UVM releases.)

## Key Takeaways
- Drain time = extra wait *after* objections hit zero, before a phase actually ends.
- `phase.phase_done.set_drain_time(this, value)` — set locally, inside the phase you want
  to extend.
- `phase.find_by_name("main", 0)` — look up any phase by name, typically used from
  `test.end_of_elaboration_phase` to set drain time centrally before run-time even
  starts.
- Always hand-trace the timeline (raise/drop times → last drop → + drain) when debugging
  "why does my phase end later than I expect."
