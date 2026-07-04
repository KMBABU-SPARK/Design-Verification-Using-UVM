# Chapter 4 — `uvm_driver` and the Sequencer↔Driver Handshake

## Chapter Overview
This is "Topic-1" from the source notes, isolated to its core idea: how does
a transaction actually travel from the sequencer to the driver?

## Learning Objectives
- Explain the role of a driver in a UVM testbench.
- Explain what `seq_item_port` is and why it exists.
- Trace the `get_next_item()` / `item_done()` handshake step by step.
- Explain why the driver's main loop is `forever begin ... end`.

## Theory Explanation

### What is a driver, conceptually?
The driver is the **only** component allowed to toggle DUT input pins. Its
job is: pull one transaction at a time from the sequencer, translate it into
pin-level activity (drive `a`, `b`, wait a clock, etc.), then ask for the
next one. It never invents data itself — that's the sequence's job
(Chapters 7–9).

### `seq_item_port` — the TLM connection
`uvm_driver#(REQ, RSP)` (here just `uvm_driver#(transaction)`, meaning
REQ=RSP=transaction) automatically owns a built-in port called
`seq_item_port` of type `uvm_seq_item_pull_port`. This port is what lets the
driver "pull" transactions from whatever sequencer it's connected to. You
never declare `seq_item_port` yourself — it comes for free from the base
class.

### The Handshake
```systemverilog
virtual task run_phase(uvm_phase phase);
  forever begin
    seq_item_port.get_next_item(t);   // (1) blocks until a sequence provides one
    // apply t to DUT pins here       // (2) do the actual driving
    seq_item_port.item_done();        // (3) tell the sequencer "I'm done, send more"
  end
endtask
```
1. `get_next_item(t)` **blocks** the driver's `run_phase` task until a
   sequence calls `start_item`/`finish_item` (or the low-level equivalent).
   It also fills `t` with the transaction handle.
2. Between steps 1 and 3 is where real pin-driving happens (omitted in the
   bare-bones "Topic-1" example — the notes explicitly leave a comment
   `//////apply seq to DUT`, meaning this is the part a real testbench must
   fill in).
3. `item_done()` signals completion, which unblocks the sequence's
   `finish_item()` on the other side and lets the sequencer offer the next
   transaction.

`forever begin ... end` exists because a driver's job never "finishes" on
its own — it must be ready to service transactions for the entire test, so
it loops indefinitely inside a single, always-running `run_phase` task.

## Architecture Diagram
```
   uvm_sequence                         uvm_sequencer                          uvm_driver
 ┌───────────────┐                    ┌────────────────┐                  ┌────────────────┐
 │ start_item()   │ ── request queue ─►│  arbitrates &   │◄─get_next_item──│  run_phase:     │
 │ finish_item()  │                    │  grants access  │──transaction───►│   forever loop   │
 └───────────────┘ ◄──item_done ack──  └────────────────┘◄──item_done─────│                 │
                                                                            └────────────────┘
```

## Code Example from the Notes (Topic-1)
```systemverilog
class driver extends uvm_driver#(transaction);
`uvm_component_utils(driver)

transaction t;

function new(input string path = "DRV", uvm_component parent = null);
  super.new(path,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  t = transaction::type_id::create("t");
endfunction

virtual task run_phase(uvm_phase phase);
  forever begin
    seq_item_port.get_next_item(t);
    //////apply seq to DUT
    seq_item_port.item_done();
  end
endtask
endclass
```

## Line-by-Line Code Explanation
1. `class driver extends uvm_driver#(transaction);` — parameterized base class gives you `seq_item_port` typed to `transaction`.
2. `` `uvm_component_utils(driver) `` — factory registration (Chapter 2).
3. `transaction t;` — a handle the driver reuses every loop iteration to receive incoming items.
4. `function new(...)` / `super.new(path, parent)` — component constructor **needs both name and parent** (see Chapter 2's object-vs-component distinction).
5. `build_phase`: creates `t` via the factory. (Note: this line is actually not strictly required here since `get_next_item` will overwrite `t` with the incoming handle anyway — the source notes include it, but see "Common Errors" below for the nuance.)
6. `run_phase`: the `forever` loop implementing the three-step handshake explained above.

## Common Errors and Debugging Tips
- **Forgetting `forever`** → the driver services exactly one transaction then `run_phase` ends, silently dropping every subsequent item the sequence tries to send.
- **Doing DUT-driving work *after* `item_done()` instead of before it** → the sequencer thinks the item is already fully processed and may issue the next one concurrently, corrupting your DUT stimulus ordering.
- **Blocking forever inside the loop without ever calling `item_done()`** → the sequence hangs forever at `finish_item()`/`wait_for_item_done()`; the simulation appears to "freeze."
- **Creating `t` in `build_phase` and expecting that exact handle to matter** → `get_next_item(t)` reassigns `t` to point at whatever transaction the sequence sent; the `build_phase` creation is often just a leftover habit, not functionally necessary here.

## Key Takeaways
- The driver is the only place DUT pins get toggled; sequences never touch pins directly.
- `seq_item_port` is inherited for free from `uvm_driver#(...)`; you don't declare it.
- The three-step handshake — `get_next_item` → drive DUT → `item_done` — is the fundamental pattern behind every UVM driver you will ever write.
- `run_phase` uses `forever` because the driver must remain available for the entire test duration.
