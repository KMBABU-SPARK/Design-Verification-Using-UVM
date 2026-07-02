# Chapter 3 — Overriding Construction, Run, and Cleanup Phases

## Chapter Overview
Now that you know *what* the phases are (Chapter 2), this chapter shows the actual
syntax for overriding each one in a component, exactly as given in the source material's
first code block.

## Learning Objectives
- Write correct override syntax for every construction and cleanup phase
- Explain why `run_phase` alone (of this whole list) is a `task`
- Explain the role of `` `uvm_info `` calls as phase-tracing tools

## Theory Explanation
Overriding a phase is just standard OOP method overriding (Chapter 0): match the base
class's method name and signature exactly, call `super.<phase>(phase)` first (function
phases only — see note below), then add your own logic.

> **Note on `super` in `run_phase`:** `uvm_component::run_phase` is empty by default and
> is rarely, if ever, called via `super.run_phase(phase)` in practice, because
> `run_phase` is normally left as the umbrella and the actual work is put in
> `reset_phase`/`main_phase`/etc. (Chapter 6). The source example overrides `run_phase`
> directly with no `super` call, which is legal but less common in production code
> that uses the full run-time schedule.

## Code Example From Source
`source_code/01_all_phases_override.sv` — full file, reproduced here in the same order
as the source document: Construction Phases block, then Main (Run) Phase, then Cleanup
Phases block.

```systemverilog
// Construction Phases
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  `uvm_info("test","Build Phase Executed", UVM_NONE);
endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  `uvm_info("test","Connect Phase Executed", UVM_NONE);
endfunction

function void end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  `uvm_info("test","End of Elaboration Phase Executed", UVM_NONE);
endfunction

function void start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
  `uvm_info("test","Start of Simulation Phase Executed", UVM_NONE);
endfunction

// Main Phase
task run_phase(uvm_phase phase);
  `uvm_info("test", "Run Phase", UVM_NONE);
endtask

// Cleanup Phases
function void extract_phase(uvm_phase phase);
  super.extract_phase(phase);
  `uvm_info("test", "Extract Phase", UVM_NONE);
endfunction

function void check_phase(uvm_phase phase);
  super.check_phase(phase);
  `uvm_info("test", "Check Phase", UVM_NONE);
endfunction

function void report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info("test", "Report Phase", UVM_NONE);
endfunction

function void final_phase(uvm_phase phase);
  super.final_phase(phase);
  `uvm_info("test", "Final Phase", UVM_NONE);
endfunction
```

## Line-by-Line Code Explanation
- `function void build_phase(uvm_phase phase)` — signature must match `uvm_component`'s
  base declaration exactly (return type `void`, one `uvm_phase` argument).
- `super.build_phase(phase);` — always first line for construction/cleanup phase
  overrides; runs base-class bookkeeping (see Chapter 0).
- `` `uvm_info("test", "...", UVM_NONE); `` — logs a trace message at the lowest
  verbosity filter (`UVM_NONE` always prints, regardless of `+UVM_VERBOSITY` setting) —
  a deliberate choice here purely to make phase order visible in the log for learning
  purposes.
- `task run_phase(uvm_phase phase); ... endtask` — the only `task` in the list; no
  `super.run_phase(phase)` call, and it prints once with no delay, so it completes
  "instantly" in this bare example (in real testbenches you'd raise an objection here or
  use the reset/main/shutdown sub-phases instead — Chapters 5–6).

## Expected Log Order
Running this component (as the top-level test) produces, in this exact order:
```
Build Phase Executed
Connect Phase Executed
End of Elaboration Phase Executed
Start of Simulation Phase Executed
Run Phase
Extract Phase
Check Phase
Report Phase
Final Phase
```
This ordering is not a coincidence — it *is* the phase list from Chapter 2, and seeing it
in a log is the best way to internalize the flow.

## Common Errors and Debugging Tips
- **Missing `super.<phase>()` call** — no compile error, but subtle runtime bugs (e.g.
  `report_phase` summary counts wrong) because base-class logic never ran. Always add it
  as the very first line, out of habit.
- **Wrong signature** (e.g. missing the `uvm_phase phase` argument) — this does **not**
  override the base method; it silently becomes a brand-new method that UVM's phasing
  engine never calls. Your phase logic simply never runs and there's no error — always
  double check signatures against the UVM Class Reference (UCR) if output is missing.
- **Putting a `#delay` inside any `function` phase** — compile error ("static/automatic
  task/function required").

## Interview-Level Points
- "Why does UVM print `Run Phase` between `start_of_simulation_phase` and
  `extract_phase`, and not somewhere else?" — because `run_phase` is the run-time domain,
  which is deliberately sandwiched between construction (must be complete first) and
  cleanup (must happen only after all run-time activity ends).
- "If you forget the argument name and just use `(uvm_phase p)` instead of
  `(uvm_phase phase)`, does the override still work?" — yes; argument *names* don't need
  to match, only the type signature does. Convention uses `phase`, though.

## Key Takeaways
- Overriding a phase = standard method override + `super` call + your logic.
- All construction/cleanup phases are `function`; only run-time phases are `task`.
- `` `uvm_info(...,UVM_NONE) `` is a simple, reliable way to trace phase execution order
  while learning.
