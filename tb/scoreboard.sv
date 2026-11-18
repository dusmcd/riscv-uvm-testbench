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

  local function automatic void checkDestinationRegister();
    if (bfm.writedata_WB != bfm.expected) begin
      $error("destination register incorrect. expected=%h got=%h for instruction=%h", bfm.expected, bfm.writedata_WB, bfm.instruction_WB);
    end
  endfunction

  task run_phase(uvm_phase phase);
    forever begin 
      @(posedge bfm.clk)

      if (!$isunknown(bfm.instruction_WB)) begin
        // check reference model against DUT 
        ref_model.decode_and_execute(bfm.instruction_WB, bfm.PC_WB, bfm.instr, bfm.expected);
        if (bfm.valid_WB) checkDestinationRegister();

        case (bfm.pcsrc_WB)
          2'd1: begin
            if (bfm.jal_addr_WB != ref_model.pc) begin
              $error("PC incorrect. expected=%h, got=%h for instruction=%h", ref_model.pc, bfm.jal_addr_WB, bfm.instruction_WB);
            end
          end
          2'd2: begin
            if (bfm.branch_addr_WB != ref_model.pc) begin
              $error("PC incorrect. expected=%h, got=%h for instruction=%h", ref_model.pc, bfm.branch_addr_WB, bfm.instruction_WB);
            end
          end
        endcase
      end
    end 
  endtask

endclass
