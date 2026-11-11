class random_tester extends uvm_component;
  `uvm_component_utils(random_tester);
  virtual cpu_bfm bfm;
  CPUInstruction cpu_instr;
 
  function new(string name, uvm_component parent);
    super.new(name, parent);
    cpu_instr = new();
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(virtual cpu_bfm bfm)::get(null, "*", "bfm", bfm))
      $fatal("Failed to get BFM");
  endfunction

  protected virtual task generate_instructions(int num_instructions);
    cpu_instr.create_instr_file(num_instructions);
    bfm.load_instructions();
  endtask

  local task pipeline();
    fork
        
     forever begin
      @(posedge bfm.clk)
      if (~bfm.KEY[0])
        bfm.valid_WB <= 1'b0;
      else begin
        bfm.valid_WB <= 1'b1;
        bfm.instruction_WB <= bfm.instruction_EX;
      end
     end

    join_none
  endtask

  
  task run_phase(uvm_phase phase);
    generate_instructions(bfm.num_instructions);
    pipeline();
    bfm.reset_cpu();
    repeat((31 + num_instructions) * 3) @(negedge bfm.clk);
    bfm.done = 1'b1;
  endtask


endclass
