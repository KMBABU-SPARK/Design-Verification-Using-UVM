# Chapter 9 — TLM Put Port (`uvm_blocking_put_port`/`export`/`imp`)

> **Source alignment:** covers the source's "Using put port" section and its
> four worked examples (port→export→imp, port→imp direct, hierarchical
> port→port→imp, port→export→child imp), reordered from simplest to most
> complex.

## Chapter Overview
The most common TLM pattern: one component **pushes** data to another.
Covers all four connection topologies demonstrated in the source document.

## Learning Objectives
- Explain "put" semantics: request and data travel in the *same* direction.
- Implement a `put_port`/`put_imp` pair directly.
- Implement a `put_port`/`put_export`/`put_imp` chain.
- Implement hierarchical port forwarding (child port surfaced through parent).

## Theory Explanation

**Put semantics (from the source):** "here request and data is sent in same
direction from producer to implement[er]." The producer calls
`port.put(data)`; the call travels through any exports to the imp, which
executes its `put()` body. Because this is the **blocking** variant, `put()`
can be declared as a `task` and may consume simulation time (e.g. wait for
a FIFO slot) — though in these simple examples it completes immediately.

**Why 4 topologies?** They're not 4 different features — they're the *same*
mechanism used in 4 structural situations you will hit in real testbenches:

1. **Port → Export → Imp** (Example 1): consumer doesn't want to expose its
   own `imp` directly to the outside world; it re-exposes it via an
   `export`. Adds a layer of indirection/encapsulation.
2. **Port → Imp direct** (Example 2): the simplest, most common case —
   consumer implements `put()` itself and exposes the `imp` directly.
3. **Port → Port → Imp, hierarchical** (Example 3): the *real* implementer
   (`subproducer`) is nested inside `producer`. `producer` doesn't
   re-implement `put`; it just forwards its child's port up through its own
   port. This is exactly how a `uvm_agent` forwards its internal
   `driver`'s port to the `env` level.
4. **Port → Export → child Imp** (Example 4): mirror image of #3, but on the
   receiving side — `consumer` doesn't implement `put()`; it forwards
   through an `export` down to its child `subconsumer`'s `imp`.

## Where Used in UVM
Driver receiving stimulus from a sequencer (via `seq_item_port`/
`seq_item_export`, a specialized TLM pair), scoreboard receiving expected
data from a reference model, or any producer/consumer relationship where
data flows one-directional and the sender needs to know the call completed.

## Syntax
```systemverilog
// Sender side
uvm_blocking_put_port #(TYPE) send;
send = new("send", this);       // in new() or build_phase
send.put(data);                 // must be called from a task

// Direct receiver side
uvm_blocking_put_imp #(TYPE, ThisClass) imp;
imp = new("imp", this);
function void put(TYPE datar);  // or `task`, if you need to block
  ...
endfunction

// Export (forwarding) side
uvm_blocking_put_export #(TYPE) expo;
expo = new("expo", this);
// in connect_phase: expo.connect(child.imp);
```

## Architecture Diagram
See `diagrams/tlm_port_connections.txt`, sections 1–4.

## Code Examples From the Source
All four topologies are extracted verbatim (cleaned up) into:
- `source_code/01_put_port_via_export/tb.sv`
- `source_code/02_put_port_direct_imp/tb.sv`
- `source_code/03_put_port_hierarchical/tb.sv`
- `source_code/04_put_port_via_export_subconsumer/tb.sv`

## Line-by-Line Explanation (Example 2, the canonical case)
```systemverilog
uvm_blocking_put_port #(int) send;      // #(int) parameterizes payload type
send = new("send", this);               // build_phase: allocate the port
...
send.put(data);                         // main_phase: blocking call
```
```systemverilog
uvm_blocking_put_imp#(int, consumer) imp;   // #(int, consumer) - payload + owner class
imp = new("imp", this);
function void put(int datar);           // this exact signature is required
  `uvm_info("Cons", $sformatf("Data Rcvd : %0d", datar), UVM_NONE);
endfunction
```
- The `imp`'s second parameter (`consumer`) tells UVM *which class*
  implements `put()` — internally the imp calls back into that class's
  method.
- `p.send.connect(c.imp);` in `env::connect_phase` performs the actual
  wiring; after this, `send.put(data)` will invoke `consumer::put()`.

## Common Errors & Debugging Tips
- **Signature mismatch**: the imp's implementing method must match the
  exact type/argument pattern the imp macro expects — e.g. a
  `uvm_blocking_put_imp#(int, consumer)` expects `put(int)`; a wrong
  argument type/count is a compile error.
- **Allocating the port in `new()` instead of `build_phase`** (Example 1
  does this — flagged in the code comments): works here because there's no
  parent-dependent setup, but it's non-idiomatic; `build_phase` is the UVM
  convention because config-DB lookups and factory overrides are guaranteed
  to be ready by then.
- **Connecting the wrong direction**, e.g. `c.imp.connect(p.send)` instead
  of `p.send.connect(c.imp)` — always connect *from* the port/export *to*
  the next-level export/imp.
- **Forgetting to `new()` an export/imp** before `connect_phase` uses it →
  null-handle error.

## Interview-Level Points
- Why would you introduce an `export` instead of connecting a port directly
  to an `imp`?
- In the hierarchical example, why does `producer` need its own `port` at
  all instead of exposing `s.subport` directly to `env`?
  (Encapsulation — `env` shouldn't need to know `producer`'s internal
  structure; `producer` should present one clean port.)
- What determines whether `put()` should be a `function` or a `task`?

## Key Takeaways
- Put port = push data one-directional; sender calls, receiver's `imp`
  executes the real logic.
- Four topologies, same underlying rule: chains must terminate at an `imp`.
- Hierarchical forwarding (port→port, export→export) is how real UVM
  agents/envs expose internal component ports cleanly at a higher level.
