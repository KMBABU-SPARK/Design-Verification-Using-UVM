# Chapter 6 — Run-Time Phases Across Multiple Components

## Chapter Overview
Chapter 5 showed objections in a single `task`. This chapter (the "4: time consuming
phases in multiple components" example from the source) shows what actually happens when
**two different components** — `driver` and `monitor` — each raise/drop objections with
*different* delays inside the *same* phase, and proves the rule stated in Chapter 5:
a phase ends only when **every** component's objections are dropped — i.e., it waits for
the slowest one.

## Learning Objectives
- Trace a multi-component timeline by hand given each component's delays
- Explain why `reset_phase` ends at the time of the *last* dropped objection, not the
  first
- Recognize the `post_main_phase` phase and understand its purpose

## Theory Explanation
When `driver` and `monitor` are siblings under the same `env`, and both override
`reset_phase`, UVM starts **both tasks at the same simulated time** (t=0) — they run
concurrently, not sequentially. `reset_phase` (the phase) is only complete once **both**
components have dropped their objection. Whichever component takes longer determines
when the phase actually ends. The same logic applies independently to `main_phase`
immediately after.

## Code Example From Source
`source_code/04_multi_component_time_consuming_phases.sv` — full driver, monitor, env,
test, and top module.

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

class driver extends uvm_driver;
  `uvm_component_utils(driver)

  function new(string path = "test", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("drv", "Driver Reset Started", UVM_NONE);
    #100;
    `uvm_info("drv", "Driver Reset Ended", UVM_NONE);
    phase.drop_objection(this);
  endtask

  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("drv", "Driver Main Phase Started", UVM_NONE);
    #100;
    `uvm_info("drv", "Driver Main Phase Ended", UVM_NONE);
    phase.drop_objection(this);
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)

  function new(string path = "monitor", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("mon", "Monitor Reset Started", UVM_NONE);
    #300;
    `uvm_info("mon", "Monitor Reset Ended", UVM_NONE);
    phase.drop_objection(this);
  endtask

  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("mon", "Monitor Main Phase Started", UVM_NONE);
    #400;
    `uvm_info("mon", "Monitor Main Phase Ended", UVM_NONE);
    phase.drop_objection(this);
  endtask
endclass

class env extends uvm_env;
  `uvm_component_utils(env)
  driver d;
  monitor m;

  function new(string path = "env", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d = driver::type_id::create("d", this);
    m = monitor::type_id::create("m", this);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test)
  env e;

  function new(string path = "test", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e", this);
  endfunction
endclass

module tb;
  initial begin
    run_test("test");
  end
endmodule
```

## Line-by-Line Timeline Walkthrough

**Reset Phase (both start at t=0):**
| Component | Raise at | Delay | Drop at |
|---|---|---|---|
| driver | t=0 | #100 | t=100 |
| monitor | t=0 | #300 | t=300 |

Reset phase objection count reaches zero only at **t=300** (monitor is the slower one) —
so `reset_phase` doesn't end at t=100 just because the driver finished; UVM correctly
waits for the monitor too.

**Main Phase (both start right after reset ends, i.e. at t=300):**
| Component | Raise at | Delay | Drop at |
|---|---|---|---|
| driver | t=300 | #100 | t=400 |
| monitor | t=300 | #400 | t=700 |

Main phase ends at **t=700**.

> Source material's own note on this example: *"here we can observe that multiple task
> even with the different [delays] holds its function until previous task work is not
> completed"* — i.e., the phase as a whole is gated on the slowest component, and the
> next phase never starts early.

## Architecture / Timing Diagram
```
              RESET PHASE                              MAIN PHASE
t:   0        100              300         300         400              700
     │         │                │           │           │                │
drv  ├─raise───┼──#100──drop────┤           ├─raise─────┼──#100──drop────┤
mon  ├─raise───┼──────#300──────┼──drop─────┤           ├─raise────#400──┼──drop
                                 ▲                                        ▲
                    reset phase ends here                    main phase ends here
                    (waits for slowest: monitor)              (waits for slowest: monitor)
```

## New Phase Introduced: `post_main_phase`
The drain-time example later in the source (reused in Chapter 8) adds a
`post_main_phase` task to both `driver` and `monitor`. It's simply the next phase in
UVM's default run-time schedule after `main_phase` — proof that the same
raise/drop/waiting logic repeats for every phase in the run-time group, not just
`reset` and `main`.

## Common Errors and Debugging Tips
- **Assuming the phase ends when the *first* component finishes** — wrong; always the
  *last*. When debugging "why is my simulation slower than I expect," check every
  component's objections in that phase, not just the one you were focused on.
- **Forgetting that reset_phase and main_phase run sequentially relative to each other**
  (main doesn't start until reset's objection count is fully zero) **but components
  within the same phase run in parallel** — mixing these two up leads to wrong timeline
  predictions.
- **Debug tip:** run with `+UVM_OBJECTION_TRACE` (or your simulator's equivalent) to get
  a printed trail of every raise/drop with the component name and time — invaluable when
  a phase seems to end "too late" and you don't know which component is holding it open.

## Interview-Level Points
- "Two components raise objections in the same phase with different delays — when does
  the phase end?" — at the time of the *last* `drop_objection` call across all
  components, i.e. governed by the slowest component.
- "Do `main_phase` and `reset_phase` for the *same* component run concurrently?" — no;
  they are part of the same sequential default run-time schedule
  (reset→configure→main→shutdown) even though within each of those phases, different
  *components* run concurrently.

## Key Takeaways
- Within one run-time phase, all components' phase tasks run concurrently.
- The phase itself ends only when the last component drops its objection.
- This "wait for the slowest" behavior is not a bug — it's the entire point of the
  objection mechanism, and it's the reason you must trace timelines carefully.
