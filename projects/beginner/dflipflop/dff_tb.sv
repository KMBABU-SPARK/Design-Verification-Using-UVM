`include "uvm_macros.svh"
import uvm_pkg::*;

class config_dff extends uvm_object;
  `uvm_object_utils(config_dff)
  uvm_active_passive_enum agent_type=UVM_ACTIVE;
  
  function new(input string path="config_dff");
    super.new(path);
  endfunction
  
endclass

  
class transaction extends uvm_sequence_item;
  
  rand bit din;
  rand bit rst;
  bit dout;
  
 //constructor creation  
  function new(input string path="transaction");
    super.new(path);
  endfunction
 //field registtration to uvm factory 
  `uvm_object_utils_begin(transaction)
 
  `uvm_field_int(din,UVM_DEFAULT)
  `uvm_field_int(dout,UVM_DEFAULT)
  `uvm_field_int(rst,UVM_DEFAULT)
  `uvm_object_utils_end
  
endclass

class valid_din extends uvm_sequence#(transaction);
  `uvm_object_utils(valid_din)
  transaction t;

  
  function new(input string path="valid_din");
    super.new(path);
    
  endfunction
  
  virtual task body;
   
    repeat(15)
       
      begin
        t=transaction::type_id::create("t");
        start_item(t);
        assert( t.randomize());
        t.rst=1'b0;
        `uvm_info("SEQ1", $sformatf("rst : %0b  din : %0b  dout : %0b", t.rst, t.din, t.dout), UVM_NONE);
        finish_item(t);
        
      end
  endtask
endclass



class rst_dff extends uvm_sequence#(transaction);
  `uvm_object_utils(rst_dff)
  transaction t;

  
  function new(input string path="rst_dff");
    super.new(path);
    
  endfunction
  
  virtual task body;
   
    repeat(15)
     //  t=transaction::type_id::create("t");
      begin
         t=transaction::type_id::create("t");
        start_item(t);
        //t.randomize();
        assert( t.randomize());
        t.rst=1'b1;
        `uvm_info("SEQ2", $sformatf("rst : %0b  din : %0b  dout : %0b", t.rst, t.din, t.dout), UVM_NONE);
     
        finish_item(t);
        
      end
  endtask
endclass



class rand_din_rst extends uvm_sequence#(transaction);
  `uvm_object_utils(rand_din_rst)
  transaction t;

  
  function new(input string path="rand_din_rst");
    super.new(path);
    
  endfunction
  
  virtual task body;
   
    repeat(15)
     
      begin
        t=transaction::type_id::create("t");
        start_item(t);
        //t.randomize();
        assert( t.randomize());
        `uvm_info("SEQ3", $sformatf("rst : %0b  din : %0b  dout : %0b", t.rst, t.din, t.dout), UVM_NONE);
        
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
  virtual dff_if dif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
 
    
    if(!uvm_config_db #(virtual dff_if)::get(this,"","dif",dif)) 
      `uvm_error("driver","Unable to access uvm_config_db");
    endfunction
    /*
    if(!uvm_config_db#(virtual add_if)::get(null,"uvm_test_top.e.a","aif",aif));
    `uvm_error("drv","interface not connected");
  endfunction*/

  
  virtual task run_phase(uvm_phase phase);
       
    tc=transaction::type_id::create("tc");
    
    forever begin
      
      seq_item_port.get_next_item(tc);
      dif.din<=tc.din;
      dif.rst<=tc.rst;
      
      //aif.b<=tc.b;
      `uvm_info("driver", $sformatf("rst : %0b  din : %0b  dout : %0b", tc.rst, tc.din, tc.dout), UVM_NONE);

      
      seq_item_port.item_done();
      repeat(2)@(posedge dif.clk);
      
    end
    
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  
  //this is an tlm communication method in this we can have one to many communication
  uvm_analysis_port#(transaction)send;
  
  
  function new(input string path="monitor",uvm_component parent=null);
    super.new(path,parent);
   // send=new("send",this);
    
  endfunction
  
  transaction t;
  virtual dff_if dif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
        send=new("send",this);
    
    t=transaction::type_id::create("t");
    
    if(!uvm_config_db #(virtual dff_if)::get(this,"","dif",dif)) 
   `uvm_error("MON","Unable to access uvm_config_db");
  endfunction
    
    
    /*
    if(!uvm_config_db#(virtual add_if)::get(null,"uvm_test_top.e.a","aif",aif));
    `uvm_error("mon","interface connection failed");
  endfunction*/
  
  virtual task run_phase(uvm_phase phase);
   
    forever begin
      repeat(2)@(posedge dif.clk);
      t.din=dif.din;
      t.rst=dif.rst;
      t.dout=dif.dout;
     // t.y=aif.y;
    `uvm_info("MON", $sformatf("rst : %0b  din : %0b  dout : %0b", t.rst, t.din, t.dout), UVM_NONE);
      
      send.write(t);
    end
  endtask
  
endclass

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);
  uvm_analysis_imp#(transaction,scoreboard)recv;
  
  
  function new(input string path="scoreboard",uvm_component parent =null);
    super.new(path,parent);
   
    
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
     recv=new("recv",this);    
  //  tr=transaction::type_id::create("tr");
    
  endfunction
                        
                                     
  virtual function void write(input transaction tr);
                                  
   
    `uvm_info("sco",$sformatf("din->%0d,dout->%0d ",tr.din,tr.dout),UVM_NONE);
    if(tr.rst==1'b1)
      `uvm_info("sco","reset done",UVM_NONE)
   else if(tr.rst==1'b0 && (tr.din==tr.dout))
      `uvm_info("sco","test passed",UVM_NONE)
   else begin
   `uvm_info("sco","test failed",UVM_NONE)   
  end
  endfunction
endclass


class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  function new(input string inst="AGENT",uvm_component parent =null);
    super.new(inst,parent);
  endfunction
  
  monitor m;
  driver d;
  uvm_sequencer#(transaction)seqr;
  
  config_dff cfg;
  
  virtual function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    m=monitor::type_id::create("m",this);//monitor is component so parent specificaation is required
    cfg=config_dff::type_id::create("cfg");//where as cfg is object class so its parent specification is not required
    
  
  if(!uvm_config_db#(config_dff)::get(this,"","cfg",cfg))
     `uvm_error("AGENT", "FAILED TO ACCESS CONFIG");
  
  if(cfg.agent_type==UVM_ACTIVE)
    begin
      d=driver::type_id::create("d",this);
    seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
    end
  endfunction
  
    
  
              
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
     if(cfg.agent_type==UVM_ACTIVE)
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
     config_dff cfg;
    
  virtual function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    s=scoreboard::type_id::create("s",this);
    a=agent::type_id::create("a",this);
    cfg=config_dff::type_id::create("cfg");
    uvm_config_db#(config_dff)::set(this,"a","cfg",cfg);
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
  valid_din    vdin;
  rst_dff      rff;
   rand_din_rst rdin;
    
  virtual function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
      e=env::type_id::create("e",this);
    
    vdin=valid_din::type_id::create("vdin");
    rff=rst_dff::type_id::create("rff");
    rdin=rand_din_rst::type_id::create("rdin");
    
  
    
  endfunction
              
    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
     // e.a.seqr.set_arbitration(UVM_SEQ_ARB_STRICT_FIFO);
     
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

    `uvm_info("TOPOLOGY","Printing UVM Topology",UVM_NONE)
    uvm_top.print_topology();
  endfunction
      
endclass

module dff_tb();
     
dff_if dif();
 
  dff dut (.din(dif.din), .dout(dif.dout),.clk(dif.clk),.rst(dif.rst));
  initial begin
    dif.clk=0;
  end
  
  always#10 dif.clk=~dif.clk;
 
initial begin
$dumpfile("dump.vcd");
$dumpvars;
end
  
initial begin  
  uvm_config_db #(virtual dff_if)::set(null, "*", "dif", dif);
run_test("test");
end
 
endmodule




                 
    

    
  
