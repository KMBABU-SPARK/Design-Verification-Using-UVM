`include "uvm_macros.svh"
import uvm_pkg::*;

`include "../01_basic_sequence_driver/interface_and_dut.sv"
`include "../01_basic_sequence_driver/transaction.sv"
`include "sequence1.sv"
`include "driver.sv"
`include "../01_basic_sequence_driver/agent.sv"
`include "../01_basic_sequence_driver/env.sv"
`include "../01_basic_sequence_driver/test.sv"

module ram_tb;

  adder_if aif();
  adder_dut dut(aif);

  initial begin
    uvm_config_db #(virtual adder_if)::set(null, "*", "aif", aif);
    run_test("test");
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
