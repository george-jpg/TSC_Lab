/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/
 
module instr_register_test (tb_ifc itfc);  // interface port

  timeunit 1ns/1ns;

  // user-defined types are defined in instr_register_pkg.sv
  import instr_register_pkg::*;

  int seed = 555;

  class Transaction;
   rand  operand_t operand_a ;
   rand operand_t operand_b;
   rand opcode_t opcode;
   address_t   write_pointer;

   constraint const_operand_a{
   
    operand_a >= -15;
	operand_a <=15;
	};
	
	constraint const_operand_b{

       
    operand_b >= 0;
	operand_b <=15;
	};
	
	


  // function void randomize_transaction();
    // static int temp = 0;
    // operand_a     = $random(seed)%16;                 // between -15 and 15
    // operand_b     = $unsigned($random)%16;            // between 0 and 15
    // opcode        = opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
    // write_pointer = temp++;
  // endfunction : randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction
  endclass: Transaction

// -------------------------------- //

  class Driver;
  virtual tb_ifc vifc;
  Transaction tr;
  
  covergroup inputs_measure;
  
   cov_0: coverpoint vifc.cb.opcode {
   bins val_Zero = {ZERO};
   bins val_passA= {PASSA};
   bins val_passB= {PASSB};
   bins val_add= {ADD};
   bins val_sub= {SUB};
   bins val_mult= {MULT};
   bins val_div= {DIV};
   bins val_mod= {MOD};
   }
   cov_1: coverpoint vifc.cb.operand_a{
   
   bins val_op_a [] = {[-15:15]};
   }
   
   cov_2: coverpoint vifc.cb.operand_b{
   
   bins val_op_b [] = {[0:15]};
   
   }
   
   cov_3: coverpoint vifc.cb.operand_a{
   
   bins val_op_a_neg [] = {[-15:-1]};
   bins val_op_a_poz [] = {[0:15]};
   
   }
     
   cov_4: cross cov_0, cov_3{
   
   ignore_bins poz_ignore = binsof (cov_3.val_op_a_poz);
   
   }
   
   cov_5_1: coverpoint vifc.cb.operand_a{
   
   bins val_op_a_15 [] ={15};
   bins val_op_a_min15 [] ={-15};
   
   }
   
   cov_5_2: coverpoint vifc.cb.operand_b{
   
   bins val_op_b_0 [] = {0};
   bins val_op_b_15 [] = {15};
   
   }
   
    cov_5: cross cov_0, cov_5_1, cov_5_2{
   
   }
   
   cov_6: cross cov_0,cov_5_1, cov_5_2{
   
    ignore_bins max_a_ignore = binsof(cov_5_1.val_op_a_15);
	ignore_bins max_b_ignore = binsof(cov_5_2.val_op_b_15);
	}
   
   
   
   cov_7: cross cov_0, cov_3{
   
   ignore_bins poz_ignore = binsof (cov_3.val_op_a_neg);
   
   }
   
   cov_8_1: coverpoint vifc.cb.operand_a{
			bins val_op_a_0 ={0};
			}
   
   
   cov_8: cross cov_8_1, cov_5_2{
   
		ignore_bins not_zero_ignore =binsof (cov_5_2.val_op_b_15);
		}
   
   endgroup
   
    function new(virtual tb_ifc vifc);
      this.vifc = vifc;
      tr = new();
	  inputs_measure = new();
    endfunction 

