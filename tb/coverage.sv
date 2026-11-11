class coverage extends uvm_component;
  `uvm_component_utils(coverage);
  // ensure that all instructions have been executed
  covergroup cg @(posedge bfm.clk);
    coverpoint bfm.instr {
      bins add = {ADD};
      bins sub = {SUB};
      bins and_bin = {AND};
      bins or_bin = {OR};
      bins xor_bin = {XOR};
      bins sll = {SLL};
      bins sra = {SRA};
      bins srl = {SRL};
      bins slt = {SLT};
      bins sltu = {SLTU};
      bins mul = {MUL};
      bins mulh = {MULH};
      bins mulhu = {MULHU};
      bins csrrw = {CSRRW};
      bins addi = {ADDI};
      bins andi = {ANDI};
      bins ori = {ORI};
      bins xori = {XORI};
      bins slli = {SLLI};
      bins srai = {SRAI};
      bins srli = {SRLI};
      bins lui = {LUI};
    }
  endgroup

  virtual cpu_bfm bfm;

  function new(string name, uvm_component parent);
    super.new(name, parent):
    cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(cpu_bfm bfm)::get(null, "*", "bfm", bfm))
      $fatal("Failed to get BFM");
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    wait(bfm.done);
    $display("Coverage = %.2f %%", cg.get_inst_coverage());
    phase.drop_objection(this);
  endtask



endclass
