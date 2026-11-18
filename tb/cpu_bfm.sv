import cpu_tb_pkg::instr_t;

interface cpu_bfm(
  input logic [31:0] dut_instruction_EX,
  input logic [31:0] dut_writedata_WB,
  input logic [11:0] dut_PC_EX,
  input logic [31:0] dut_jal_addr_EX,
  input logic [1:0] dut_pcsrc_EX,
  input logic dut_stall_EX
);
  bit clk;
	logic [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7;
	logic [3:0] KEY;
	logic [17:0] SW;
  logic [31:0] expected;
  logic [31:0] instruction_WB;
  logic [31:0] instruction_EX;
  logic [31:0] writedata_WB;
  logic [11:0] PC_EX;
  logic [11:0] PC_WB;
  logic [31:0] jal_addr_EX;
  logic [31:0] jal_addr_WB;
  logic [1:0] pcsrc_EX;
  logic [1:0] pcsrc_WB;
  logic stall_EX;
  bit valid_WB;
  instr_t instr;
  bit done;
  bit load_instr_request = 0;
  bit load_instr_done = 0;
  int num_instructions;

  // drive clock
  initial begin
    forever begin
      #5 clk = ~clk;
    end
  end

  // drive bfm signals from dut
  assign instruction_EX = dut_instruction_EX;
  assign writedata_WB = dut_writedata_WB;
  assign PC_EX = dut_PC_EX;
  assign jal_addr_EX = dut_jal_addr_EX;
  assign pcsrc_EX = dut_pcsrc_EX;
  assign stall_EX = dut_stall_EX;


  task reset_cpu();
    KEY = 4'b1110;
    #10;
    KEY = 4'b1111;
  endtask

  task load_instructions();
    load_instr_done = 0;
    load_instr_request = 1;

    wait(load_instr_done);
    load_instr_request = 0;
  endtask

endinterface
