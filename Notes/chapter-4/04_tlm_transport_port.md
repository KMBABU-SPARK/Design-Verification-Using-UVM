# Chapter 04 — TLM Transport Port (`uvm_blocking_transport_port`/`imp`)

> **Source alignment:** covers the source's "Transport port" section
> verbatim.

## Chapter Overview
Bidirectional communication in a single call — send and receive combined.

## Learning Objectives
- Explain when transport is preferable to separate put+get calls.
- Implement a `transport_port`/`transport_imp` pair with two type
  parameters (request and response).

## Theory Explanation

Source document, verbatim idea: "This port is used for bidirectional
communication between producer and consumer. Here both of them can send
data a[t the] same time to each other."

Put moves data one way; get pulls data the other way; **transport** does
both **in one atomic call**: the initiator sends a request and receives a
response as part of the same method invocation —
`port.transport(request, response)`. This models protocols where a
send-and-reply is a single logical transaction (e.g. a memory read: address
out, data back, as one bus operation), rather than two independent
put/get calls that could be arbitrarily interleaved with other traffic.

## Where Used in UVM
Bus-style read transactions, register-access-layer backdoor/frontdoor
transactions, or any protocol where "send this, get a reply to *this
specific* send" must be atomic rather than two separately-orderable calls.

## Syntax
```systemverilog
uvm_blocking_transport_port #(REQ, RSP) port;   // two type parameters
port = new("port", this);
port.transport(req_data, rsp_data);             // rsp_data filled by callee

uvm_blocking_transport_imp#(REQ, RSP, ThisClass) imp;
imp = new("imp", this);
virtual task transport(input REQ req, output RSP rsp);
  rsp = ...;
endtask
```

## Architecture Diagram
See `diagrams/tlm_port_connections.txt`, section 6.
```
producer.port.transport(datas, datar)
        |                          |
        v                          ^
   consumer.transport(datar_in, datas_out)  -- one call, two-way data
```

## Code Example (from the source)
See `source_code/06_transport_port/tb.sv`.

## Line-by-Line Explanation
```systemverilog
uvm_blocking_transport_port #(int , int) port;   // #(REQ=int, RSP=int)
int datas = 12;   // what producer sends
int datar = 0;    // will hold what producer receives
...
port.transport(datas, datar);   // one call: send datas, block until datar is filled
```
```systemverilog
uvm_blocking_transport_imp#(int, int , consumer) imp;
int datas = 13;   // what consumer will reply with
...
virtual task transport(input int datar , output int datas);
  datas = this.datas;   // reply with consumer's own datas (13)
  ...
endtask
```
- Naming collision alert: the consumer's task parameters are also named
  `datar`/`datas`, and it uses `this.datas` to disambiguate its own member
  variable from the task's local `output datas` parameter — a subtle but
  important SystemVerilog scoping detail.

## Common Errors & Debugging Tips
- **Variable name shadowing** (as above): using `this.` to refer to the
  member when a task parameter has the same name — omitting `this.` would
  reference the wrong (local) variable.
- **Swapping REQ/RSP type parameter order** between port and imp
  declarations → connection type mismatch, compile error.
- **Treating transport as "just put then get"** — semantically it's meant
  to be atomic; splitting it into two calls loses that guarantee.

## Interview-Level Points
- How does `transport` differ from issuing a `put` immediately followed by
  a `get`?
- Why does `uvm_blocking_transport_port` take two type parameters instead
  of one?
- Give a real protocol example where transport-style semantics are a
  natural fit.

## Key Takeaways
- Transport = one call, two-way data exchange (`REQ` out, `RSP` back).
- Useful for atomic request/response protocols like bus reads.
