# Chapter 8 — Low-Level Sequence API: `wait_for_grant` / `send_request` / `wait_for_item_done`

## Chapter Overview
"Topic-2" in the source notes ("understand the exact flow followed by
sequence and driver") deliberately uses the verbose, manual handshake API
instead of the shortcut (`start_item`/`finish_item`, Chapter 9) specifically
to teach *what's happening underneath*. This chapter treats it as a
first-class topic, in its original teaching intent.

## Learning Objectives
- Name each low-level API call and what it does, in execution order.
- Explain why this API exists even though `start_item`/`finish_item` is preferred in practice.
- Trace, line by line, how a single transaction travels from sequence to driver and back.

## Theory Explanation

### Why learn the "hard way" first?
`start_item()`/`finish_item()` (Chapter 9) are convenience wrappers around
exactly this low-level sequence of calls. Learning the manual version first
demystifies what those two calls do internally — a very common interview
question is "what does `start_item`/`finish_item` do under the hood?", and
the answer is precisely this chapter.

### The Four-Step Manual Handshake
```systemverilog
trans = transaction::type_id::create("trans");   // (0) create the item
wait_for_grant();                                 // (1) request permission from the sequencer
assert(trans.randomize());                        // (2) fill in random stimulus
send_request(trans);                              // (3) hand the item to the driver
wait_for_item_done();                              // (4) block until driver signals completion
```

1. **`wait_for_grant()`** — asks the sequencer for permission to proceed.
   The sequencer's **arbitration** logic (Chapter 12) decides *when* this
   call returns, especially if multiple sequences are competing for the
   same sequencer.
2. Randomize **after** the grant, not before — this ensures data is as
   fresh as possible relative to when it will actually be used, and mirrors
   the pattern used by `start_item`/`finish_item` internally.
3. **`send_request(trans)`** — pushes the item into the sequencer's queue for
   the driver to receive via `get_next_item()`.
4. **`wait_for_item_done()`** — blocks until the driver calls
   `seq_item_port.item_done()` (Chapter 4), synchronizing the sequence with
   the driver's completion of the transaction.

### Matching driver side (unchanged from Chapter 4)
The driver code doesn't need to know or care whether the sequence used the
low-level or high-level API — from the driver's perspective, it's still
just `get_next_item()` → drive → `item_done()`. This symmetry is intentional:
**the driver interface is the same regardless of which sequence API style is
used on the other side.**

## Architecture Diagram
```
   sequence1::body()                              driver::run_phase()
 ┌─────────────────────────┐                    ┌──────────────────────┐
 │ create(trans)             │                    │                       │
 │ wait_for_grant()  ────────┼──── request ──────►│                       │
 │  (blocks until granted)   │                    │  get_next_item(t) ◄───┼─ (unblocks after
 │ randomize(trans)          │                    │                       │   send_request)
 │ send_request(trans) ──────┼──── item ─────────►│  // drive DUT          │
 │ wait_for_item_done() ◄────┼──── item_done ─────│  item_done()          │
 └─────────────────────────┘                    └──────────────────────┘
```

## Code Example from the Notes (Topic-2)
```systemverilog
class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1)
  transaction trans;

  function new(input string inst = "seq1");
    super.new(inst);
  endfunction

  virtual task body();
    `uvm_info("SEQ1", "Trans obj Created" , UVM_NONE);
    trans = transaction::type_id::create("trans");
    `uvm_info("SEQ1", "Waiting for Grant from Driver" , UVM_NONE);
    wait_for_grant();
    `uvm_info("SEQ1", "Rcvd Grant..Randomizing Data" , UVM_NONE);
    assert(trans.randomize());
    `uvm_info("SEQ1", "Randomization Done -> Sent Req to Drv" , UVM_NONE);
    send_request(trans);
    `uvm_info("SEQ1", "Waiting for Item Done Resp from Driver" , UVM_NONE);
    wait_for_item_done();
    `uvm_info("SEQ1", "SEQ1 Ended" , UVM_NONE);
  endtask
endclass
```

## Line-by-Line Code Explanation
- `trans = transaction::type_id::create("trans");` — factory-created item (Chapter 2/3).
- `wait_for_grant();` — blocking call; only returns once the sequencer's arbitration selects this sequence.
- `assert(trans.randomize());` — standard defensive randomization pattern (Chapter 0).
- `send_request(trans);` — hands the (already-randomized) item to the sequencer's item queue.
- `wait_for_item_done();` — blocks until the driver's `item_done()` call unblocks it.
- Each `` `uvm_info `` call is purely instructional here — it exists so a beginner can watch the exact order these five steps execute in the simulation log.

## Common Errors and Debugging Tips
- **Calling `send_request()` before `wait_for_grant()` returns** → violates the API contract; some simulators flag this as an error, others silently misbehave.
- **Randomizing before `wait_for_grant()`** → wastes randomization if the grant is delayed/denied for a long time in an arbitration-heavy environment (Chapter 12), and can desynchronize timing-sensitive test intent.
- **Never calling `wait_for_item_done()`** → the sequence's `body()` returns before the driver has actually finished processing the item, which can cause the test to drop its objection and end the simulation prematurely, cutting off in-flight DUT activity.
- **Mixing this API with `start_item`/`finish_item` in the same sequence body call** → don't call both APIs for the same item; pick one style per item.

## Key Takeaways
- The low-level API — `wait_for_grant → randomize → send_request → wait_for_item_done` — is exactly what `start_item`/`finish_item` (Chapter 9) do internally.
- Understanding this flow is what lets you correctly answer "what happens if I call `finish_item` without `start_item`?" style interview questions.
- The driver-side code never changes between low-level and high-level sequence styles — the abstraction boundary is clean.
