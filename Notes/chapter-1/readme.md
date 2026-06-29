
# Chapter 1: SystemVerilog Prerequisites

## Everything You Must Know Before Touching UVM

---

## Chapter Overview

UVM is written entirely in SystemVerilog (SV). If you do not understand SystemVerilog's Object-Oriented Programming (OOP) concepts, UVM will seem confusing and difficult to follow.

This chapter covers the minimum SystemVerilog knowledge required before learning UVM.

---

## Learning Objectives

After completing this chapter, you will be able to:

- Define a class and instantiate an object
- Understand inheritance using `extends`
- Understand the purpose of `super.new()`
- Use packages and `import` correctly
- Use `` `include `` for macro/header files

---

# 1.1 Classes in SystemVerilog

## Theory

A **class** is a user-defined data type that combines:

- Data (properties/variables)
- Behavior (functions/tasks)

A class acts as a **blueprint**, while an object is an actual instance created from that blueprint.

In UVM:

- Driver = Class
- Monitor = Class
- Agent = Class
- Environment = Class
- Transaction = Class

Everything in UVM is class-based.

---

## Syntax

```systemverilog
class my_class;

    int data;

    function new();
        data = 0;
    endfunction

    task print_data();
        $display("data = %0d", data);
    endtask

endclass
```

### Object Creation

```systemverilog
module tb;

    my_class obj;

    initial begin
        obj = new();
        obj.print_data();
    end

endmodule
```

### Important Note

```systemverilog
my_class obj;
```

Only creates a **handle**.

```systemverilog
obj = new();
```

Actually creates the object.

Without `new()`, the handle points to `null`.

---

## Handle vs Object

| Handle | Object |
|----------|----------|
| Reference/Pointer | Actual memory allocation |
| Declared using class type | Created using `new()` |
| Can be null | Occupies memory |

Example:

```systemverilog
my_class obj;   // Handle only

obj.print_data(); // ERROR (null handle)

obj = new();      // Object created

obj.print_data(); // Works
```

---

# 1.2 Inheritance and `extends`

## Theory

Inheritance allows a child class to reuse all properties and methods of a parent class.

Relationship:

```text
Child IS-A Parent
```

Example:

```text
Dog IS-A Animal
Driver IS-A uvm_driver
Monitor IS-A uvm_monitor
```

UVM heavily relies on inheritance.

---

## Syntax

```systemverilog
class animal;

    string name;

    function new(string n);
        name = n;
    endfunction

    task speak();
        $display("%s says hello", name);
    endtask

endclass
```

### Child Class

```systemverilog
class dog extends animal;

    function new(string n);
        super.new(n);
    endfunction

    task fetch();
        $display("%s fetches the ball", name);
    endtask

endclass
```

---

## Why Use Inheritance?

Benefits:

- Code Reuse
- Reduced Coding Effort
- Easier Maintenance
- Supports Polymorphism
- Foundation of UVM Architecture

---

# 1.3 Understanding `super.new()`

## Theory

When a child object is created, the parent class must be initialized first.

This is done using:

```systemverilog
super.new(...)
```

It calls the constructor of the parent class.

### UVM Example

```systemverilog
class my_driver extends uvm_driver;

    function new(string path = "my_driver",
                 uvm_component parent = null);

        super.new(path,parent);

    endfunction

endclass
```

### Rule

Always place:

```systemverilog
super.new(...)
```

as the **first statement** inside the constructor.

---

# 1.4 Packages and `import`

## Theory

A package is a container used to store:

- Classes
- Functions
- Parameters
- Typedefs
- Enums

Packages help organize code and avoid naming conflicts.

### Example Package

```systemverilog
package my_pkg;

    class transaction;
        rand bit [3:0] data;
    endclass

endpackage
```

### Importing a Package

```systemverilog
import my_pkg::*;
```

Now all package contents become visible.

### UVM Package

The entire UVM library is stored inside:

```systemverilog
uvm_pkg
```

Import it before using any UVM class.

```systemverilog
import uvm_pkg::*;
```

---

# 1.5 `include` for Macro Files

## Theory

The backtick (`) indicates a compiler directive.

The directive:

```systemverilog
`include
```

copies the contents of another file into the current file during compilation.

### UVM Macro File

```systemverilog
uvm_macros.svh
```

contains:

```systemverilog
`uvm_info
`uvm_warning
`uvm_error
`uvm_fatal
`uvm_component_utils
`uvm_object_utils
```

### Syntax

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;
```

### Rule of Thumb

Always place these two lines at the top of every UVM file:

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;
```

---

# Include vs Import

| `include` | `import` |
|------------|------------|
| Copies file content | Makes package symbols visible |
| Used for macros/header files | Used for classes/functions |
| Compile-time text insertion | Namespace visibility |
| Example: `uvm_macros.svh` | Example: `uvm_pkg::*` |

---

# UVM Class Hierarchy

```text
                    uvm_void
                        |
                    uvm_object
                   /          \
                  /            \
        uvm_component     uvm_sequence_item
              |
    -------------------------
    |          |           |
 uvm_env  uvm_driver  uvm_monitor
                            |
                     Your Monitor
```

---

# Key Takeaways

- SystemVerilog classes are the foundation of UVM.
- A handle is not an object.
- Objects are created using `new()`.
- Inheritance is implemented using `extends`.
- Always call `super.new()` first.
- Use packages for sharing declarations.
- Import UVM using:

```systemverilog
import uvm_pkg::*;
```

- Include UVM macros using:

```systemverilog
`include "uvm_macros.svh"
```

---

# Interview Questions

### 1. What is the difference between a class handle and an object?

A handle is a reference to an object, while an object is the actual allocated memory created using `new()`.

### 2. Why is `super.new()` required?

It initializes the parent class before the child class starts initialization.

### 3. What is the difference between `include` and `import`?

`include` copies file contents into the current file, while `import` makes package members visible.

### 4. Why do we import `uvm_pkg`?

Because all UVM classes are defined inside `uvm_pkg`.

### 5. Why is `uvm_macros.svh` included?

To access macros such as:

```systemverilog
`uvm_info
`uvm_error
`uvm_warning
`uvm_component_utils
```

---

## Final Note

**If you understand Classes, Objects, Inheritance, `super.new()`, Packages, and Macros, you are ready to start learning UVM.**
