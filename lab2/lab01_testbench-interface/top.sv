/***********************************************************************
 * A SystemVerilog top-level netlist to connect testbench to DUT
 **********************************************************************/

module top;
  timeunit 1ns/1ns;

  // user-defined types are defined in instr_register_pkg.sv
  import instr_register_pkg::*;

  // clock variables
  logic clk;
  logic test_clk;



tb_ifc tbif (
  .clk(test_clk)
  );




  // instantiate testbench and connect ports
  instr_register_test test (
    .clk(test_clk),
    .load_en(tbif.load_en),
    .reset_n(tbif.reset_n),
    .operand_a(tbif.operand_a),
    .operand_b(tbif.operand_b),
    .opcode(tbif.opcode),
    .write_pointer(tbif.write_pointer),
    .read_pointer(tbif.read_pointer),
    .instruction_word(tbif.instruction_word)
   );

  // instantiate design and connect ports
  instr_register dut (
    .clk(clk),
    .load_en(tbif.load_en),
    .reset_n(tbif.reset_n),
    .operand_a(tbif.operand_a),
    .operand_b(tbif.operand_b),
    .opcode(tbif.opcode),
    .write_pointer(tbif.write_pointer),
    .read_pointer(tbif.read_pointer),
    .instruction_word(tbif.instruction_word)
   );

  // clock oscillators
  initial begin
    clk <= 0;
    forever #5  clk = ~clk;
  end

  initial begin
    test_clk <=0;
    // offset test_clk edges from clk to prevent races between
    // the testbench and the design
    #4 forever begin
      #2ns test_clk = 1'b1;
      #8ns test_clk = 1'b0;
    end
  end

endmodule: top
