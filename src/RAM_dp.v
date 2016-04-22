`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Photoelectronics Engineering Lab., Quantum Physics & Quantum Information, USTC. PEL@QPQI.USTC
// Engineer: JX
// 
// Create Date:    14:23:14 08/15/2014 
// Design Name: 
// Module Name:    RAM_sp 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module RAM_dp #(
    
   parameter RAM_WIDTH = 8,			// default byte width
   parameter RAM_ADDR_BITS = 14		// default 
    )(
	//read port
	input 							Rd_Clk,
	input								Rd_en,		// should keep valid during a frame reading
	input	[RAM_ADDR_BITS-1:0]	Rd_Addr,		
	output reg[RAM_WIDTH-1:0]		Rd_data,
	
	//write port
	input 							Wr_Clk,
	input								Wr_en,		// should keep valid during a frame writing
	input	[RAM_ADDR_BITS-1:0]	Wr_Addr,
	input	[RAM_WIDTH-1:0]		Wr_data
    );

   
   (* RAM_STYLE="{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
   reg [RAM_WIDTH-1:0] RAM_reg [(2**RAM_ADDR_BITS)-1:0];
   //  The forllowing code is only necessary if you wish to initialize the RAM 
   //  contents via an external file (use $readmemb for binary data)
//   initial
//      $readmemh("<data_file_name>", <rom_name>, <begin_address>, <end_address>);

						
   always @(posedge Wr_Clk)
		if (Wr_en)
			RAM_reg[Wr_Addr] <= Wr_data;
	
   always @(posedge Rd_Clk)
      if (Rd_en)
            Rd_data <= RAM_reg[Rd_Addr];
						
endmodule
