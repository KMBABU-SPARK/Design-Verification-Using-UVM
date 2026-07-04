# Chapter 7 — High-Level Sequence API: `start_item()` / `finish_item()`



## Learning Objectives
- Explain what `start_item()` and `finish_item()` each do internally.
- Rewrite a low-level sequence (Chapter 8) using the high-level API and confirm behavioral equivalence.
- Generate multiple transactions from one sequence using `repeat`.

## Theory Explanation

### The mapping to the low-level API
| High-level call | Equivalent low-level steps |
|---|---|
| `start_item(trans)` | `wait_for_grant()` |
| *(you randomize here, in between)* | `assert(trans.randomize())` |
| `finish_item(trans)` | `send_request(trans)` + `wait_for_item_done()` |

This is why `start_item`/`finish_item` is preferred in real projects: it's
two lines instead of four, with randomization sitting naturally between them
— less boilerplate, same guaranteed synchronization with the driver.

```systemverilog
start_item(trans);
assert(trans.randomize);
finish_item(trans);
```

### Generating multiple items: `repeat`
```systemverilog
repeat(5) begin
  trans = transaction::type_id::create("trans");
  start_item(trans);
  assert(trans.randomize);
  finish_item(trans);
  `uvm_info("SEQ", $sformatf("a : %0d b:%0d", trans.a, trans.b), UVM_NONE);
end
```
Notice a **fresh transaction object is created inside the loop, every
iteration**. This matters — reusing one handle across iterations (creating
it once, outside the loop) would still work mechanically, but each
`randomize()` would overwrite the same object, and any code that stored a
reference to a "previous" transaction (e.g., a coverage collector keeping a
transaction history) would incorrectly see every entry pointing at the
identical, final randomized values.

## Architecture Diagram
```
   for 5 iterations:
   ┌────────────────────────────────────────────────────┐
   │ create new transaction                             │
   │        │                                           │
   │        ▼                                           │
   │  start_item(trans) ───► (internally: wait_for_grant)   
   │        │                                           │
   │        ▼                                           │
   │  randomize(trans)                                  │
   │        │                                           │
   │        ▼                                           │
   │  finish_item(trans) ──► (internally: send_request  │
   │        │                 + wait_for_item_done)     │
   │        ▼                                           │
   │  print a, b via `uvm_info                          │
   └────────────────────────────────────────────────────┘
```

## Code Example from the Notes (Topic-3)
```systemverilog
class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1)
  transaction trans;

  function new(string path = "sequence1");
    super.new(path);
  endfunction

  virtual task body();
    repeat(5) begin
      trans = transaction::type_id::create("trans");
      //simplest way to use the sequence to generate and send the data to driver class
      start_item(trans);
      assert(trans.randomize);
      finish_item(trans);
      `uvm_info("SEQ", $sformatf("a : %0d b:%0d", trans.a, trans.b), UVM_NONE);
    end
  endtask
endclass

class driver extends uvm_driver#(transaction);
`uvm_component_utils(driver)
  transaction trans;

  function new(input string inst = "DRV", uvm_component c);
    super.new(inst,c);
  endfunction

  virtual task run_phase(uvm_phase phase);
    trans = transaction::type_id::create("trans");
    forever begin
      seq_item_port.get_next_item(trans);
      `uvm_info("DRV", $sformatf("a : %0d b:%0d", trans.a, trans.b), UVM_NONE);
      seq_item_port.item_done();
    end
  endtask
endclass
```

## Line-by-Line Code Explanation
- `repeat(5) begin ... end` — runs the enclosed block exactly 5 times, generating 5 independent transactions.
- `start_item(trans);` — requests sequencer access for this item (blocks until granted, arbitration-aware).
- `assert(trans.randomize);` — note: **missing parentheses** (`randomize` instead of `randomize()`) — SystemVerilog allows calling a method with no arguments without parentheses, so this compiles and runs identically to `randomize()`. Still, `randomize()` with explicit parentheses is the clearer, more conventional style.
- `finish_item(trans);` — sends the item and blocks until the driver reports it done.
- `$sformatf("a : %0d b:%0d", trans.a, trans.b)` — formats a string for the log message; `%0d` prints a decimal integer with no leading padding.
- Driver side: unchanged three-step handshake, now also logging the received values for visual confirmation that data actually transferred correctly.

## Common Errors and Debugging Tips
- **Calling `finish_item()` without a matching `start_item()`** → runtime error; the API requires the pair to be called on the same item, in order.
- **Modifying `trans` fields after `finish_item()` returns** → too late; the driver may have already read (or even finished processing) the item.
- **Forgetting to create a new transaction each `repeat` iteration** → all 5 "different" transactions end up being the same object handle, defeating the purpose of generating varied stimulus.
- **Relying on `assert(trans.randomize)` without parentheses out of habit** → works, but many lint/style guides flag this; prefer `randomize()` for readability and to avoid confusion with a possible `randomize` *property* name collision in more complex classes.

## Key Takeaways
- `start_item`/`finish_item` is the idiomatic two-call pattern that replaces four low-level calls; know both because interviews frequently ask about the internal mapping.
- Always create a fresh item per loop iteration when generating multiple transactions.
- The driver-side handshake code is identical regardless of which sequence API style is used — this decoupling is by design.
