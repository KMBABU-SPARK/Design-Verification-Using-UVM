# UVM Testbench for DFF

A simple **UVM (Universal Verification Methodology)** testbench that verifies a **D Flip-Flop (DFF)** with reset using a complete UVM environment: sequence item, sequences, driver, monitor, scoreboard, agent, environment, and test.

## Design Under Test (DUT)

```systemverilog
module dff (
  input clk, rst, din,   // din - data input, rst - active high synchronous reset
  output reg dout         // dout - data output
);

  always @(posedge clk) begin
    if (rst == 1'b1)
      dout <= 1'b0;
    else
      dout <= din;
  end

endmodule
```

## Interface

```systemverilog
interface dff_if();
  logic clk;
  logic rst;
  logic din;
  logic dout;
endinterface
```

## UVM Testbench Code

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

class config_dff extends uvm_object;
  `uvm_object_utils(config_dff)

  uvm_active_passive_enum agent_type = UVM_ACTIVE;

  function new(input string path = "config_dff");
    super.new(path);
  endfunction
endclass


class transaction extends uvm_sequence_item;
  rand bit din;
  rand bit rst;
  bit dout;

  function new(input string path = "transaction");
    super.new(path);
  endfunction

  `uvm_object_utils_begin(transaction)
    `uvm_field_int(din,  UVM_DEFAULT)
    `uvm_field_int(dout, UVM_DEFAULT)
    `uvm_field_int(rst,  UVM_DEFAULT)
  `uvm_object_utils_end
endclass


class valid_din extends uvm_sequence #(transaction);
  `uvm_object_utils(valid_din)

  transaction t;

  function new(input string path = "valid_din");
    super.new(path);
  endfunction

  virtual task body();
    repeat (15) begin
      t = transaction::type_id::create("t");
      start_item(t);
      assert(t.randomize());
      t.rst = 1'b0;
      `uvm_info("SEQ1", $sformatf("rst=%0b din=%0b dout=%0b", t.rst, t.din, t.dout), UVM_NONE)
      finish_item(t);
    end
  endtask
endclass


class rst_dff extends uvm_sequence #(transaction);
  `uvm_object_utils(rst_dff)

  transaction t;

  function new(input string path = "rst_dff");
    super.new(path);
  endfunction

  virtual task body();
    repeat (15) begin
      t = transaction::type_id::create("t");
      start_item(t);
      assert(t.randomize());
      t.rst = 1'b1;
      `uvm_info("SEQ2", $sformatf("rst=%0b din=%0b dout=%0b", t.rst, t.din, t.dout), UVM_NONE)
      finish_item(t);
    end
  endtask
endclass


class rand_din_rst extends uvm_sequence #(transaction);
  `uvm_object_utils(rand_din_rst)

  transaction t;

  function new(input string path = "rand_din_rst");
    super.new(path);
  endfunction

  virtual task body();
    repeat (15) begin
      t = transaction::type_id::create("t");
      start_item(t);
      assert(t.randomize());
      `uvm_info("SEQ3", $sformatf("rst=%0b din=%0b dout=%0b", t.rst, t.din, t.dout), UVM_NONE)
      finish_item(t);
    end
  endtask
endclass


class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)

  function new(input string path = "driver", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  transaction tc;
  virtual dff_if dif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(virtual dff_if)::get(this, "", "dif", dif))
      `uvm_error("DRIVER", "Unable to access uvm_config_db")
  endfunction

  virtual task run_phase(uvm_phase phase);
    tc = transaction::type_id::create("tc");

    forever begin
      seq_item_port.get_next_item(tc);
      dif.din <= tc.din;
      dif.rst <= tc.rst;

      `uvm_info("DRIVER", $sformatf("rst=%0b din=%0b dout=%0b", tc.rst, tc.din, tc.dout), UVM_NONE)

      seq_item_port.item_done();
      repeat (2) @(posedge dif.clk);
    end
  endtask
endclass


