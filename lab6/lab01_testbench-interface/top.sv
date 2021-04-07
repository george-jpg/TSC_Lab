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
  
	// instantiate the testbench interface
  tb_ifc itfc (.clk(clk));

	// connect interface to testbench
  instr_register_test test (.itfc(itfc));

  // instantiate testbench and connect ports

  // instantiate design and connect ports
  instr_register dut (
    .clk(clk),
    .load_en(itfc.load_en),
    .reset_n(itfc.reset_n),
    .operand_a(itfc.operand_a),
    .operand_b(itfc.operand_b),
    .opcode(itfc.opcode),
    .write_pointer(itfc.write_pointer),
    .read_pointer(itfc.read_pointer),
    .instruction_word(itfc.instruction_word)
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
