`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: Photoelectronics Engineering Lab., Quantum Physics & Quantum Information, USTC. PEL@QPQI.USTC
// Engineer: JX
//
// Create Date:   15:22:37 08/16/2014
// Design Name:   Mac_RX2
// Module Name:   
// Project Name:  FE_2566_GBE
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Mac_RX2
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Mac_RX2_tester;

	// Inputs
	reg reset;
	reg Rd_Clk;
	reg Rd_en;
	reg [13:0] Rd_Addr;
	reg [3:0] PHY_RXD;
	reg PHY_RXC;
	reg PHY_RXDV;

	// Outputs
	wire [7:0] Rd_data;
	wire Frm_valid;

	// Instantiate the Unit Under Test (UUT)
	Mac_RX2 uut (
		.reset(reset), 
		.Rd_Clk(Rd_Clk), 
		.Rd_en(Rd_en), 
		.Rd_Addr(Rd_Addr), 
		.Rd_data(Rd_data), 
		.Frm_valid(Frm_valid), 
		.PHY_RXD(PHY_RXD), 
		.PHY_RXC(PHY_RXC), 
		.PHY_RXDV(PHY_RXDV)
	);

	initial begin
		// Initialize Inputs
		reset = 0;
		Rd_Clk = 0;
		Rd_en = 0;
		Rd_Addr = 0;
		PHY_RXD = 0;
		PHY_RXC = 0;
		PHY_RXDV = 0;

		// Wait 100 ns for global reset to finish
		#100;
		#100;
      reset = 1;
		#100;
		reset = 0;
		#100;
		@(negedge PHY_RXC)
		#2;
		PHY_RXDV = 1;
  	    repeat (4) begin
			PHY_RXD = 4'hf;
     #4;
     end
		repeat (15) begin
			PHY_RXD = 4'h5;
			#4;
		end
		PHY_RXD = 4'hd;
		#4;
		repeat (18) begin
			PHY_RXD = 4'ha;
			#4;
		end
		PHY_RXD = 4'h2;
		#4;
		PHY_RXD = 4'h0;
		#4;
		PHY_RXD = 4'h0;
		#4;
		PHY_RXD = 4'h0;
		#4;
		PHY_RXD = 4'h1;
		#4;
		PHY_RXD = 4'h0;
		#4;
		PHY_RXD = 4'h0;
		#4;
		PHY_RXD = 4'h0;
		#4;
/* -----\/----- EXCLUDED -----\/-----
	   	PHY_RXD = 4'h5;
		#4;
		PHY_RXD = 4'h5;
		#4;
 -----/\----- EXCLUDED -----/\----- */
		repeat (94) begin
			PHY_RXD = 4'h0;
			#4;
		end
		PHY_RXD = 4'h1;//4'h8;
		#4;                   
		PHY_RXD = 4'h3;//4'h9;
		#4;                   
		PHY_RXD = 4'he;//4'hd;
		#4;                   
		PHY_RXD = 4'hd;//4'hf;
		#4;                   
		PHY_RXD = 4'hb;//4'he;
		#4;                   
		PHY_RXD = 4'h9;//4'h8;
		#4;                   
		PHY_RXD = 4'h9;//4'h8;
		#4;                   
		PHY_RXD = 4'ha;//4'hf;
		#4;
		
		PHY_RXDV = 0;
		
		#100;
		@(posedge Rd_Clk);
		#1;
		Rd_en = 1;
		Rd_Addr = 0;
		repeat (80)
		begin
			@(posedge Rd_Clk);
			#1;
			Rd_Addr = Rd_Addr + 1;
			
		end
		
		#300;
		Rd_en = 0;
		
		
		// Add stimulus here

	end
	
   always begin
      PHY_RXC = 1'b0;
      #4 PHY_RXC = 1'b1;
      #4;
   end  
   always begin
      Rd_Clk = 1'b0;
      #7 Rd_Clk = 1'b1;
      #7;
   end  
      
endmodule

