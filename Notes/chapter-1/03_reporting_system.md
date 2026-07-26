# Chapter 3: UVM Reporting System
### `uvm_info`, Verbosity, Severity, Actions, and Log Files

---

## Chapter Overview

The UVM reporting system is the first practical UVM feature every
beginner encounters. It replaces `$display` with a structured messaging
system that supports filtering by verbosity, routing to files, changing
severity, and controlling simulation behavior on errors.

---

## Learning Objectives

After this chapter you will be able to:
- Use all four UVM message macros correctly
- Explain what verbosity levels are and how to control them
- Override severity and actions programmatically
- Route UVM messages to a log file
- Debug common reporting-related mistakes

---

## 3.1 The Four UVM Message Macros

### Theory

Plain `$display` has no structure. You cannot filter it, count errors
from it, or stop simulation based on it. UVM's four macros solve all of
these problems.

### Syntax

```
`uvm_info   (id, message, verbosity_level)
`uvm_warning(id, message)
`uvm_error  (id, message)
`uvm_fatal  (id, message)
```

| Macro          | Default Behaviour                                        |
|----------------|----------------------------------------------------------|
| `uvm_info      | Prints if current verbosity ≥ specified level            |
| `uvm_warning   | Always prints; marks message as WARNING                  |
| `uvm_error     | Always prints; increments error count; sim continues     |
| `uvm_fatal     | Always prints; **stops simulation immediately**          |

### Arguments

- **id** — a string label (like a category tag) showing the source.
  Convention: use the class name or a short uppercase path
  (e.g., `"DRV"`, `"TB_TOP"`, `"MON"`).
- **message** — the string to print. Use `$sformatf()` to embed values.
- **verbosity_level** (info only) — controls whether the message
  appears at all (see Section 3.2).

### Code Example — Basic Usage (from document)

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

module tb;
    int data = 56;
    initial begin
        `uvm_info("TB_TOP", $sformatf("Value of data : %0d", data), UVM_NONE);
    end
endmodule
```

#### Line-by-Line Explanation

| Line | Explanation |
|------|-------------|
| `` `include "uvm_macros.svh" `` | Paste in all macro definitions |
| `import uvm_pkg::*;` | Import all UVM class names |
| `int data = 56;` | A plain SV integer variable |
| `` `uvm_info(...) `` | Print an info message |
| `"TB_TOP"` | ID tag: identifies where in the TB this came from |
| `$sformatf(...)` | Formats a string with the variable value (like sprintf) |
| `UVM_NONE` | Verbosity = 0 — always prints regardless of filter level |

### Output Format

UVM automatically prefixes messages with metadata:
```
UVM_INFO tb.sv(7) @ 0: reporter [TB_TOP] Value of data : 56
          ^path  ^line ^time      ^id      ^your message
```

---

## 3.2 Verbosity Levels

### Theory

Verbosity lets you decide **how much** output you want during a run.
In a large testbench, dozens of components emit messages every cycle.
If all of them always printed, logs would be gigabytes. Verbosity
filtering solves this.

### Verbosity Level Constants

```
UVM_NONE    = 0      // Always prints — use for critical messages
UVM_LOW     = 100    // Low-detail messages
UVM_MEDIUM  = 200    // Default filter level — default if not changed
UVM_HIGH    = 300    // Detailed debug messages
UVM_FULL    = 400    // Very verbose (trace-level)
UVM_DEBUG   = 500    // Maximum detail
```

### How Filtering Works

```
Message verbosity ≤ Current filter level  →  PRINTED
Message verbosity >  Current filter level →  SUPPRESSED
```

Default filter = UVM_MEDIUM (200). So:
- `uvm_info(..., UVM_LOW)`    → always printed  (100 ≤ 200) ✓
- `uvm_info(..., UVM_MEDIUM)` → printed          (200 ≤ 200) ✓
- `uvm_info(..., UVM_HIGH)`   → suppressed       (300 > 200) ✗

### Setting Verbosity — Three Scopes

#### (a) Global — entire simulation

```systemverilog
uvm_top.set_report_verbosity_level(UVM_HIGH);
```

#### (b) Per-object — only that instance

```systemverilog
drv.set_report_verbosity_level(UVM_HIGH);
```

#### (c) Hierarchically — object and all its children

```systemverilog
e.set_report_verbosity_level_hier(UVM_HIGH);
```

### Architecture Diagram: Verbosity Filtering

