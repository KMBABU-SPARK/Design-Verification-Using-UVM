# Project 1: Your First Complete UVM Testbench
### A minimal driver + monitor + env with full reporting control

---

## Objective

Build a self-contained UVM testbench that:
1. Has a driver, monitor, and environment
2. Uses all four reporting macros
3. Demonstrates verbosity control
4. Routes errors to a log file

---

## Project Code

Save this as `project1_tb.sv` and compile with your simulator:

```
vcs -sverilog -ntb_opts uvm project1_tb.sv -o simv
./simv
```

---

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

// ─── DRIVER ─────────────────────────────────────────────────
class my_driver extends uvm_driver;
    `uvm_component_utils(my_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run();
        `uvm_info   ("DRV", "Driver started",          UVM_LOW);
        `uvm_info   ("DRV", "Driving first stimulus",  UVM_HIGH);
        `uvm_warning("DRV", "Timing margin is tight");
        `uvm_error  ("DRV", "Protocol violation seen");
    endtask
endclass

// ─── MONITOR ────────────────────────────────────────────────
class my_monitor extends uvm_monitor;
    `uvm_component_utils(my_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run();
        `uvm_info("MON", "Monitor started",         UVM_LOW);
        `uvm_info("MON", "Observed output = 0xAB",  UVM_HIGH);
    endtask
endclass

// ─── ENVIRONMENT ────────────────────────────────────────────
class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    my_driver  drv;
    my_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run();
        drv = new("DRV", this);
        mon = new("MON", this);
        drv.run();
        mon.run();
    endtask
endclass

// ─── TESTBENCH TOP ──────────────────────────────────────────
module tb;
    my_env e;
    int    error_log;

    initial begin
        error_log = $fopen("errors.log", "w");
        e = new("ENV", null);

        // Show LOW and above (hides HIGH debug messages)
        e.set_report_verbosity_level_hier(UVM_LOW);

        // Route errors to file as well as console
        e.set_report_severity_file(UVM_ERROR, error_log);

        // Stop after 5 errors
        e.set_report_max_quit_count(5);

        e.run();

        #10;
        $fclose(error_log);
        $display("\n--- Simulation Complete. Check errors.log ---");
    end
endmodule
```

---

## Expected Console Output

```
UVM_INFO  ... [DRV] Driver started
UVM_WARNING ... [DRV] Timing margin is tight
UVM_ERROR ... [DRV] Protocol violation seen
UVM_INFO  ... [MON] Monitor started
(HIGH messages suppressed — verbosity is LOW)
--- Simulation Complete. Check errors.log ---
```

## Expected errors.log Content

```
UVM_ERROR ... [DRV] Protocol violation seen
```

---

## Exercises

1. Change verbosity to `UVM_HIGH` and observe the extra debug messages.
2. Add a `uvm_fatal` to the driver and observe the simulation stopping.
3. Use `set_report_severity_override` to turn the fatal into an error.
4. Add a second driver `drv2` to the environment.
5. Set verbosity to HIGH on only `drv` and LOW on `mon` — verify selective output.
