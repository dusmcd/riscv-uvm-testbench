class branch_coverage extends coverage;
  `uvm_component_utils(branch_coverage);

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_branch = new();
  endfunction

  local instr_t instr;
  covergroup cg_branch;
    coverpoint instr {
      bins jal = {JAL};
      bins beq = {BEQ};
      bins bge = {BGE};
      bins bgeu = {BGEU};
      bins blt = {BLT};
      bins bltu = {BLTU};
    }
  endgroup

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    fork
      forever begin
        @(negedge bfm.clk);
        instr = bfm.instr;
        cg_branch.sample();
      end
    join_none

    wait(bfm.done);
    $display("Coverage = %.2f %%", cg_branch.get_inst_coverage());
    phase.drop_objection(this);

  endtask
endclass
