class env extends uvm_env;
  `uvm_component_utils(env)

  function new(input string path = "env", uvm_component parent= null);
    super.new(path,parent);
  endfunction

  agent a;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = agent::type_id::create("a",this);
  endfunction

endclass
