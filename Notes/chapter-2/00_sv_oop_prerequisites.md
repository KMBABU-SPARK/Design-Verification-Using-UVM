# Chapter 0 — Prerequisites: SystemVerilog OOP You Need Before UVM


## Chapter Overview
A 5-minute primer on SystemVerilog class syntax, constructors, handles vs. objects,
`rand`, and `$cast` — the four building blocks every `uvm_object` example reuses.

## Learning Objectives
- Declare a `class`, instantiate it, and tell the difference between a *handle* and
  an *object*.
- Write a constructor (`function new`) and know why `super.new()` must be called first.
- Understand `rand` variables and the `randomize()` method.
- Understand `$cast` and why UVM uses it everywhere instead of a plain assignment.

## Theory Explanation

### 1. Classes, handles, and objects
A `class` is a blueprint. `new()` allocates a real object in memory and returns a
**handle** (a reference) to it. A variable of class type is just a handle — it can be
`null`, or it can point to an object.

```
class_var  ----points to---->  [ actual object in memory ]
   (handle)                          (allocated by new())
```

Two handles can point to the *same* object (this is exactly what "shallow copy"
means later in Chapter 4).

### 2. Constructors and `super.new()`
Every class has an implicit or explicit constructor called `new()`. When a class
*extends* another class, the child's `new()` must call `super.new()` **first**, so the
parent class can initialize its own internal state before the child adds its own.
`uvm_object` and `uvm_component` rely on their internal state (like the object's name)
being set up by `super.new(name)` — skip it and the object is broken.

### 3. `rand` and `randomize()`
Declaring a variable `rand` makes it eligible for randomization. Calling
`object.randomize()` assigns it a new legal random value (respecting bit-width,
unless constraints restrict it). This is the primary way UVM generates stimulus.

### 4. `$cast` — safe type conversion
SystemVerilog will not silently allow you to assign a **base-class handle to a
derived-class variable** (downcasting) — you must use `$cast(dest, src)`. It returns
1 on success, 0 on failure (e.g. wrong type), and is heavily used with `clone()`
because `clone()` returns a generic `uvm_object` handle that must be cast back to
the specific class.

```systemverilog
uvm_object generic_handle;
my_class   specific_handle;
$cast(specific_handle, generic_handle);   // safe downcast
```

## Architecture Diagram (Handle vs Object)
```
 declare:        first f;            // f = handle, currently null
 construct:       f = new("first");   // allocates object, f now points to it
                  
   f ───────► ┌─────────────────┐
              │  first object   │
              │  data = 4'bXXXX │
              └─────────────────┘
```

## Common Errors and Debugging Tips
| Mistake | Symptom | Fix |
|---|---|---|
| Forgetting `super.new()` | Object name/parent not set, prints look wrong | Always call `super.new(name)` as the first line |
| Assigning base handle to derived variable directly | Compile error: "illegal assignment" | Use `$cast()` |
| Calling methods on a `null` handle | Runtime crash / "null object access" | Always `new()` (or factory-`create()`) before use |
| Forgetting `rand` keyword | `randomize()` doesn't touch that field | Mark every field that needs randomization as `rand` |

## Key Takeaways
- A class variable is a handle, not the object itself.
- `super.new()` must run before a child class does its own setup.
- `rand` + `randomize()` is how UVM generates stimulus.
- `$cast` is the safe way to convert between class types — you'll see it in nearly
  every clone/copy example.
