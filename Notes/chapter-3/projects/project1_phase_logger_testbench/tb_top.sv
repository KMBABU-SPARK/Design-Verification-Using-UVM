// Project 1 solution — tb_top.sv
// Compile order: driver.sv, monitor.sv, env.sv, test.sv, tb_top.sv
`include "uvm_macros.svh"
import uvm_pkg::*;

module tb_top;
  initial begin
    uvm_top.set_timeout(2000ns, 0);   // global safety net (Chapter 7)
    run_test("test");
  end
endmodule

// ============================================================================
// Expected simulated log order (see monitor.sv for the numeric timeline):
//   Driver Reset Started        (t=0)
//   Monitor Reset Started       (t=0)
//   Driver Reset Ended          (t=50)
//   Monitor Reset Ended         (t=90)      <- reset_phase ends here
//   Driver Main Phase Started   (t=90)
//   Monitor Main Phase Started  (t=90)
//   Driver Main Phase Ended     (t=170)
//   Monitor Main Phase Ended    (t=210)     <- objections all zero here
//   ... 75 time units of drain time pass with no activity ...
//   Driver Post-Main Phase Started    (t=285)
//   Monitor Post-Main Phase Started   (t=285)
// ============================================================================
