# Chapter 3 — Agent, Env, and Test: Assembling the Component Tree

## Chapter Overview
The driver from Chapter 4 needs a sequencer to talk to, and that pairing
needs to live inside a proper component hierarchy. This chapter covers
`uvm_agent`, `uvm_env`, and `uvm_test` together since they always appear as
a connected unit in the notes.

## Learning Objectives
- Explain the responsibility of `uvm_agent`, `uvm_env`, and `uvm_test`.
- Connect a driver to a sequencer using `connect_phase`.
- Start a sequence on a sequencer from the test's `run_phase`.

## Theory Explanation

### `uvm_agent` — packaging driver + sequencer (+ monitor) together
An agent groups everything related to **one DUT interface** into a single
reusable unit. In these notes the agent owns exactly a `driver` and a
`uvm_sequencer#(transaction)`.

```systemverilog
class agent extends uvm_agent;
  driver d;
  uvm_sequencer #(transaction) seqr;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d    = driver::type_id::create("d",this);
    seqr = uvm_sequencer #(transaction)::type_id::create("seqr",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
```

The critical line is `d.seq_item_port.connect(seqr.seq_item_export)` —
**this is the line that physically wires the handshake from Chapter 4
together.** Without it, `get_next_item()` has nothing to pull from and the
driver hangs forever.

### `uvm_env` — the environment
The env exists to group **one or more agents** (plus, in a fuller
testbench, a scoreboard/coverage collector) into the reusable DUT-level
verification environment. Here it owns exactly one `agent`.

### `uvm_test` — where the actual test scenario is chosen
The test is the only layer that:
1. Decides *which* sequence(s) to run.
2. Starts them by calling `seq.start(sequencer)`.
3. Raises/drops the objection that keeps the simulation alive (Chapter 10).

```systemverilog
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  seq1.start(e.a.seqr);
  phase.drop_objection(this);
endtask
```
Note the path `e.a.seqr` — **test → env → agent → sequencer** — this
dotted path is only possible because each parent explicitly created and
stored a handle to its child in `build_phase`.

## Architecture Diagram
```
test
 ├─ e : env
 │    └─ a : agent
 │         ├─ d    : driver ───┐
 │         └─ seqr : sequencer ┘  (connected in agent::connect_phase)
 └─ seq1 : sequence1   (started via  seq1.start(e.a.seqr)  in test::run_phase)
```

## Code Examples from the Notes
```systemverilog
class env extends uvm_env;
`uvm_component_utils(env)
  agent a;
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = agent::type_id::create("a",this);
  endfunction
endclass

class test extends uvm_test;
`uvm_component_utils(test)
  sequence1 seq1;
  env e;
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e",this);
    seq1 = sequence1::type_id::create("seq1");
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq1.start(e.a.seqr);
    phase.drop_objection(this);
  endtask
endclass
```

## Line-by-Line Code Explanation
- `agent::type_id::create("a", this)` — `this` (the env) is passed as parent, placing `a` correctly under `e` in the component tree.
- `seq1 = sequence1::type_id::create("seq1");` — **no parent argument**, because `sequence1` is a `uvm_object`, not a `uvm_component` (Chapter 2/3).
- `seq1.start(e.a.seqr);` — starts the sequence's `body()` task on the given sequencer; this single call is what actually begins stimulus generation.
- `phase.raise_objection(this)` / `phase.drop_objection(this)` — bracket the sequence's execution so the simulation doesn't end while it's still running (full explanation in Chapter 10).

## Common Errors and Debugging Tips
- **Forgetting `d.seq_item_port.connect(seqr.seq_item_export)` in `connect_phase`** → driver's `get_next_item()` hangs forever with no error message — one of the most common "my testbench does nothing" bugs.
- **Building components in `connect_phase` instead of `build_phase`** → the child doesn't exist yet when a parent tries to reference it, or factory overrides set for that type are bypassed.
- **Passing `this` when creating a `uvm_object` (like a sequence)** → compile error; only `uvm_component::type_id::create()` takes a parent argument.
- **Calling `seq1.start(...)` without a preceding `raise_objection`** → the sequence may be cut off mid-execution because the simulation phase ends as soon as `run_phase` returns, if nothing is holding it open.

## Key Takeaways
- Agent = driver + sequencer (+monitor) for one interface. Env = one or more agents. Test = chooses and starts sequences.
- The connect step `d.seq_item_port.connect(seqr.seq_item_export)` is the literal wire between Chapter 4's handshake ends — never skip it.
- Sequences are started from the **test**, not from inside the agent/env, because "which scenario runs" is a test-level decision by design.
