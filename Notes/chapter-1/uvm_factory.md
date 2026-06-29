# Chapter 5: UVM Factory and `uvm_component_utils`
### Registration, Creation, and Override

---

## Chapter Overview

The UVM factory is one of the most important concepts in the entire
framework. It is the mechanism that makes testbenches *overridable* —
letting you substitute one component type for another at runtime
without modifying any source code. Every class you saw in Chapter 4
used `` `uvm_component_utils `` — this chapter explains exactly what
that macro does and why it matters.

---

## Learning Objectives

After this chapter you will be able to:
- Explain what the UVM factory is and the problem it solves
- Understand what `` `uvm_component_utils `` registers
- Understand what `` `uvm_object_utils `` registers
- Use `type_id::create()` instead of `new()` for factory-aware creation
- Explain factory overrides at the interview level

---

## 5.1 The Problem: Hard-Coded Class Names

Without a factory, to replace a `driver` with an `error_driver`
(a modified version for corner-case testing), you would need to:
1. Open the environment source file
2. Change `driver drv = new(...)` to `error_driver drv = new(...)`
3. Recompile the entire testbench

If the environment is in a shared library (like a VIP), you cannot
edit it at all. This is the problem the factory solves.

---

## 5.2 What Is the UVM Factory?

The UVM factory is a **centralized registry** that maps class names
(strings) to their types. When you ask the factory to "create a driver",
it looks up the current registered type for `driver` and creates that.

If you have registered an override — "whenever anyone asks for a driver,
give them an error_driver instead" — the factory silently returns an
`error_driver` object without the caller knowing.

```
  Factory Registry (internal table)
  ──────────────────────────────────
  "driver"       → driver class
  "monitor"      → monitor class
  "env"          → env class
  ... (overridable at runtime)
```

---

## 5.3 `` `uvm_component_utils `` — What It Does

### Syntax

```systemverilog
class driver extends uvm_driver;
    `uvm_component_utils(driver)   // ← this line
    ...
endclass
```

This single macro expands into several lines of boilerplate that:
1. Register the `driver` type with the UVM factory under the string `"driver"`
2. Implement the `get_type()`, `create()`, `get_type_name()` methods
3. Make `driver::type_id::create(...)` work

### In Plain English

> "Hey UVM factory, my class `driver` exists. Please keep track of it
> so anyone can create it by name, and so it can be overridden."

---

## 5.4 Two Registration Macros

| Macro | Used For |
|-------|----------|
| `` `uvm_component_utils(T) `` | Classes that extend `uvm_component` (persistent testbench components) |
| `` `uvm_object_utils(T) `` | Classes that extend `uvm_object` (transient things like sequence items, transactions) |

Rule: If your class extends `uvm_component` (or driver, monitor, env,
etc.) → use `` `uvm_component_utils ``.
If your class extends `uvm_object` (or sequence_item, sequence, etc.)
→ use `` `uvm_object_utils ``.

---

## 5.5 Factory-Aware Creation: `type_id::create()`

Once a class is registered with the factory, you should create it with
the factory's `create` method, not with `new()` directly:

```systemverilog
// Without factory (hard-coded, not overridable)
drv = new("DRV", this);

// With factory (overridable at runtime)
drv = driver::type_id::create("DRV", this);
```

The factory-aware call goes through the registry, so overrides apply.
The direct `new()` call bypasses the factory entirely.

---

## 5.6 Factory Override — The Payoff

Suppose you have written a baseline driver and now want to test with
a slightly different one for a corner case, without modifying the
environment:

```systemverilog
class error_driver extends driver;
    `uvm_component_utils(error_driver)
    ...
endclass

module tb;
    env e;
    initial begin
        // Tell factory: everywhere driver is requested, give error_driver
        driver::type_id::set_type_override(error_driver::get_type());

        e = env::type_id::create("ENV", null);
        // When env creates drv = driver::type_id::create(...)
        // the factory returns an error_driver instead
    end
endmodule
```

No modification to `env` or `driver` was needed. This is the power
of the factory pattern.

---

## 5.7 Architecture Diagram: Factory Flow

```
  Test says:
  driver::type_id::create("DRV", this)
              │
              ▼
    ┌─────────────────┐
    │  UVM Factory    │
    │  Registry       │
    │                 │
    │  "driver" → ?   │
    │                 │
    │  Override set?  │
     YES → error_driver
    │  NO  → driver   │
    └────────┬────────┘
             │
             ▼
    Returns object of correct type
    (caller doesn't know which)
```

---

## 5.8 What Happens Without `uvm_component_utils`?

If you forget the macro, several things break:
1. `type_id::create()` does not exist on your class
2. Factory overrides cannot target your class
3. UVM's built-in automation (copy, print, compare) is not available

The simulation may still run if you use `new()` directly, which is why
beginners sometimes miss this — but the testbench is no longer
factory-compliant and cannot be overridden.

---

## Common Errors and Debugging Tips

| Error | Cause | Fix |
|-------|-------|-----|
| `type_id` not defined | Missing `uvm_component_utils` | Add the macro right after the class declaration |
| Wrong macro used | Used `uvm_object_utils` on a component | Match: component→`uvm_component_utils`, object→`uvm_object_utils` |
| Override not working | Creating with `new()` instead of `type_id::create()` | Switch to factory-aware creation |
| `get_type_name()` returns wrong string | Class re-named but macro argument not updated | Keep macro argument in sync with class name |

---

## Key Takeaways

- The UVM factory is a registry that decouples class creation from class names.
- `` `uvm_component_utils(T) `` registers type T with the factory — always include it.
- Use `T::type_id::create("name", parent)` instead of `new()` for factory-aware creation.
- Factory overrides let you substitute components at runtime without source changes.
- `uvm_component_utils` is for components; `uvm_object_utils` is for objects/transactions.

---

## Interview Questions

1. What does `` `uvm_component_utils `` do?
2. What is the difference between `new()` and `type_id::create()`?
3. Why would you use a factory override?
4. What is the difference between `` `uvm_component_utils `` and `` `uvm_object_utils ``?
5. What breaks if you forget to add `` `uvm_component_utils `` to your class?
