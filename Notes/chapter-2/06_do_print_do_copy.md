# Chapter 6 — Customizing Behavior: `do_print()`, `convert2string()`, `do_copy()`

## Chapter Overview
Field macros (Chapter 2) cover most cases automatically, but sometimes you need
custom formatting or custom copy logic. This chapter covers the three "do_*"/
helper virtual methods UVM lets you override directly, bypassing field-macro
automation.

## Learning Objectives
- Override `do_print()` to manually control printed output using a `uvm_printer`.
- Override `convert2string()` to build a custom one-line summary string.
- Override `do_copy()` to control field-by-field copy logic manually.
- Know when to use manual overrides vs. field macros.

## Theory Explanation

### Why override these at all if field macros already exist?
Field macros are great for simple, uniform cases. But sometimes you need: custom
formatting logic, computed/derived display values, selective copying based on
conditions, or fields that field macros simply don't support well. UVM's
`do_print`/`do_copy`/`do_compare`/`convert2string` are the **escape hatch**: every
`uvm_object` method like `print()` is a thin wrapper that calls the corresponding
`do_*` virtual method, which you can override.

```
 print()  ──calls──►  do_print(printer)   (you override this)
 copy()   ──calls──►  do_copy(rhs)         (you override this)
 compare()──calls──►  do_compare(rhs, ...)  (not shown in source, same pattern)
 (custom one-liner) convert2string()        (you override this directly)
```

**Always call `super.do_print(printer)` / `super.do_copy(rhs)` first** inside your
override, so any fields still registered via field macros are still handled
automatically — your override only needs to add what's extra/custom.

### `do_print(uvm_printer printer)`
The `printer` object exposes typed helper methods: `print_field_int`,
`print_string`, `print_real`, `print_object`, etc. — each takes a name, value, and
formatting options, and appends a line to the eventual printed report.

### `convert2string()`
Returns a single `string` summarizing the object — handy for compact one-line
`` `uvm_info `` messages instead of the (often verbose) multi-line `print()` table
output.

### `do_copy(uvm_object rhs)`
Receives the source object as a generic `uvm_object` — you must `$cast` it to your
specific type before accessing its fields, then manually assign each field from
`temp` to `this`.

## Code Examples from Source

### ex12 — do_print() override
`source_code/ex12_do_print_override.sv`
```systemverilog
bit [3:0] a = 4;
string    b = "UVM";
real      c = 12.34;

virtual function void do_print(uvm_printer printer);
  super.do_print(printer);                       // keep base-class behavior
  printer.print_field_int("a", a, $bits(a), UVM_HEX);
  printer.print_string("b", b);
  printer.print_real("c", c);
endfunction
```
**Line-by-line:** because these fields are plain (no `` `uvm_field_* `` macros used
here at all), `print()` would show nothing for them by default. The manual
`do_print()` override is the *only* thing making them appear, with `a` explicitly
shown in hex via `UVM_HEX`.

### ex13 — convert2string() override
`source_code/ex13_convert2string_override.sv`
```systemverilog
virtual function string convert2string();
  string s = super.convert2string();
  s = {s, $sformatf("a : %0d ", a)};
  s = {s, $sformatf("b : %0s ", b)};
  s = {s, $sformatf("c : %0f ", c)};
  // result e.g: "a : 4 b : UVM c : 12.3400 "
  return s;
endfunction
```
Used later as:
```systemverilog
`uvm_info("TB_TOP", $sformatf("%0s", o.convert2string()), UVM_NONE);
```
**Why this is useful:** a single-line log entry is often easier to scan than a
multi-line `print()` table, especially in high-volume simulation logs.

### ex14 — do_copy() override
`source_code/ex14_do_copy_override.sv`
```systemverilog
virtual function void do_copy(uvm_object rhs);
  obj temp;
  $cast(temp, rhs);          // rhs arrives as generic uvm_object; cast it back
  super.do_copy(rhs);         // let base class copy any field-macro fields too
  this.a = temp.a;
  this.b = temp.b;
endfunction
```
**Line-by-line:** `$cast(temp, rhs)` recovers the specific type so `temp.a`/`temp.b`
are accessible. `super.do_copy(rhs)` is called for safety/consistency even though,
in this particular class, no field macros are used. Then each field is explicitly
copied.

## Common Errors and Debugging Tips
| Mistake | Symptom | Fix |
|---|---|---|
| Forgetting `super.do_print()`/`super.do_copy()` inside the override | Fields handled by field macros silently disappear from output/copy | Always call `super.*` first inside a `do_*` override |
| Forgetting `$cast` in `do_copy()` | Compile error (rhs is generic `uvm_object`) | Always `$cast` rhs into a local typed variable first |
| Mixing field macros AND manual `do_print` for the same field | Duplicate or conflicting print lines | Pick one mechanism per field — don't double-register |

## Interview-Level Points
- *Q: When would you override `do_print()` instead of just using field macros?*
  A: When you need custom formatting, computed/derived values, or fields that
  field macros can't express cleanly.
- *Q: Why must `do_copy()` use `$cast`?* A: Its parameter type is the generic
  `uvm_object`, since `copy()` must work polymorphically across all UVM objects.
- *Q: What's the relationship between `print()` and `do_print()`?* A: `print()` is
  the public entry point; it internally invokes the virtual `do_print()`, which you
  can override — classic template-method pattern.

## Key Takeaways
- `do_print`, `do_copy`, `convert2string` (and `do_compare`, not shown here) are
  the manual escape hatches behind UVM's automatic field-macro behavior.
- Always call the `super.*` version first inside an override to preserve
  field-macro-driven behavior for any fields still using macros.
- `convert2string()` is ideal for compact log messages; `do_print()` is for full
  structured `print()` output.
