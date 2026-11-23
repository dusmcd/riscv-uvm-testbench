class branch_test extends random_test;
  `uvm_component_utils(branch_test);
  branch_tester tester_i;
  branch_coverage coverage_i;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    tester_i = new("tester_i", this);
    coverage_i = new("coverage_i", this);
    scoreboard_i = new("scoreboard_i", this);
  endfunction
endclass