task reset_signals();
 vifc.cb.write_pointer   <= 5'h00;      // initialize write pointer
      vifc.cb.read_pointer    <= 5'h1F;      // initialize read pointer
      vifc.cb.load_en         <= 1'b0;       // initialize load control line
      vifc.cb.reset_n         <= 1'b0;       // assert reset_n (active low)
      repeat (2) @(vifc.cb) ;                // hold in reset for 2 clock cycles
      vifc.cb.reset_n         <= 1'b1;       // deassert reset_n (active low)
	  endtask
	  
	  function assign_signals();
	  static int temp =0;
  vifc.cb.operand_a <= tr.operand_a;
        vifc.cb.operand_b <= tr.operand_b;
        vifc.cb.opcode <= tr.opcode;
        vifc.cb.write_pointer <= temp++;
		
		endfunction


    task generate_transaction();
	reset_signals();
	
      $display("\nWriting values to register stack...");
      @vifc.cb vifc.cb.load_en <= 1'b1;      // enable writing to register
      repeat (3) begin
        @(vifc.cb) tr.randomize();
		assign_signals();
        
        @(vifc.cb) tr.print_transaction();
		inputs_measure.sample;
      end
      @vifc.cb vifc.cb.load_en <= 1'b0;  	  // turn-off writing to register
	  
	  

    endtask
	
	
  endclass: Driver

  // -------------------------------- //

  class Monitor;
    virtual tb_ifc vifc;

    function new(virtual tb_ifc vifc);
      this.vifc = vifc;
    endfunction

    function void print_results;
      $display("Read from register location %0d: ", vifc.cb.read_pointer);
      $display("  opcode = %0d (%s)", vifc.cb.instruction_word.opc, itfc.cb.instruction_word.opc.name);
      $display("  operand_a = %0d",   vifc.cb.instruction_word.op_a);
      $display("  operand_b = %0d\n", vifc.cb.instruction_word.op_b);
    endfunction: print_results

    task transaction_monitor();
      $display("\nReading back the same register locations written...");
      for (int i=0; i<=2; i++) begin
        @(this.vifc.cb) this.vifc.cb.read_pointer <= i;
        @(this.vifc.cb) this.print_results();
      end
    endtask
  endclass: Monitor

  // --------------------------------- //

  initial begin
    
    Driver driver;
    Monitor monitor;

    driver = new(itfc);
    monitor = new(itfc);

    driver.generate_transaction();
    monitor.transaction_monitor();

    @(itfc.cb) $finish;

  end

	  
	  
	  


  // initial begin
    // $display("\n\n***********************************************************");
    // $display(    "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    // $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    // $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    // $display(    "***********************************************************");

    // $display("\nReseting the instruction register...");
    // itfc.cb.write_pointer  <= 5'h00;         // initialize write pointer
    // itfc.cb.read_pointer   <= 5'h1F;         // initialize read pointer
    // itfc.cb.load_en        <= 1'b0;          // initialize load control line
    // itfc.cb.reset_n       <= 1'b0;          // assert reset_n (active low)
    // repeat (2) @itfc.cb ;     // hold in reset for 2 clock cycles
    // itfc.cb.reset_n        <= 1'b1;          // deassert reset_n (active low)

    // $display("\nWriting values to register stack...");
    // @itfc.cb itfc.cb.load_en <= 1'b1;  // enable writing to register
    // repeat (3) begin
      // @itfc.cb randomize_transaction;
      // @itfc.cb print_transaction;
    // end
    // @itfc.cb itfc.cb.load_en <= 1'b0;  // turn-off writing to register

    // // read back and display same three register locations
    // $display("\nReading back the same register locations written...");
    // for (int i=0; i<=2; i++) begin
      // // later labs will replace this loop with iterating through a
      // // scoreboard to determine which addresses were written and
      // // the expected values to be read back
      // @itfc.cb itfc.cb.read_pointer <= i;
      // @itfc.cb print_results;
    // end

    // @itfc.cb ;
    // $display("\n***********************************************************");
    // $display(  "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    // $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    // $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    // $display(  "***********************************************************\n");
    // $finish;
  // end

  // function void randomize_transaction;
    // // A later lab will replace this function with SystemVerilog
    // // constrained random values
    // //
    // // The stactic temp variable is required in order to write to fixed
    // // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // // write_pointer values in a later lab
    // //
    // static int temp = 0;
    // itfc.cb.operand_a     <= $random(seed)%16;                 // between -15 and 15
    // itfc.cb.operand_b     <= $unsigned($random)%16;            // between 0 and 15
    // itfc.cb.opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
    // itfc.cb.write_pointer <= temp++;
  // endfunction: randomize_transaction

  // function void print_transaction;
    // $display("Writing to register location %0d: ", itfc.cb.write_pointer);
    // $display("  opcode = %0d (%s)", itfc.cb.opcode, itfc.cb.opcode.name);
    // $display("  operand_a = %0d",   itfc.cb.operand_a);
    // $display("  operand_b = %0d\n", itfc.cb.operand_b);
  // endfunction: print_transaction

  // function void print_results;
    // $display("Read from register location %0d: ", itfc.cb.read_pointer);
    // $display("  opcode = %0d (%s)", itfc.cb.instruction_word.opc, itfc.cb.instruction_word.opc.name);
    // $display("  operand_a = %0d",   itfc.cb.instruction_word.op_a);
    // $display("  operand_b = %0d\n", itfc.cb.instruction_word.op_b);
  // endfunction: print_results

endmodule: instr_register_test
