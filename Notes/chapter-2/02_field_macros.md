# Chapter 2 — UVM Field Macros (Automation Engine for print/copy/compare)

## Chapter Overview
Field macros are the single biggest productivity feature of `uvm_object`. This
chapter covers every field-macro variant seen in the source material: `int`,
`enum`, `string`, `real`, `object` (nesting), and the four array kinds.

## Learning Objectives
- Explain what `` `uvm_object_utils_begin/end `` actually generates.
- Use the correct field macro for int, enum, string, real, nested object, and each
  array type.
- Understand the FLAG argument (`UVM_DEFAULT`, `UVM_NOPRINT`, `UVM_BIN`, `UVM_DEC`, etc.)
- Know what breaks if you forget to register a field.

## Theory Explanation

### Why field macros exist
Without field macros, to support `print()`, `copy()`, `compare()`, and `pack()` for a
class with 10 fields, you'd write ~40 lines of repetitive code (one block per method
per field). Field macros let you declare "this field participates in automation" in
**one line**, and UVM auto-generates the rest under the hood (technically: they
populate UVM's internal field-automation table, used by the default `do_print`,
`do_copy`, `do_compare`, etc. implementations inherited from `uvm_object`).

### Syntax skeleton
```systemverilog
class my_class extends uvm_object;
  ... fields ...

  `uvm_object_utils_begin(my_class)
    `uvm_field_<type>(field_name, FLAGS)
    ... one line per field ...
  `uvm_object_utils_end
endclass
```
`` `uvm_object_utils_begin/end `` replaces the simpler `` `uvm_object_utils `` macro
from Chapter 1 — use `_begin/_end` whenever you also list field macros inside.

### Field macro catalogue (from the source material)
| Macro | Purpose |
|---|---|
| `` `uvm_field_int(ARG, FLAG) `` | integer / bit-vector fields |
| `` `uvm_field_enum(T, ARG, FLAG) `` | enum-typed fields (`T` = enum type name) |
| `` `uvm_field_string(ARG, FLAG) `` | `string` fields |
| `` `uvm_field_real(ARG, FLAG) `` | `real` (floating point) fields |
| `` `uvm_field_object(ARG, FLAG) `` | a field that is itself a `uvm_object` (nesting) |
| `` `uvm_field_sarray_int(ARG, FLAG) `` | static array of ints |
| `` `uvm_field_array_int(ARG, FLAG) `` | dynamic array of ints |
| `` `uvm_field_queue_int(ARG, FLAG) `` | queue of ints |
| `` `uvm_field_aa_int_int(ARG, FLAG) `` | associative array (int-keyed, int-valued) |

> Official reference (per the source PDF):
> verificationacademy.com — UVM `uvm_object_defines.svh` macro docs.

### FLAG argument
The FLAG controls *how* the field participates: `UVM_DEFAULT` enables all
operations (print/copy/compare/pack) with default formatting; `UVM_NOPRINT`
excludes the field from `print()` output (but it still participates in copy/compare);
radix flags like `UVM_BIN`/`UVM_DEC`/`UVM_HEX` control the **display** format; flags
can be OR'd together, e.g. `UVM_NOPRINT | UVM_BIN`.

## Architecture Diagram
```
        field macros (declarative)
              │
              ▼
   UVM field-automation table (internal, per-class)
              │
   ┌──────────┼──────────┬───────────┐
   ▼          ▼          ▼           ▼
print()     copy()    compare()    pack()/unpack()
 (auto-generated default behavior for every registered field)
```

## Code Examples from Source

### ex02 — int fields
`source_code/ex02_field_macros_int.sv`
```systemverilog
rand bit [3:0] a;
rand bit [7:0] b;

`uvm_object_utils_begin(obj)
  `uvm_field_int(a, UVM_NOPRINT | UVM_BIN)
  `uvm_field_int(b, UVM_DEFAULT | UVM_DEC)
`uvm_object_utils_end
```
**Explanation:** `a` is registered but will be *hidden from print()* (`UVM_NOPRINT`)
while still being copyable/comparable; if it were printed it would show in binary.
`b` prints in decimal by default. Calling `o.print(uvm_default_table_printer)`
displays only `b` because `a` was suppressed.

### ex03 — enum, string, real
`source_code/ex03_field_macros_enum_string_real.sv`
```systemverilog
typedef enum bit [1:0] {s0, s1, s2, s3} state_type;
rand state_type state;
real   temp = 12.34;
string str  = "UVM";

