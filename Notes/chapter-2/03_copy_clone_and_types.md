# Chapter 3 — Duplicating Objects: `copy()`, `clone()`, Shallow vs Deep Copy

## Chapter Overview
The most conceptually important (and most-asked-in-interviews) part of `uvm_object`:
how object duplication actually works, why simple assignment (`s2 = s1`) is
dangerous, and how `copy()`/`clone()` solve it.

## Learning Objectives
- Distinguish handle assignment from object duplication.
- Use `copy()` correctly (destination must already exist).
- Use `clone()` correctly (creates + copies, requires `$cast`).
- Explain shallow copy vs deep copy with a concrete example, and know which one
  UVM's auto-generated `copy()`/`clone()` perform by default.

## Theory Explanation

### The core problem: `s2 = s1` is NOT a copy
```systemverilog
second s1, s2;
s1 = new("s1");
s2 = new("s2");
...
s2 = s1;   // <-- this does NOT copy s1's data into s2.
           //     It makes s2 POINT TO THE SAME OBJECT as s1.
```
After `s2 = s1`, there is only **one object** in memory with **two handles**
pointing at it. Any change through `s2` is visible through `s1` too — this is what
the source material calls a **shallow copy**, except it's not even copying any
fields at all; it's pure handle aliasing. (The term "shallow copy" more precisely
applies to `copy()`/`clone()` when only the *top-level* fields are duplicated but
nested object fields are still shared — see below.)

### `copy()` — deep-copies field by field, but the destination must exist
```systemverilog
f2 = new("f2");      // destination object must already exist
f2.copy(f1);          // f2's registered fields now match f1's, FIELD BY FIELD
```
`copy()` uses the field-automation table from Chapter 2 to copy each registered
field. For an `` `uvm_field_object `` field, UVM recursively calls `copy()` on the
nested object too — so the **default behavior of UVM's generated copy() is a deep
copy** for any field properly registered with `` `uvm_field_object ``.

### `clone()` — `create()` + `copy()` in one call, returns a generic handle
```systemverilog
$cast(s, f.clone());
```
`clone()` internally does the equivalent of `type_id::create()` for a brand-new
object **and** copies `f`'s data into it — all in one call. Because `clone()`'s
return type is the generic `uvm_object`, you must `$cast` it to your specific class.

### Shallow vs Deep — visual proof from the source examples

**Shallow (ex07 — plain handle assignment, no `copy`/`clone` involved at all):**
```
 s1 ──┐
      ├──► [ second object: f -> [ first object: data=X ] ]
 s2 ──┘            (s1 and s2 share EVERYTHING — same second AND same first)
```
Changing `s2.f.data` also changes what `s1.f.data` reads, because there's only one
`second` object and one `first` object in memory.

**Deep (ex08 — using `clone()`):**
```
 s1 ──► [ second object #1: f -> [ first object #1: data=X ] ]

 s2 ──► [ second object #2: f -> [ first object #2: data=X (copy) ] ]
         (separate object, separate nested object — fully independent)
```
After `$cast(s2, s1.clone())`, `s2` is a totally separate object tree. Changing
`s2.f.data` does **not** affect `s1.f.data`.

## Code Examples from Source

### ex06 — clone() vs copy() syntax
`source_code/ex06_clone_vs_copy.sv`
```systemverilog
// copy() approach (destination pre-allocated):
// f = new("first"); s = new("second"); f.randomize(); s.copy(f);

// clone() approach (one call, needs $cast):
f = new("first");
f.randomize();
$cast(s, f.clone());
```

### ex07 — shallow copy demonstration
`source_code/ex07_shallow_copy.sv`
```systemverilog
second s1, s2;
s1 = new("s1"); s2 = new("s2");
s1.f.randomize();
s1.print();
s2 = s1;            // handle aliasing, NOT a copy
s2.print();          // identical to s1 (same object)

s2.f.data = 12;       // mutate through s2...
s1.print();            // ...s1 ALSO shows data = 12 → proves shared object
s2.print();
```
**Line-by-line:** `s2 = s1` is plain SystemVerilog handle assignment — both
variables now reference the exact same `second` instance. The subsequent mutation
`s2.f.data = 12` is visible from `s1` because there is no second copy anywhere.

### ex08 — deep copy demonstration
`source_code/ex08_deep_copy.sv`
```systemverilog
second s1, s2;
s1 = new("s1");
s1.f.randomize();

$cast(s2, s1.clone());   // DEEP copy via clone()

s1.print();
s2.print();

s2.f.data = 12;           // mutate s2's nested object
s1.print();                // s1 UNCHANGED
s2.print();
```

## Common Errors and Debugging Tips
| Mistake | Symptom | Fix |
|---|---|---|
| Using `s2 = s1` thinking it duplicates data | Bugs from unintended shared state | Use `copy()` or `clone()` instead |
| Calling `copy()` on a `null` destination handle | Runtime null-object crash | `new()`/`create()` the destination first, or use `clone()` instead |
| Forgetting `$cast` after `clone()` | Compile error (type mismatch) | `clone()` returns `uvm_object`; always `$cast` to your specific class |
| Nested object field NOT registered with `` `uvm_field_object `` | "Deep" copy silently becomes shallow for that field | Register every nested object field |

## Interview-Level Points
- *Q: What's the difference between `copy()` and `clone()`?* A: `copy()` copies data
  into an already-existing destination object; `clone()` creates a new object AND
  copies into it in a single call, returning a generic `uvm_object` handle.
- *Q: Is UVM's default copy shallow or deep?* A: Deep for any field registered with
  `` `uvm_field_object `` (it recurses); fields not registered with field macros are
  not touched by `copy()`/`compare()` at all, which can masquerade as "shallow"
  behavior if forgotten.
- *Q: Why does `clone()` need `$cast`?* A: Its return type is the generic base class
  `uvm_object`, so a safe downcast is required to use it as your specific type.

## Key Takeaways
- Plain `=` assignment between class handles is aliasing, never a copy.
- `copy()` needs a pre-existing destination object; `clone()` creates one for you.
- Deep vs shallow depends on whether nested object fields are registered with
  `` `uvm_field_object `` — register them to get a true deep copy.
