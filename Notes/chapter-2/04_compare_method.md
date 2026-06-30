# Chapter 4 — Comparing Objects with `compare()`

## Chapter Overview
A short but interview-favorite topic: how UVM compares two objects field-by-field,
and how it relates to the field macros from Chapter 2.

## Learning Objectives
- Use `compare()` and interpret its return value.
- Understand that `compare()`, like `copy()`, only "knows about" fields registered
  with field macros.

## Theory Explanation
`compare()` walks the field-automation table (the same one built by
`` `uvm_field_* `` macros) and checks each registered field for equality between
`this` and the argument object. It returns `1` if every registered field matches,
`0` otherwise. Like `copy()`, any field NOT registered with a field macro is
**invisible** to `compare()` — it will be silently ignored even if it differs.

By default, on a mismatch, `compare()` also prints a `UVM_ERROR`/report describing
which field differed (when using `uvm_default_comparer` settings) — useful for
scoreboards comparing expected vs actual transactions.

## Code Example from Source

### ex09 — compare()
`source_code/ex09_compare_method.sv`
```systemverilog
first f1, f2;
int status = 0;
initial begin
  f1 = new("f1");
  f2 = new("f2");
  f1.randomize();
  f2.copy(f1);          // make f2 identical to f1 first
  f1.print();
  f2.print();
  status = f1.compare(f2);   // 1 = equal, 0 = different
  $display("Value of status : %0d", status);
end
```
**Line-by-line:** `f2.copy(f1)` ensures the two objects start identical, so
`f1.compare(f2)` is expected to return `1`. If you instead randomized `f1` and `f2`
independently, `compare()` would almost certainly return `0` since `data` is only
4 bits wide but the randomization is independent per object.

## Common Errors and Debugging Tips
| Mistake | Symptom | Fix |
|---|---|---|
| Expecting `compare()` to check fields not registered with field macros | False "equal" result even when data differs | Register every field you care about comparing |
| Confusing `compare()`'s return value (1 = match) with a boolean "difference found" | Off-by-one logic in test pass/fail checks | Remember: `1` means *equal*, not *different* |

## Interview-Level Points
- *Q: How does `compare()` know which fields to check?* A: The same
  field-automation table populated by `` `uvm_field_* `` macros — there is no
  separate registration step.
- *Q: Where is `compare()` used in a real testbench?* A: Scoreboards — comparing an
  expected transaction (from a reference model) against an actual transaction
  (from DUT output monitors).

## Key Takeaways
- `compare()` returns `1` for "objects are equal," `0` for "different."
- It only examines fields registered via field macros — same caveat as `copy()`.
