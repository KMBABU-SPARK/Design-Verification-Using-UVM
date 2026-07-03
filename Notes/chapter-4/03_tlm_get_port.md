# Chapter 03 — TLM Get Port (`uvm_blocking_get_port`/`imp`)

> **Source alignment:** covers the source's "use of get port" section
> verbatim, with the direction-reversal explanation expanded.

## Chapter Overview
The mirror image of put: the *request* flows one way, but the *data*
flows back the other way.

## Learning Objectives
- Explain how get differs from put in terms of data direction.
- Implement a `get_port`/`get_imp` pair with an `output` argument.

## Theory Explanation

Source document, verbatim idea: "here producer put the request of data to
the consumer and the data is sent by consumer to the producer — request and
data flow direction are different here."

With put, the caller *provides* the data (`put(data)` — an `input`). With
get, the caller *requests* data and receives it back (`get(output data)` —
the argument is filled in by the callee). Structurally the connection looks
identical (`producer.port.connect(consumer.imp)`), but semantically the
information flow is reversed: producer *pulls* from consumer.

## Where Used in UVM
Any situation where the initiator needs to *retrieve* something it doesn't
already have — e.g. a driver pulling the next stimulus item from a
sequencer-like source (though real sequencers typically use the specialized
`uvm_seq_item_pull_port`, which is conceptually a `get`/`transport`-family
port).

## Syntax
```systemverilog
uvm_blocking_get_port #(TYPE) port;
port = new("port", this);
port.get(data);                       // data is an `output`-style arg, filled by callee

uvm_blocking_get_imp#(TYPE, ThisClass) imp;
imp = new("imp", this);
virtual task get(output TYPE datar);  // callee fills datar and returns
  datar = ...;
endtask
```

## Architecture Diagram
See `diagrams/tlm_port_connections.txt`, section 5.
```
producer.port.get(data)  --(travels to)-->  consumer.get(datar)
                                                    |
                            consumer fills datar, returns
                                                    |
producer.data  <-----------------------------------+
```

## Code Example (from the source)
See `source_code/05_get_port/tb.sv`.

## Line-by-Line Explanation
```systemverilog
uvm_blocking_get_port #(int) port;
int data = 0;
...
port.get(data);                 // producer PULLS - data ends up populated after this call
`uvm_info("PROD", $sformatf("Data Recv : %0d", data), UVM_NONE);
```
```systemverilog
uvm_blocking_get_imp#(int, consumer) imp;
int data = 12;                  // this is the value that WILL be sent
...
virtual task get(output int datar);
  `uvm_info("CONS", $sformatf("Data Sent : %0d", data), UVM_NONE);
  datar = data;                 // this is what producer's `data` becomes
endtask
```
- Note both classes happen to use a variable literally called `data`; they
  are unrelated — `consumer.data` is the source value, `producer.data` is
  the destination variable overwritten by the `get()` call.

## Common Errors & Debugging Tips
- **Confusing get with put** and writing `get(input ...)` instead of
  `get(output ...)` — wrong direction, compile error or silently wrong
  value.
- **Expecting the producer's initial `data` value to matter** — it doesn't;
  it gets overwritten by whatever the consumer returns.
- **Forgetting `virtual`** on the `get()` task implementation — breaks
  polymorphic dispatch from the imp.

## Interview-Level Points
- When would you choose `get` over `put`, architecturally?
- Why is the argument to `get()` declared `output` rather than `input`?
- Could you build "get" behavior using a `put` port instead? (Not directly —
  direction of data flow is baked into which side implements/holds it.)

## Key Takeaways
- Put = push (caller provides data). Get = pull (caller requests, callee
  supplies).
- Same connection mechanics as put; only the method signature/semantics
  differ.
