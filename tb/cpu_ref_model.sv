typedef enum int {RTYPE, ITYPE, UTYPE, JTYPE, BTYPE, NA} instr_types;

class CPUReferenceModel;
  logic [31:0] registers[32];
  logic [11:0] pc;
  logic [4:0] rs1, rs2, rd;
  logic stall_EX;

  function new();
    foreach (registers[i])
      registers[i] = 32'b0;

    pc = 12'b0;
    rs1 = 5'b0;
    rs2 = 5'b0;
    rd = 5'b0;
  endfunction

  function automatic void decode_and_execute(
    input logic [31:0] instruction,
    input logic [11:0] PC_WB,
    output instr_t instr_out
  );
    logic [11:0] imm;
    logic [19:0] imm_u;

    logic [12:0] boffset = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    instr_t instr;

    rs1 = instruction[19:15];
    rs2 = instruction[24:20];
    rd = instruction[11:7];
    imm = instruction[31:20];
    imm_u = instruction[31:12];
    instr = NOOP;
    pc = PC_WB + 12'b1; // default value if no branch taken or no jump instruction
    stall_EX = 1'b0;

    case (instruction[6:0])
      7'b0110011: begin
        // R-type integer and multiply instructions.
        case ({instruction[31:25], instruction[14:12]})
          {7'b0000000, 3'b000}: instr = ADD;
          {7'b0100000, 3'b000}: instr = SUB;
          {7'b0000000, 3'b111}: instr = AND;
          {7'b0000000, 3'b110}: instr = OR;
          {7'b0000000, 3'b100}: instr = XOR;
          {7'b0000000, 3'b001}: instr = SLL;
          {7'b0100000, 3'b101}: instr = SRA;
          {7'b0000000, 3'b101}: instr = SRL;
          {7'b0000000, 3'b010}: instr = SLT;
          {7'b0000000, 3'b011}: instr = SLTU;
          {7'b0000001, 3'b000}: instr = MUL;
          {7'b0000001, 3'b001}: instr = MULH;
          {7'b0000001, 3'b011}: instr = MULHU;
          default: instr = NOOP;
        endcase
      end
      7'b0010011: begin
        // I-type integer instructions.
        case (instruction[14:12])
          3'b000: instr = ADDI;
          3'b111: instr = ANDI;
          3'b110: instr = ORI;
          3'b100: instr = XORI;
          3'b001: begin
            if (instruction[31:25] == 7'b0000000)
              instr = SLLI;
          end
          3'b101: begin
            if (instruction[31:25] == 7'b0100000)
              instr = SRAI;
            else if (instruction[31:25] == 7'b0000000)
              instr = SRLI;
          end
          default: instr = NOOP;
        endcase
      end
      7'b1110011: begin
        // Register form of CSR read/write.
        if (instruction[14:12] == 3'b001)
          instr = CSRRW;
      end
      7'b0110111: begin
        // U-type load upper immediate.
        instr = LUI;
      end
      7'b1101111: begin
        instr = JAL;
      end
      7'b1100011: begin
        // B-type instructions
        case (instruction[14:12])
          3'b000: instr = BEQ;
          3'b101: instr = BGE;
          3'b111: instr = BGEU;
          3'b100: instr = BLT;
          3'b110: instr = BLTU;
        endcase
      end
      default: instr = NOOP;
    endcase

    execute_instruction(instr, imm, imm_u, PC_WB, boffset, instr_out);
  endfunction


  local function automatic void print_instr(
    input instr_t instr,
    input instr_types instr_type,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [11:0] imm,
    input logic [19:0] imm_u
  );
    case (instr_type)
      RTYPE: begin
        $display("%s x%d, x%d, x%d", instr.name(), rd, rs1, rs2);
      end
      ITYPE: begin
        $display("%s x%d, x%d, %d", instr.name(), rd, rs1, imm);
      end
      JTYPE: begin
        $display("%s x%d, %h", instr.name(), rd, imm_u);
      end
      BTYPE: begin
        $display("%s x%d, x%d", instr.name(), rs1, rs2);
      end
      default: $display("instruction not supported for display right now");
    endcase

  endfunction

  local function automatic void execute_instruction(
    input instr_t instr,
    input logic [11:0] imm,
    input logic [19:0] imm_u,
    input logic [11:0] PC_WB,
    input logic [12:0] boffset,
    output instr_t instr_out
  );

    instr_types instr_type;
    instr_type = NA;
    case (instr)
      ADD: begin
        add();
        instr_type = RTYPE;
      end
      SUB: begin
        sub();
        instr_type = RTYPE;
      end
      AND: begin
        and_op();
        instr_type = RTYPE;
      end
      OR: begin
        or_op();
        instr_type = RTYPE;
      end
      XOR: begin
        xor_op();
        instr_type = RTYPE;
      end
      SLL: begin
        sll();
        instr_type = RTYPE;
      end
      SRA: begin
        sra();
        instr_type = RTYPE;
      end
      SRL: begin
        srl();
        instr_type = RTYPE;
      end
      SLT: begin
        slt();
        instr_type = RTYPE;
      end
      SLTU: begin
        sltu();
        instr_type = RTYPE;
      end
      MUL: begin
        mul();
        instr_type = RTYPE;
      end
      MULH: begin
        mulh();
        instr_type = RTYPE;
      end
      MULHU: begin
        mulhu();
        instr_type = RTYPE;
      end
      CSRRW: csrrw(imm);
      ADDI: begin
        addi(imm);
        instr_type = ITYPE;
      end
      ANDI: begin
        andi(imm);
        instr_type = ITYPE;
      end
      ORI: begin
        ori(imm);
        instr_type = ITYPE;
      end
      XORI: begin
        xori(imm);
        instr_type = ITYPE;
      end
      SLLI: begin
        slli(imm);
        instr_type = ITYPE;
      end
      SRAI: begin
        srai(imm);
        instr_type = ITYPE;
      end
      SRLI: begin
        srli(imm);
        instr_type = ITYPE;
      end
      LUI: lui(imm_u);
      JAL: begin
        jal(imm_u, PC_WB);
        instr_type = JTYPE;
      end
      BEQ: begin
        beq(boffset, PC_WB);
        instr_type = BTYPE;
      end
      BGE: begin
        bge(boffset, PC_WB);
        instr_type = BTYPE;
      end
      BGEU: begin
        bgeu(boffset, PC_WB);
        instr_type = BTYPE;
      end
      BLT: begin
        blt(boffset, PC_WB);
        instr_type = BTYPE;
      end
      BLTU: begin
        bltu(boffset, PC_WB);
        instr_type = BTYPE;
      end
      NOOP: ;
    endcase

    registers[0] = 32'b0;
    instr_out = instr;
    // print_instr(instr, instr_type, rs1, rs2, rd, imm, imm_u);
  endfunction

  function automatic void bltu(input logic [12:0] boffset, input logic [11:0] PC_WB);
    if (registers[rs1] < registers[rs2]) begin
      stall_EX = 1'b1; // the instruction currently in execution stage should be stalled if branch is taken
      pc = PC_WB + {boffset[12], boffset[12:2]};
    end
  endfunction


  function automatic void bgeu(input logic [12:0] boffset, input logic [11:0] PC_WB);
    if (registers[rs1] >= registers[rs2]) begin
      stall_EX = 1'b1; // the instruction currently in execution stage should be stalled if branch is taken
      pc = PC_WB + {boffset[12], boffset[12:2]};
    end
  endfunction

  function automatic void blt(input logic [12:0] boffset, input logic [11:0] PC_WB);
    if ($signed(registers[rs1]) < $signed(registers[rs2])) begin
      stall_EX = 1'b1; // the instruction currently in execution stage should be stalled if branch is taken
      pc = PC_WB + {boffset[12], boffset[12:2]};
    end
  endfunction

  function automatic void bge(input logic [12:0] boffset, input logic [11:0] PC_WB);
    if ($signed(registers[rs1]) >= $signed(registers[rs2])) begin
      stall_EX = 1'b1; // the instruction currently in execution stage should be stalled if branch is taken
      pc = PC_WB + {boffset[12], boffset[12:2]};
    end
  endfunction

  function automatic void beq(input logic [12:0] boffset, input logic [11:0] PC_WB);
    if (registers[rs1] == registers[rs2]) begin
      stall_EX = 1'b1; // the instruction currently in execution stage should be stalled if branch is taken
      pc = PC_WB + {boffset[12], boffset[12:2]};
    end
  endfunction

  function automatic void jal(input logic [19:0] imm_u, input logic [11:0] PC_WB);
    logic [20:0] jal_offset = {imm_u[19], imm_u[7:0], imm_u[8], imm_u[18:9], 1'b0};
    pc = PC_WB + jal_offset[13:2];
    registers[rd] = {20'b0, PC_WB + 12'b1};
    stall_EX = 1'b1;
  endfunction

  function automatic void add();
    registers[rd] = registers[rs1] + registers[rs2];
  endfunction

  function automatic void sub();
    registers[rd] = registers[rs1] - registers[rs2];
  endfunction

  function automatic void and_op();
    registers[rd] = registers[rs1] & registers[rs2];
  endfunction

  function automatic void or_op();
    registers[rd] = registers[rs1] | registers[rs2];
  endfunction

  function automatic void xor_op();
    registers[rd] = registers[rs1] ^ registers[rs2];
  endfunction

  function automatic void sll();
    registers[rd] = registers[rs1] << registers[rs2][4:0];
  endfunction

  function automatic void sra();
    registers[rd] = $signed(registers[rs1]) >>> registers[rs2][4:0];
  endfunction

  function automatic void srl();
    registers[rd] = registers[rs1] >> registers[rs2][4:0];
  endfunction

  function automatic void slt();
    registers[rd] = ($signed(registers[rs1]) < $signed(registers[rs2]));
  endfunction

  function automatic void sltu();
    registers[rd] = (registers[rs1] < registers[rs2]);
  endfunction

  function automatic void mul();
    registers[rd] = registers[rs1] * registers[rs2];
  endfunction

  function automatic void mulh();
    logic signed [63:0] product;
    logic signed [63:0] lhs;
    logic signed [63:0] rhs;
    lhs = $signed(registers[rs1]);
    rhs = $signed(registers[rs2]);
    product = lhs * rhs;
    registers[rd] = product[63:32];
  endfunction

  function automatic void mulhu();
    logic [63:0] product;
    logic [63:0] lhs;
    logic [63:0] rhs;
    lhs = registers[rs1];
    rhs = registers[rs2];
    product = lhs * rhs;
    registers[rd] = product[63:32];
  endfunction

  function automatic void csrrw(input logic[11:0] csr);
    /*
      this will not use CSR state, but will serve as a general purpose I/O
    */
  endfunction

  function automatic void addi(input logic [11:0] imm);
    registers[rd] = registers[rs1] + {{20{imm[11]}}, imm};
  endfunction

  function automatic void andi(input logic [11:0] imm);
    registers[rd] = registers[rs1] & {{20{imm[11]}}, imm};
  endfunction

  function automatic void ori(input logic [11:0] imm);
    registers[rd] = registers[rs1] | {{20{imm[11]}}, imm};
  endfunction

  function automatic void xori(input logic [11:0] imm);
    registers[rd] = registers[rs1] ^ {{20{imm[11]}}, imm};
  endfunction

  function automatic void slli(input logic [11:0] imm);
    registers[rd] = registers[rs1] << imm[4:0];
  endfunction

  function automatic void srai(input logic [11:0] imm);
    registers[rd] = $signed(registers[rs1]) >>> imm[4:0];
  endfunction

  function automatic void srli( input logic [11:0] imm);
    registers[rd] = registers[rs1] >> imm[4:0];
  endfunction

  function automatic void lui(input logic [19:0] imm_u);
    registers[rd] = {imm_u, 12'b0};
  endfunction



endclass
