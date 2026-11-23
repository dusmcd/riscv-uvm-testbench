class branch_tester extends random_tester;
  `uvm_component_utils(branch_tester);

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  protected virtual task generate_instructions(int num_instructions);
    cpu_instr.create_branch_instr_file(num_instructions);
    bfm.load_instructions();
  endtask
endclass
