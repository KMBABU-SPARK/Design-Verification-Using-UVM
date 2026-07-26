`timescale 1ns/1ps;

// interface d_ff_if #(parameter N=8);
// 	logic clk;
// 	logic rst_n;
// 	logic [N-1:0] din;
// 	logic [N-1:0] dout;

// 	modport dut(			//only names of signals are specified and not their width inside modport
// 		input clk,rst_n,
// 		input din,
// 		output dout
// 		);

// 	modport tb(			//only names of signals are specified and not their width inside modport
// 		input clk, dout,
// 		output rst_n, din
// 		);

// endinterface

// module d_ff #(
// 	parameter N=8
// 	);

// 	(
// 	/*input [N-1:0] din,
// 	input clk, rst_n,
// 	output logic [N-1:0] dout*/

// 	d_ff_if.dut d_ff_vif
// 	);

// 	always @(posedge d_ff_vif.clk, negedge d_ff_vif.rst_n) begin
// 		if(!d_ff_vif.rst_n)
// 			d_ff_vif.dout <= {N{1'b0}};		//cannot be "{N{0}}" and it can be "0" also
// 		else
// 			d_ff_vif.dout <= d_ff_vif.din;
// 	end

// endmodule


interface dff_if;
  logic clk;   // Clock signal
  logic rst;   // Reset signal
  logic din;   // Data input
  logic dout;  // Data output

endinterface

module dff (dff_if vif);

  always @(posedge vif.clk)
    begin
      if (vif.rst == 1'b1)
	  vif.dout <= 1'b0;
      else
        vif.dout <= vif.din;
    end

endmodule
