// -----------------------------------------------------------------------
// Minimal interface + DUT stub. NOT explicitly shown in the source notes,
// but required for the code to compile/run -- reconstructed as a
// prerequisite per the assignment's instruction #6.
// -----------------------------------------------------------------------
interface adder_if;
  logic [3:0] a, b;
  logic [4:0] y;
endinterface

module adder_dut(adder_if aif);
  assign aif.y = aif.a + aif.b;
endmodule
