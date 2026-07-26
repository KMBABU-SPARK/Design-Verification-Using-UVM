# UVM Testbench for 4-bit Adder

A simple **UVM (Universal Verification Methodology)** testbench that verifies a 4-bit combinational adder (`add`) using a complete UVM environment: sequence item, sequencer/generator, driver, monitor, scoreboard, agent, environment, and test.

## Design Under Test (DUT)

```systemverilog
module add(
  a, b, y
);
  input  [3:0] a, b;
  output [4:0] y;

  assign y = a + b;
endmodule
```

## Interface

```systemverilog
interface add_if();
  logic [3:0] a;
  logic [3:0] b;
  logic [4:0] y;
endinterface
```

## Testbench Architecture

- **transaction** – UVM sequence item holding the randomized inputs (`a`, `b`) and the DUT output (`y`).
- **generator** – UVM sequence that randomizes and sends 10 transactions to the sequencer.
- **driver** – Drives randomized `a`/`b` values onto the DUT interface.
- **monitor** – Samples `a`, `b`, and `y` from the interface and broadcasts them via an analysis port.
- **scoreboard** – Receives transactions from the monitor and checks `y == a + b`.
- **agent** – Encapsulates the driver, monitor, and sequencer.
- **env** – Encapsulates the agent and scoreboard, connecting monitor to scoreboard.
- **test** – Instantiates the environment and generator, and starts the sequence.
- **add_tb** – Top-level testbench module that instantiates the DUT, interface, sets up `uvm_config_db`, and runs the test.

## Full UVM Testbench Code

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  rand bit[3:0]a;
  rand bit[3:0]b;
  bit [4:0]y;
 //constructor creation  
  function new(input string path="transaction");
    super.new(path);
  endfunction
 //field registtration to uvm factory 
  `uvm_object_utils_begin(transaction)
 
  `uvm_field_int(a,UVM_DEFAULT)
  `uvm_field_int(b,UVM_DEFAULT)
  `uvm_field_int(y,UVM_DEFAULT)
  `uvm_object_utils_end
  
endclass

class generator extends uvm_sequence#(transaction);
  `uvm_object_utils(generator)
  transaction t;
  integer i;
  
  function new(input string path="generator");
    super.new(path);
    
  endfunction
  
  virtual task body;
    t=transaction::type_id::create("t");
    repeat(10)
      begin
        start_item(t);
        t.randomize();
        `uvm_info("gen",$sformatf("a->%0d,b->%0d",t.a,t.b),UVM_NONE);
        finish_item(t);
        
      end
  endtask
endclass



class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
  
  function new(input string path="driver",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  transaction tc;
  virtual add_if aif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    tc=transaction::type_id::create("tc");
    
      if(!uvm_config_db #(virtual add_if)::get(this,"","aif",aif)) 
      `uvm_error("DRV","Unable to access uvm_config_db");
    endfunction
    /*
    if(!uvm_config_db#(virtual add_if)::get(null,"uvm_test_top.e.a","aif",aif));
    `uvm_error("drv","interface not connected");
  endfunction*/
  
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      
      seq_item_port.get_next_item(tc);
      aif.a<=tc.a;
      aif.b<=tc.b;
      
      `uvm_info("drv",$sformatf("a->%0d,b->%0d",tc.a,tc.b),UVM_NONE);
      
      seq_item_port.item_done();
      #10;
    end
    
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  
  //this is an tlm communication method in this we can have one to many communication
  uvm_analysis_port#(transaction)send;
  
  
  function new(input string path="monitor",uvm_component parent=null);
    super.new(path,parent);
    send=new("send",this);
    
  endfunction
  
  transaction t;
  virtual add_if aif;
  
  virtual function void buid_phase(uvm_phase phase);
    super.build_phase(phase);
    
    t=transaction::type_id::create("t");
    
    if(!uvm_config_db #(virtual add_if)::get(this,"","aif",aif)) 
   `uvm_error("MON","Unable to access uvm_config_db");
  endfunction
    
    
    /*
    if(!uvm_config_db#(virtual add_if)::get(null,"uvm_test_top.e.a","aif",aif));
    `uvm_error("mon","interface connection failed");
  endfunction*/
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      #10;
      t.a=aif.a;
      t.b=aif.b;
      t.y=aif.y;
      `uvm_info("mon",$sformatf("a->%0d,b->%0d ,y->%0d",t.a,t.b,t.y),UVM_NONE);
      
      send.write(t);
    end
  endtask
  
endclass

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);
  uvm_analysis_imp#(transaction,scoreboard)recv;
  transaction tr;
  
  function new(input string path="scoreboard",uvm_component parent =null);
    super.new(path,parent);
    recv=new("recv",this);
    
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    tr=transaction::type_id::create("tr");
    
  endfunction
                        
                                     
  virtual function void write(input transaction t);
                                  
   tr=t;
  `uvm_info("sco",$sformatf("a->%0d,b->%0d ,y->%0d",tr.a,tr.b,tr.y),UVM_NONE);
   if(tr.y==tr.a+tr.b)
   `uvm_info("sco","test passed",UVM_NONE)
   else begin
   `uvm_info("sco","test failed",UVM_NONE)   
  end
  endfunction
endclass


class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  function new(input string inst="AGENT",uvm_component c);
    super.new(inst,c);
  endfunction
  monitor m;
  driver d;
  uvm_sequencer#(transaction)seqr;
  
  virtual function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    m=monitor::type_id::create("m",this);
    d=driver::type_id::create("d",this);
    seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
    
    
  endfunction
              
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass


  class env extends uvm_env;
    `uvm_component_utils(env)
  
    function new(input string inst="ENV",uvm_component c);
    super.new(inst,c);
  endfunction
  scoreboard s;
  agent a;
    
  virtual function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    s=scoreboard::type_id::create("s",this);
    a=agent::type_id::create("a",this);
    
  endfunction
              
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.recv);
  endfunction
    
   

endclass
                                 
    

  class test extends uvm_test;
    `uvm_component_utils(test)
  
    function new(input string inst="TEST",uvm_component c);
    super.new(inst,c);
  endfunction
  env e;
  generator gen;
    
  virtual function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    gen=generator::type_id::create("gen");
    e=env::type_id::create("e",this);
    
  endfunction
              
    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      gen.start(e.a.seqr);
      #50;
      phase.drop_objection(this);
    endtask
    
    virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    `uvm_info("TOPOLOGY","Printing UVM Topology",UVM_NONE)
    uvm_top.print_topology();
  endfunction
      
endclass

module add_tb();
 
add_if aif();
 
add dut (.a(aif.a), .b(aif.b), .y(aif.y));
 
initial begin
$dumpfile("dump.vcd");
$dumpvars;
end
  
initial begin  
uvm_config_db #(virtual add_if)::set(null, "uvm_test_top.e.a", "aif", aif);
run_test("test");
end
 
endmodule
```

## How to Run

1. Compile with a UVM-aware simulator (e.g., Questa, VCS, or Xcelium) with UVM library support.
2. Run the `add_tb` top module.
3. Check the scoreboard log for `test passed` / `test failed` messages.

## Notes

- The interface path used in `uvm_config_db` (`uvm_test_top.e.a`) must match the hierarchy: `test -> env (e) -> agent (a)`.
- There's a typo in the `monitor` class (`buid_phase` instead of `build_phase`) — fix this before running, or the interface won't be fetched correctly in the monitor.
