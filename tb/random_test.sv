class random_test extends uvm_test;
  `uvm_component_utils(random_test);

  local random_tester tester_i;
  coverage coverage_i;
  scoreboard scoreboard_i;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    tester_i = new("tester_i", this);
    coverage_i = new ("coverage_i", this);
    scoreboard_i = new ("scoreboard_i", this);
  endfunction

endclass
