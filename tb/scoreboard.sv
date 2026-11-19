class scoreboard extends uvm_component;
  `uvm_component_utils(scoreboard);
  CPUReferenceModel ref_model;
  virtual cpu_bfm bfm;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    this.ref_model = new();
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(virtual cpu_bfm)::get(null, "*", "bfm", bfm))
        $fatal("Failed to get BFM");
  endfunction

  function void print_registers();
    $display("instruction: %s", bfm.instr.name());
    $display("rd: x%d, rs1: x%d, rs2: x%d", ref_model.rd, ref_model.rs1, ref_model.rs2);
    $display("REGISTERS");
    $display("======================");
    for (int i = 0; i < 32; i++)
      $display("x%d: %h", i, ref_model.registers[i]);
  endfunction

  local function void log_instruction();
    if (bfm.instruction_counts.exists(bfm.instr.name()))
      bfm.instruction_counts[bfm.instr.name()]++;
    else
      bfm.instruction_counts[bfm.instr.name()] = 1;
  endfunction

  task run_phase(uvm_phase phase);
    forever begin 
      @(posedge bfm.clk)

      if (bfm.not_stalled && !$isunknown(bfm.instruction_WB)) begin
        // check reference model against DUT 
        logic [31:0] expected;
        ref_model.decode_and_execute(bfm.instruction_WB, bfm.PC_WB, bfm.instr);
        log_instruction();
        bfm.instructions_checked++;
        expected = ref_model.registers[ref_model.rd];
        if (bfm.valid_WB) begin
          if (bfm.writedata_WB != expected) begin
            $error("destination register incorrect. expected=%h got=%h for instruction=%h", expected, bfm.writedata_WB, bfm.instruction_WB);
            print_registers();
          end
        end

        if (ref_model.pcsrc != bfm.pcsrc_WB) begin
          $error("branch was incorrectly taken or not taken. expected pcsrc=%d, got=%d", ref_model.pcsrc, bfm.pcsrc_WB);
          print_registers();
        end

        case (bfm.pcsrc_WB)
          2'd1: begin
            if (bfm.jal_addr_WB[11:0] != ref_model.pc) begin
              $error("PC incorrect. expected=%h, got=%h for instruction=%h", ref_model.pc, bfm.jal_addr_WB, bfm.instruction_WB);
              $display("PC Source: %d", bfm.pcsrc_WB);
              print_registers();
            end
          end
          2'd2: begin
            //$display("getting to pcsrc = 2, instruction=%s", bfm.instr.name());
            if (bfm.branch_addr_WB[11:0] != ref_model.pc) begin
              $error("PC incorrect. expected=%h, got=%h for instruction=%h", ref_model.pc, bfm.branch_addr_WB, bfm.instruction_WB);
              $display("PC Source: %d", bfm.pcsrc_WB);
              print_registers();
            end
          end
        endcase
      end
    end 
  endtask

endclass
