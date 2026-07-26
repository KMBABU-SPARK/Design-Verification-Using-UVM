// Project 1 solution — test.sv
`include "uvm_macros.svh"
import uvm_pkg::*;

class test extends uvm_test;
  `uvm_component_utils(test)

  env e;

  function new(string path = "test", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e", this);
  endfunction

  // Centralized drain time: applied to "main" phase once, here, instead of
  // duplicated inside driver/monitor.
  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_phase main_phase;
    super.end_of_elaboration_phase(phase);
    main_phase = phase.find_by_name("main", 0);
    main_phase.phase_done.set_drain_time(this, 75);
  endfunction
endclass
