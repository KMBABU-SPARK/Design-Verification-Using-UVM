# Chapter 5 — The Factory in Practice: `create()` and Type Override

## Chapter Overview
Returns to the factory concept introduced in Chapter 1 and shows it in action:
`type_id::create()` vs plain `new()`, and how `set_type_override_by_type()` lets you
substitute one class for another without touching existing code — the actual
*point* of using the factory.

## Learning Objectives
- Explain why `type_id::create()` is preferred over `new()` in real testbenches.
- Use `set_type_override_by_type()` to override a base class with a derived class.
- Trace what happens when an override is in effect.

## Theory Explanation

### `new()` vs `create()`
```systemverilog
f1 = new("f1");                       // direct construction — factory bypassed
f1 = first::type_id::create("f1");    // factory-based — overridable
```
Both produce a working object in the simple case. The difference only matters when
someone, somewhere, has installed a **factory override**. `new()` always builds
*exactly* the class you named in the code. `create()` asks the factory "what should
I actually build when someone requests `first`?" — and the factory may answer with
a different (derived) class if an override is registered.

### Why is this useful?
Without changing a single line inside `comp`'s implementation, you can globally
swap `first` for an extended version `first_mod` everywhere `comp` would have
created a `first`. This is invaluable for: injecting error scenarios, extending
behavior in regression-specific tests, or layering verification IP without
modifying the original (possibly vendor-supplied) code.

### Override types
- `set_type_override_by_type(original_type, override_type)` — global override,
  applies everywhere that type is requested.
- (Not shown in source, but standard UVM) `set_inst_override_by_type(...)` —
  applies only to a specific instance path.

## Code Examples from Source

### ex10 — create()
`source_code/ex10_create_method.sv`
```systemverilog
first f1, f2;
initial begin
  f1 = first::type_id::create("f1");
  f2 = first::type_id::create("f2");
  f1.randomize();
  f2.randomize();
  f1.print();
  f2.print();
end
```
This behaves identically to using `new()` **when no override is registered** — the
benefit only shows up once you add an override, as in ex11.

### ex11 — factory override
`source_code/ex11_factory_override.sv`
```systemverilog
class first extends uvm_object;
  rand bit [3:0] data;
  `uvm_object_utils_begin(first)
    `uvm_field_int(data, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

class first_mod extends first;        // derived class, adds a field
  rand bit ack;
  `uvm_object_utils_begin(first_mod)
    `uvm_field_int(ack, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

class comp extends uvm_component;
  `uvm_component_utils(comp)
  first f;
  function new(string path = "second", uvm_component parent = null);
    super.new(path, parent);
    f = first::type_id::create("f");   // <-- factory decides actual type
    f.randomize();
    f.print();
  endfunction
endclass

module tb;
  comp c;
  initial begin
    c.set_type_override_by_type(first::get_type(), first_mod::get_type());
    c = comp::type_id::create("comp", null);
  end
endmodule
```
**Line-by-line:**
- `first_mod extends first` — a derived class adding the `ack` field, registered
  independently with its own field macros.
- `comp` (a `uvm_component`, briefly introduced here as the structural container)
  creates a `first` via `create()` **inside its own constructor**.
- In `tb`, `c.set_type_override_by_type(first::get_type(), first_mod::get_type())`
  registers the override *before* `comp` itself is constructed.
- `c = comp::type_id::create(...)` then triggers `comp`'s constructor, which calls
  `first::type_id::create("f")` — but because of the override, the factory actually
  builds a `first_mod` object instead. `f.print()` inside `comp` would then show the
  extra `ack` field, proving the substitution worked.

> **Note on example ordering:** the original code calls
> `c.set_type_override_by_type(...)` on `c` **before** `c` has been constructed
> (`c` is still `null` at that point). In practice, factory override methods are
> `static`-like and are typically called via the class name or singleton accessor
> (e.g. `first::type_id::set_type_override(...)` or
> `uvm_factory::get().set_type_override_by_type(...)`) rather than through an
> uninitialized component handle. Treat this example as illustrating the *concept*
> of override; double-check exact call syntax against your UVM version's LRM.

## Common Errors and Debugging Tips
| Mistake | Symptom | Fix |
|---|---|---|
| Using `new()` in a testbench that relies on factory overrides | Override silently has no effect | Always use `type_id::create()` for objects/components that might be overridden |
| Registering the override AFTER the original object is already created | Override has no effect on already-created objects | Register overrides early — typically in `build_phase` of a top-level test |
| Forgetting to register the derived class with its own `` `uvm_object_utils `` | Factory can't create it, override fails | Every class participating in the factory needs its own registration |

## Interview-Level Points
- *Q: Why use `create()` over `new()`?* A: Only `create()` goes through the factory,
  enabling type/instance overrides without modifying existing code — a key UVM
  reusability mechanism.
- *Q: What's the difference between type override and instance override?* A: Type
  override replaces a class everywhere; instance override replaces it only at one
  specific hierarchical path.
- *Q: What problem does the factory solve in verification?* A: Reusing a base
  testbench/VIP while injecting custom behavior (e.g. error injection, extended
  transactions) without editing the original source.

## Key Takeaways
- `type_id::create()` is the factory-aware way to construct UVM objects/components.
- Factory overrides let you substitute a derived class for a base class globally,
  without touching existing code — the core value proposition of UVM's factory.
- Always register overrides before the affected objects get created.