```
  Your Code                      Filter (set_report_verbosity_level)
  ─────────                      ────────────────────────────────────
  `uvm_info("X","msg",UVM_HIGH)
         │
         ▼
  Is 300 ≤ current_level ?
         │               │
        YES              NO
         │               │
         ▼               ▼
      PRINT          SUPPRESS
```

---

## 3.3 Verbosity Examples from Document

### Example 1 — Global Verbosity Override

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

module tb;
    initial begin
        uvm_top.set_report_verbosity_level(UVM_HIGH);   // (A)

        $display("Default Verbosity level : %0d",
                 uvm_top.get_report_verbosity_level());  // (B)

        `uvm_info("TB_TOP", "String", UVM_HIGH);         // (C)
    end
endmodule
```

| Label | Explanation |
|-------|-------------|
| (A) | Raises the global filter to UVM_HIGH (300). Now HIGH messages pass. |
| (B) | `get_report_verbosity_level()` returns the current filter as an integer. Useful for debugging. |
| (C) | This `uvm_info` uses UVM_HIGH. Without line (A) it would be suppressed; with it, it prints. |

**Note from document:**
> "Generally it is at UVM_MEDIUM level (200). If the set command is not
> called, `uvm_info` with UVM_HIGH will not be printed because 300 > 200."

### Example 2 — Per-Object Verbosity

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

class driver extends uvm_driver;
    `uvm_component_utils(driver)

    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction

    task run();
        `uvm_info("DRV1", "Executed Driver1 Code", UVM_HIGH);
        `uvm_info("DRV2", "Executed Driver2 Code", UVM_HIGH);
    endtask
endclass

class env extends uvm_env;
    `uvm_component_utils(env)

    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction

    task run();
        `uvm_info("ENV1", "Executed ENV1 Code", UVM_HIGH);
        `uvm_info("ENV2", "Executed ENV2 Code", UVM_HIGH);
    endtask
endclass

module tb;
    driver drv;
    env e;

    initial begin
        drv = new("DRV", null);
        e   = new("ENV", null);

        drv.set_report_verbosity_level(UVM_HIGH);  // ← only driver gets HIGH
        // e verbosity stays at default MEDIUM — ENV messages suppressed

        drv.run();
        e.run();
    end
endmodule
```

**Result:** Only DRV1 and DRV2 messages print. ENV1 and ENV2 are
suppressed because `e`'s verbosity level was never raised.

---

## 3.4 Hierarchical Verbosity (`set_report_verbosity_level_hier`)

### Theory

When you set verbosity on a parent object using the `_hier` variant,
it propagates automatically to all children. This is crucial in real
testbenches where an environment contains dozens of sub-components.

### Example 3 — Hierarchical Verbosity (from document)

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

class driver extends uvm_driver;
    `uvm_component_utils(driver)
    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction
    task run();
        `uvm_info("DRV", "Executed Driver Code", UVM_HIGH);
    endtask
endclass

class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)
    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction
    task run();
        `uvm_info("MON", "Executed Monitor Code", UVM_HIGH);
    endtask
endclass

class env extends uvm_env;
    `uvm_component_utils(env)
    driver  drv;
    monitor mon;

    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction

    task run();
        drv = new("DRV", this);   // 'this' = env is the parent
        mon = new("MON", this);
        drv.run();
        mon.run();
    endtask
endclass

module tb;
    env e;
    initial begin
        e = new("ENV", null);
        e.set_report_verbosity_level_hier(UVM_HIGH);  // ← propagates to drv AND mon
        e.run();
    end
endmodule
```

**Key insight:** By calling `set_report_verbosity_level_hier` on `e`,
both `drv` and `mon` inside it get UVM_HIGH verbosity automatically.
You do not need to call it on each child individually.

---

## 3.5 Severity Override

### Theory

Severity override changes the severity classification of a message at
runtime, without touching the source code. This is used when you want
to temporarily downgrade a `uvm_fatal` to a `uvm_error` during bring-up.

### Two Flavors

```systemverilog
// 1. All FATAL messages from this object become ERROR
d.set_report_severity_override(UVM_FATAL, UVM_ERROR);

