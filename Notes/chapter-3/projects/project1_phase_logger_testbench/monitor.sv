// Project 1 solution — monitor.sv
`include "uvm_macros.svh"
import uvm_pkg::*;

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)

  function new(string path = "monitor", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("mon", "Monitor Reset Started", UVM_NONE);
    #90;
    `uvm_info("mon", "Monitor Reset Ended", UVM_NONE);
    phase.drop_objection(this);
  endtask

  task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("mon", "Monitor Main Phase Started", UVM_NONE);
    #120;
    `uvm_info("mon", "Monitor Main Phase Ended", UVM_NONE);
    phase.drop_objection(this);
  endtask

  task post_main_phase(uvm_phase phase);
    `uvm_info("mon", "Monitor Post-Main Phase Started", UVM_NONE);
  endtask
endclass

// Expected timeline with these numbers (driver: reset #50/main #80,
// monitor: reset #90/main #120, drain time 75 on main, set centrally by test):
//   reset_phase ends at t=90   (monitor is slower: 90 > 50)
//   main_phase objections zero at t = 90 + max(80,120) = 210
//   main_phase actual end (with +75 drain) = 285
//   post_main_phase starts only after t=285
