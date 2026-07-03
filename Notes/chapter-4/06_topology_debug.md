# Chapter 06 — Debugging Topology: `uvm_top.print_topology()`

> **Source alignment:** covers `uvm_top.print_topology()`, which appears in
> Examples 3 and 4 inside `end_of_elaboration_phase` without explanation.

## Chapter Overview
A single but essential debug tool for verifying your component hierarchy
and TLM connections actually got built the way you intended.

## Learning Objectives
- Call `print_topology()` correctly and know when to call it.
- Read its output to confirm hierarchy correctness.
- Use it as a first debugging step when TLM data isn't arriving.

## Theory Explanation

`uvm_top` is UVM's implicit root component (the parent of `uvm_test_top`,
which is the parent of your `test`). `uvm_top.print_topology()` walks the
entire component tree and prints every component's full hierarchical name,
type, and (depending on UVM version/verbosity) its ports. It's typically
called in `end_of_elaboration_phase` because, by that point
(Chapter 4), every component has been created (`build_phase`) *and* every
connection has been made (`connect_phase`) — so the printed topology is
final and trustworthy.

## Where Used in UVM
Universally used as a first debugging step whenever "my component doesn't
seem to exist where I expect" or "my connect_phase silently did nothing" —
before diving into waveform or `$display` debugging, check topology first.

## Syntax
```systemverilog
virtual function void end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.print_topology();
endfunction
```

## Code Example (from the source)
```systemverilog
class test extends uvm_test;
  `uvm_component_utils(test)
  env e;
  ...
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass
```
(from `source_code/03_put_port_hierarchical/tb.sv` and
`source_code/04_put_port_via_export_subconsumer/tb.sv`)

## Line-by-Line Explanation
- `end_of_elaboration_phase` — chosen specifically because hierarchy +
  connections are guaranteed complete (Chapter 4).
- `uvm_top.print_topology()` — `uvm_top` is a global singleton handle
  automatically available everywhere; no need to create or find it.

## Common Errors & Debugging Tips
- **Calling `print_topology()` inside `build_phase`** → connections aren't
  made yet, so the printout is incomplete/misleading.
- **Component missing from the printout** → almost always means it was
  `new()`'d instead of created via `type_id::create(name, parent)`
  (Chapter 3) with the wrong/`null` parent.
- **Data not arriving despite topology looking correct** → topology only
  confirms hierarchy/creation, not that `.connect()` was actually called;
  cross-check `connect_phase` code next.

## Interview-Level Points
- Why is `end_of_elaboration_phase` the idiomatic place to call
  `print_topology()`, rather than `build_phase` or `run_phase`?
- What's the first thing you check when a component "doesn't seem to
  exist" in simulation?

## Key Takeaways
- `uvm_top.print_topology()` is a one-line, always-available sanity check
  for hierarchy correctness.
- Call it from `end_of_elaboration_phase`, after both build and connect
  have completed.
