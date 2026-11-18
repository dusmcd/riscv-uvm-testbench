class CPUInstruction;
  rand instr_t instr;
  rand bit [4:0] rs1;
  rand bit [4:0] rs2;
  rand bit [4:0] rd;
  rand bit [11:0] imm;
  rand bit [19:0] imm_u;
  rand bit [20:0] imm_joffset;
  rand bit [12:0] imm_boffset;

  constraint valid_registers {
    rd != 5'b0;
  }

  // offsets must be word aligned and cannot exceed the memory range (12 bits)
  constraint valid_offset {
    imm_joffset % 4 == 0;
    imm_joffset inside {[12'h0 : 12'hFFF]};
    imm_boffset % 4 == 0;
    imm_boffset inside {[12'h0 : 12'hFFF]};
  }

  function automatic void create_instr_file(input int num);
    int file = $fopen("tb_instructions.txt", "w");
    if (file == 0)
      $fatal("Could not create file");

    randomize_regs(file);
    for (int i = 0; i < num; i++) begin
      bit [31:0] instruction;
      if (!randomize())
        $fatal("Randomization failed");

      instruction = encode_instr(); 
      $fdisplay(file, "%h", instruction);
      
    end
    $fclose(file);
  endfunction

  local function automatic void randomize_regs(input int file);
    // generate instructions to fill out regfile with random values
    for (int i = 1; i < 32; i++) begin
      if (!randomize())
        $fatal("Randomization failed");

      rd = i;
      instr = ADDI;
      rs1 = 5'b0;
      $fdisplay(file, "%h", encode_instr());
    end
  endfunction

  function automatic void create_raw_instr_file(input int num);
    int file = $fopen("tb_instructions.txt", "w");
    bit [4:0] previous_rd = 5'b0;
    if (file == 0) begin
      $fatal("Could not create instruction file");
    end

    randomize_regs(file);
    repeat(num) begin
      if (!randomize())
        $fatal("Randomization failed");

      if (previous_rd != 5'b0) rs1 = previous_rd;

      $fdisplay(file, "%h", encode_instr());

      previous_rd = rd;

    end
    $fclose(file);

  endfunction


  local function automatic bit [31:0] encode_instr();
    bit [31:0] instruction;
    typedef enum int {RTYPE, ITYPE, UTYPE, JTYPE, BTYPE, NO_OPERANDS} instr_type;
    instr_type instr_type_inst;

    instruction = 32'b0;
    instr_type_inst = NO_OPERANDS;

    case (instr)
      ADD: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b0;
        instr_type_inst = RTYPE;
      end
      SUB: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0100000;
        instruction[14:12] = 3'b0;
        instr_type_inst = RTYPE;
      end
      AND: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b111;
        instr_type_inst = RTYPE;
      end
      OR: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b110;
        instr_type_inst = RTYPE;
      end
      XOR: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b100;
        instr_type_inst = RTYPE;
      end
      SLL: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b001;
        instr_type_inst = RTYPE;
      end
      SRA: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0100000;
        instruction[14:12] = 3'b101;
        instr_type_inst = RTYPE;
      end
      SRL: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b101;
        instr_type_inst = RTYPE;
      end
      SLT: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b010;
        instr_type_inst = RTYPE;
      end
      SLTU: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b011;
        instr_type_inst = RTYPE;
      end
      MUL: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0000001;
        instruction[14:12] = 3'b000;
        instr_type_inst = RTYPE;
      end
      MULH: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0000001;
        instruction[14:12] = 3'b001;
        instr_type_inst = RTYPE;
      end
      MULHU: begin
        instruction[6:0] = 7'b0110011;
        instruction[31:25] = 7'b0000001;
        instruction[14:12] = 3'b011;
        instr_type_inst = RTYPE;
      end
      ADDI: begin
        instruction[6:0] = 7'b0010011;
        instruction[14:12] = 3'b0;
        instr_type_inst = ITYPE;
      end
      ANDI: begin
        instruction[6:0] = 7'b0010011;
        instruction[14:12] = 3'b111;
        instr_type_inst = ITYPE;
      end
      ORI: begin
        instruction[6:0] = 7'b0010011;
        instruction[14:12] = 3'b110;
        instr_type_inst = ITYPE;
      end
      XORI: begin
        instruction[6:0] = 7'b0010011;
        instruction[14:12] = 3'b100;
        instr_type_inst = ITYPE;
      end
      SLLI: begin
        instruction[6:0] = 7'b0010011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b001;
        instr_type_inst = ITYPE;
      end
      SRAI: begin
        instruction[6:0] = 7'b0010011;
        instruction[31:25] = 7'b0100000;
        instruction[14:12] = 3'b101;
        instr_type_inst = ITYPE;
      end
      SRLI: begin
        instruction[6:0] = 7'b0010011;
        instruction[31:25] = 7'b0;
        instruction[14:12] = 3'b101;
        instr_type_inst = ITYPE;
      end
      CSRRW: begin
        instruction[6:0] = 7'b1110011;
        instruction[14:12] = 3'b001;
        instr_type_inst = ITYPE;
      end
      LUI: begin
        instruction[6:0] = 7'b0110111;
        instr_type_inst = UTYPE;
      end
      JAL: begin
        instruction[6:0] = 7'b1101111;
        instr_type_inst = JTYPE;
      end
      BEQ: begin
        instruction[6:0] = 7'b1100011;
        instr_type_inst = BTYPE;
        instruction[14:12] = 3'b000;
      end
      BGE: begin
        instruction[6:0] = 7'b1100011;
        instr_type_inst = BTYPE;
        instruction[14:12] = 3'b101;
      end
      BGEU: begin
        instruction[6:0] = 7'b1100011;
        instr_type_inst = BTYPE;
        instruction[14:12] = 3'b111;
      end
      BLT: begin
        instruction[6:0] = 7'b1100011;
        instr_type_inst = BTYPE;
        instruction[14:12] = 3'b100;
      end
      BLTU: begin
        instruction[6:0] = 7'b1100011;
        instr_type_inst = BTYPE;
        instruction[14:12] = 3'b110;
      end
      NOOP: begin
        instruction = 32'h00000013;
        instr_type_inst = NO_OPERANDS;
      end
      default: begin
        instruction = 32'h00000013;
        instr_type_inst = NO_OPERANDS;
      end
    endcase

    case (instr_type_inst)
      RTYPE: begin
        instruction[19:15] = rs1;
        instruction[24:20] = rs2;
        instruction[11:7] = rd;
      end
      ITYPE: begin
        instruction[19:15] = rs1;
        instruction[11:7] = rd;
        if (instr == SLLI || instr == SRLI || instr == SRAI)
          instruction[24:20] = imm[4:0];
        else
          instruction[31:20] = imm;
      end
      UTYPE: begin
        instruction[11:7] = rd;
        instruction[31:12] = imm_u;
      end
      JTYPE: begin
        instruction[11:7] = rd;
        instruction[31:12] = {imm_joffset[20], imm_joffset[10:1], imm_joffset[11], imm_joffset[19:12]};
      end
      BTYPE: begin
        instruction[19:15] = rs1;
        instruction[24:20] = rs2;
        instruction[31:25] = {imm_boffset[12], imm_boffset[10:5]};
        instruction[11:7] = {imm_boffset[4:1], imm_boffset[11]};
      end
    endcase

    return instruction;
  endfunction



endclass
