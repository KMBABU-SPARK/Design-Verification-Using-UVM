module clk_gen(
  input clk, rst,
  input [16:0] baud,
  output tx_clk
);

  reg t_clk = 0;
  int tx_max = 0;
  int tx_count = 0;

  always @(posedge clk) begin
    if (rst) begin
      tx_max <= 0;
    end
    else begin
      case (baud)
        4800:   tx_max <= 14'd10416;
        9600:   tx_max <= 14'd5208;
        14400:  tx_max <= 14'd3472;
        19200:  tx_max <= 14'd2604;
        38400:  tx_max <= 14'd1302;
        57600:  tx_max <= 14'd868;
        default: tx_max <= 14'd5208;
      endcase
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      tx_count <= 0;
      t_clk    <= 0;
    end
    else begin
      if (tx_count < tx_max / 2) begin
        tx_count <= tx_count + 1;
      end
      else begin
        t_clk    <= ~t_clk;
        tx_count  <= 0;
      end
    end
  end

  assign tx_clk = t_clk;

endmodule


interface clk_if;
  logic clk, rst;
  logic [16:0] baud;
  logic tx_clk;
endinterface