class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)

  uvm_analysis_port #(transaction) send;

  function new(input string path = "monitor", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  transaction t;
  virtual dff_if dif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    send = new("send", this);
    t    = transaction::type_id::create("t");

    if (!uvm_config_db #(virtual dff_if)::get(this, "", "dif", dif))
      `uvm_error("MON", "Unable to access uvm_config_db")
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      repeat (2) @(posedge dif.clk);
      t.din  = dif.din;
      t.rst  = dif.rst;
      t.dout = dif.dout;

      `uvm_info("MON", $sformatf("rst=%0b din=%0b dout=%0b", t.rst, t.din, t.dout), UVM_NONE)

      send.write(t);
    end
  endtask
endclass


class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  uvm_analysis_imp #(transaction, scoreboard) recv;

  function new(input string path = "scoreboard", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv", this);
  endfunction

  virtual function void write(input transaction tr);
    `uvm_info("SCO", $sformatf("din=%0d dout=%0d", tr.din, tr.dout), UVM_NONE)

    if (tr.rst == 1'b1)
      `uvm_info("SCO", "reset done", UVM_NONE)
    else if (tr.rst == 1'b0 && (tr.din == tr.dout))
      `uvm_info("SCO", "test passed", UVM_NONE)
    else
      `uvm_info("SCO", "test failed", UVM_NONE)
  endfunction
endclass


class agent extends uvm_agent;
  `uvm_component_utils(agent)

  function new(input string inst = "AGENT", uvm_component parent = null);
    super.new(inst, parent);
  endfunction

  monitor m;
  driver d;
  uvm_sequencer #(transaction) seqr;
  config_dff cfg;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m   = monitor::type_id::create("m", this);
    cfg = config_dff::type_id::create("cfg");

    if (!uvm_config_db #(config_dff)::get(this, "", "cfg", cfg))
      `uvm_error("AGENT", "FAILED TO ACCESS CONFIG")

    if (cfg.agent_type == UVM_ACTIVE) begin
      d    = driver::type_id::create("d", this);
      seqr = uvm_sequencer #(transaction)::type_id::create("seqr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.agent_type == UVM_ACTIVE)
      d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass


class env extends uvm_env;
  `uvm_component_utils(env)

  function new(input string inst = "ENV", uvm_component c);
    super.new(inst, c);
  endfunction

  scoreboard s;
  agent a;
  config_dff cfg;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    s   = scoreboard::type_id::create("s", this);
    a   = agent::type_id::create("a", this);
    cfg = config_dff::type_id::create("cfg");

    uvm_config_db #(config_dff)::set(this, "a", "cfg", cfg);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.recv);
  endfunction
endclass


class test extends uvm_test;
  `uvm_component_utils(test)

  function new(input string inst = "TEST", uvm_component c);
    super.new(inst, c);
  endfunction

  env e;
  valid_din    vdin;
  rst_dff      rff;
  rand_din_rst rdin;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    e    = env::type_id::create("e", this);
    vdin = valid_din::type_id::create("vdin");
    rff  = rst_dff::type_id::create("rff");
    rdin = rand_din_rst::type_id::create("rdin");
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    rff.start(e.a.seqr);
    #50;

    vdin.start(e.a.seqr);
    #50;

    rdin.start(e.a.seqr);
    #50;

    phase.drop_objection(this);
  endtask

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("TOPOLOGY", "Printing UVM Topology", UVM_NONE)
    uvm_top.print_topology();
  endfunction
endclass
```

## Top Module

```systemverilog
module dff_tb();

  dff_if dif();

  dff dut (
    .din(dif.din),
    .dout(dif.dout),
    .clk(dif.clk),
    .rst(dif.rst)
  );

  initial begin
    dif.clk = 0;
  end

  always #10 dif.clk = ~dif.clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  initial begin
    uvm_config_db #(virtual dff_if)::set(null, "*", "dif", dif);
    run_test("test");
  end

endmodule
```

## Notes

* The `driver` sends `din` and `rst` to the DUT.
* The `monitor` samples `din`, `rst`, and `dout` after every 2 clock cycles.
* The `scoreboard` checks:

  * reset case: `rst == 1` → `dout` should be `0`
  * normal case: `rst == 0` → `dout` should follow `din`
* The `agent` is active because it contains a driver and sequencer.
* The `env` passes the config object to the agent through `uvm_config_db`.

## How to Run

1. Compile with a UVM-aware simulator.
2. Run the `dff_tb` top module.
3. Check the log for `reset done`, `test passed`, or `test failed`.
