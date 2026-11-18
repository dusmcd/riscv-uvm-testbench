class random_tester extends uvm_component;
  `uvm_component_utils(random_tester);
  virtual cpu_bfm bfm;
  CPUInstruction cpu_instr;
 
  function new(string name, uvm_component parent);
    super.new(name, parent);
    cpu_instr = new();
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(virtual cpu_bfm)::get(null, "*", "bfm", bfm))
      $fatal("Failed to get BFM");
    
    bfm.num_instructions = 4000;
  endfunction

  protected virtual task generate_instructions(int num_instructions);
    cpu_instr.create_instr_file(num_instructions);
    bfm.load_instructions();
  endtask

  local task pipeline();
    fork
        
     forever begin
      @(posedge bfm.clk)
      if (~bfm.KEY[0]) begin
        bfm.valid_WB <= 1'b0;
        bfm.not_stalled <= 1'b0;
      end
      else begin
        bfm.valid_WB <= bfm.regwrite_EX;
        bfm.not_stalled <= ~bfm.stall_EX;
        bfm.instruction_WB <= bfm.instruction_EX;
        bfm.PC_WB <= bfm.PC_EX;
        bfm.jal_addr_WB <= bfm.jal_addr_EX;
        bfm.branch_addr_WB <= bfm.branch_addr_EX;
      end
     end

    join_none
  endtask

  
  task run_phase(uvm_phase phase);
    generate_instructions(bfm.num_instructions);
    pipeline();
    bfm.reset_cpu();
    repeat((31 + bfm.num_instructions) * 3) @(negedge bfm.clk);
    $display("instructions executed: %d", bfm.instructions_checked);
    bfm.done = 1'b1;
  endtask


endclass