// 2. Only FATAL messages with ID "DRV" from this object become ERROR
d.set_report_severity_id_override(UVM_FATAL, "DRV", UVM_ERROR);
```

---

## 3.6 Severity Actions

### Theory

A **severity action** controls what *happens* when a message fires.
It does NOT change the severity itself (that is `severity_override`).
Actions are bitmask flags:

| Flag          | Meaning                                         |
|---------------|-------------------------------------------------|
| `UVM_DISPLAY` | Print to console                                |
| `UVM_LOG`     | Write to log file                               |
| `UVM_COUNT`   | Increment the error counter                     |
| `UVM_EXIT`    | Stop simulation immediately                     |
| `UVM_NO_ACTION` | Do nothing                                   |

You combine them with `|`:

```systemverilog
// INFO messages: print AND exit
d.set_report_severity_action(UVM_INFO, UVM_DISPLAY | UVM_EXIT);

// FATAL messages: only print, don't exit
d.set_report_severity_action(UVM_FATAL, UVM_DISPLAY);
```

### Max Quit Count

Stop simulation after a certain number of errors accumulate:

```systemverilog
d.set_report_max_quit_count(3);  // Stop after 3 uvm_errors
```

This is safer than letting a broken DUT produce thousands of errors
before someone notices.

---

## 3.7 Routing Messages to a Log File

### Theory

By default, all UVM messages go to the console (stdout). In long regressions
you want error messages saved to a file so you can examine them later.

### Full Example (from document)

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

class driver extends uvm_driver;
    `uvm_component_utils(driver)
    function new(string path, uvm_component parent);
        super.new(path, parent);
    endfunction
    task run();
        `uvm_info   ("DRV", "Informational Message", UVM_NONE);
        `uvm_warning("DRV", "Potential Error");
        `uvm_error  ("DRV", "Real Error");
        `uvm_error  ("DRV", "Second Real Error");
    endtask
endclass

module tb;
    driver d;
    int    file;                          // (A) file handle

    initial begin
        file = $fopen("log.txt", "w");   // (B) open log file for writing
        d    = new("DRV", null);

        // d.set_report_default_file(file);        // route ALL messages
        d.set_report_severity_file(UVM_ERROR, file); // (C) only ERRORs

        d.run();

        #10;
        $fclose(file);                   // (D) flush and close
    end
endmodule
```

| Label | Explanation |
|-------|-------------|
| (A) | `int file` stores the file descriptor returned by `$fopen` |
| (B) | `$fopen("log.txt","w")` opens a new file for writing, returns an integer handle |
| (C) | Only `uvm_error` messages are written to `log.txt`; other severities go to console |
| (D) | Always close the file; unclosed files may be truncated |

---

## 3.8 Architecture Diagram: Reporting Flow

```
  `uvm_info / `uvm_error / etc.
          │
          ▼
   Verbosity check (if INFO)
   Is msg_level ≤ filter_level?
          │ YES
          ▼
   Severity action lookup
   (DISPLAY? LOG? COUNT? EXIT?)
        │        │        │
        ▼        ▼        ▼
    Console   Log File  Error
    Output    (if LOG)  Counter
                         │
                   > max_quit_count?
                         │ YES
                         ▼
                   Stop Simulation
```

---

## Common Errors and Debugging Tips

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `uvm_info` not printing | Verbosity too high for current filter | Call `set_report_verbosity_level(UVM_HIGH)` |
| Messages from only one class appear | Only that class's verbosity was set | Use `_hier` variant on the parent |
| Log file is empty | Missing UVM_LOG in action | Add `UVM_LOG` to action flags |
| Simulation stops unexpectedly | `uvm_fatal` triggered | Find the source ID and check the message |
| Error count never quits | `set_report_max_quit_count` not called | Call it with desired limit |

---

## Key Takeaways

- Four macros: `uvm_info`, `uvm_warning`, `uvm_error`, `uvm_fatal` — each has different default behaviour.
- Verbosity is a filter: set the level, all messages above it are suppressed.
- `_hier` variants propagate settings to all children — use on the environment, not individual components.
- Severity override changes the type of message; severity action changes what happens when it fires.
- Use `$fopen` + `set_report_severity_file` to route specific severities to log files.

---

## Interview Questions

1. What is the difference between `uvm_error` and `uvm_fatal`?
2. If verbosity is set to UVM_MEDIUM, which messages get printed?
3. What does `set_report_verbosity_level_hier` do differently from `set_report_verbosity_level`?
4. How would you make `uvm_info` stop the simulation?
5. What is `set_report_max_quit_count` and when would you use it?
6. How do you redirect only error messages to a log file?