`uvm_object_utils_begin(obj)
  `uvm_field_enum(state_type, state, UVM_DEFAULT)
  `uvm_field_string(str, UVM_DEFAULT)
  `uvm_field_real(temp, UVM_DEFAULT)
`uvm_object_utils_end
```
**Note the enum macro signature** — it needs the *type name* (`state_type`) as the
first argument, unlike int/string/real which only need the field name. This is a
common source of compile errors for beginners.

### ex04 — nested object field
`source_code/ex04_field_macros_object_nested.sv`
```systemverilog
class parent extends uvm_object;
  rand bit [3:0] data;
  `uvm_object_utils_begin(parent)
    `uvm_field_int(data, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

class child extends uvm_object;
  parent p;
  function new(string path = "child");
    super.new(path);
    p = new("parent");          // must construct nested object in constructor!
  endfunction
  `uvm_object_utils_begin(child)
    `uvm_field_object(p, UVM_DEFAULT)
  `uvm_object_utils_end
endclass
```
**Why this matters:** `` `uvm_field_object `` tells UVM "when you print/copy/compare
`child`, recurse into `p` too." This is how `c.print()` shows the hierarchy
("p.data: ...") instead of just an opaque handle. The nested object **must be
constructed** (`new()`) before use — declaring `parent p;` alone only creates a null
handle.

### ex05 — arrays
`source_code/ex05_field_macros_arrays.sv`
```systemverilog
int arr1[3]  = {1,2,3};   // static
int arr2[];               // dynamic
int arr3[$];               // queue
int arr4[int];             // associative

`uvm_object_utils_begin(array)
  `uvm_field_sarray_int(arr1, UVM_DEFAULT)
  `uvm_field_array_int(arr2, UVM_DEFAULT)
  `uvm_field_queue_int(arr3, UVM_DEFAULT)
  `uvm_field_aa_int_int(arr4, UVM_DEFAULT)
`uvm_object_utils_end
```
The macro name encodes the array kind — `sarray` (static), `array` (dynamic),
`queue`, `aa_<key>_<value>` (associative, key type then value type). Get the macro
type wrong for the array declaration and the code won't compile.

## Common Errors and Debugging Tips
| Mistake | Symptom | Fix |
|---|---|---|
| Using `` `uvm_field_int `` on an enum | Compile/elaboration error | Use `` `uvm_field_enum(type, field, flag) `` |
| Forgetting to `new()` a nested object before use | Null-handle crash on `randomize()`/access | Always construct nested objects in the constructor |
| Mismatched array macro vs array declaration (e.g. `array_int` on a static array) | Compile error or wrong print output | Match macro suffix to array kind exactly |
| Using `UVM_NOPRINT` but expecting the field to also be excluded from copy/compare | Field still gets copied/compared, just not printed | `UVM_NOPRINT` ONLY affects `print()` |

## Interview-Level Points
- *Q: What's the difference between `` `uvm_object_utils `` and
  `` `uvm_object_utils_begin/_end ``?* A: The plain version just registers the class
  with the factory; the begin/end pair additionally lets you list field macros for
  automation.
- *Q: How does `` `uvm_field_object `` differ from the others?* A: It tells UVM the
  field is itself a `uvm_object`, so print/copy/compare should **recurse** into it
  rather than treat it as a scalar.
- *Q: What does the FLAG argument actually control?* A: Which operations the field
  participates in (print/copy/compare/pack), and display radix for print.

## Key Takeaways
- Field macros are declarative shortcuts that auto-generate print/copy/compare logic.
- Pick the macro that matches the field's **type**, not just its size.
- `UVM_NOPRINT` hides a field from `print()` only — it still copies/compares.
- Nested `uvm_object` fields need `` `uvm_field_object `` AND must be constructed
  in the owning class's constructor.
