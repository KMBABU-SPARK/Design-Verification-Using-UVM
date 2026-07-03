# Chapter 05 — TLM Analysis Port (`uvm_analysis_port`/`uvm_analysis_imp`)

> **Source alignment:** covers the source's "ANALYSIS PORT" section and its
> worked example, plus Assignment 2 (three-subscriber broadcast).

## Chapter Overview
One-to-many, non-blocking broadcast — the pattern behind every
monitor→scoreboard/coverage connection in real UVM testbenches.

## Learning Objectives
- Explain why analysis ports are non-blocking and why `write()` is always
  a `function`.
- Connect one analysis port to multiple imps (fan-out).
- Recognize this as the standard monitor-broadcast pattern.

## Theory Explanation

Source document, verbatim idea: "This port is used for communication
between multiple consumers and single producer. This port is time
independent unlike other port[s], it dont wait till entire data is sent or
received... so here we basically use virtual function."

**Why non-blocking?** A monitor observing DUT activity shouldn't have to
wait for every subscriber (scoreboard, coverage collector, logger...) to
finish processing before it can continue watching the bus. So
`uvm_analysis_port.write(data)` fires the call to **every** connected
`uvm_analysis_imp` **immediately**, without blocking, and doesn't care how
many subscribers exist — zero, one, or many. That's why the implementing
method must be a plain `function` (Chapter 0): a `function` cannot block,
guaranteeing the broadcast really is instantaneous.

**Fan-out (1-to-N):** unlike put/get/transport (which connect one port to
one export/imp — a strict 1-to-1 pipe), a single `uvm_analysis_port` can be
`.connect()`-ed to **many** different imps. Every one of them receives every
`write()` call.

## Where Used in UVM
This is *the* standard way a `uvm_monitor` reports observed transactions to
a scoreboard and/or a coverage collector simultaneously — arguably the most
important TLM pattern in any real UVM environment.

## Syntax
```systemverilog
uvm_analysis_port #(TYPE) port;
port = new("port", this);
port.write(data);                      // broadcasts to ALL connected imps, no wait

uvm_analysis_imp#(TYPE, ThisClass) imp;
imp = new("imp", this);
virtual function void write(TYPE datar);   // MUST be a function, not a task
  ...
endfunction

// connect_phase - fan-out:
producer.port.connect(subscriber1.imp);
producer.port.connect(subscriber2.imp);
producer.port.connect(subscriber3.imp);
```

## Architecture Diagram
See `diagrams/tlm_port_connections.txt`, section 7.

## Code Examples From the Source
- Two-subscriber version: `source_code/07_analysis_port_broadcast/tb.sv`
- Three-subscriber version (Assignment 2, string payload):
  `projects/assignment2_analysis_broadcast/tb.sv`

## Line-by-Line Explanation
```systemverilog
uvm_analysis_port #(int) port;
...
port.write(data);          // fires to c1.imp AND c2.imp, non-blocking
```
```systemverilog
uvm_analysis_imp#(int, consumer1) imp;
virtual function void write(int datar);   // function, not task - cannot block
  `uvm_info("CONS1", $sformatf("Data Recv : %0d", datar), UVM_NONE);
endfunction
```
```systemverilog
// env::connect_phase
p.port.connect(c1.imp);
p.port.connect(c2.imp);     // same port, second .connect() call = fan-out
```

## Common Errors & Debugging Tips
- **Implementing `write()` as a `task`** → compile error; analysis imps
  require a `function`.
- **Expecting order/synchronization between subscribers** — all subscribers
  receive the same call in the order `.connect()`s were made, but since
  it's non-blocking there's no "wait for subscriber 1 to finish" guarantee
  the way there would be with sequential blocking calls (in practice,
  function calls in SV do execute sequentially in call order, but no
  subscriber can make the broadcast itself block/wait).
- **Trying to `.connect()` an analysis port to an export expecting a
  different type parameter** → type mismatch, compile error.
- **Assuming analysis ports enforce exactly one connection** — they
  explicitly support many; forgetting this and only connecting one
  subscriber when you meant to fan out to several is a common oversight.

## Interview-Level Points
- Why must `write()` always be a `function`, never a `task`?
- Why is the analysis port the natural choice for monitor→scoreboard and
  monitor→coverage connections specifically (vs. put/get)?
- Can a single analysis port have zero connections? What happens to
  `write()` calls in that case? (They're simply dropped/no-op — no error.)

## Key Takeaways
- Analysis port = 1-to-N, non-blocking broadcast.
- `write()` must be a `function`.
- This is the canonical monitor → (scoreboard + coverage) UVM pattern.
