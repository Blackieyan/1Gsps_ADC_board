
//-----------------------------------------------------------------------------
//  
//  Copyright (c) Photoelectronics Engineering Lab., Quantum Physics & Quantum Information, USTC. PEL@QPQI.USTC
//
//  Designer : JX
//  Created  : 2014-07-27
//
//  Project  : GBE
//  Module   : RGMII_to_GMII.v
//  Children : None
//
//  Description: 
//     
//  Parameters:
//     None
//  Local Parameters:
//     None
//
//  Notes       : 
//
//  Multicycle and False Paths
//     None
//
//`timescale 1ns/1ps

module RGMII_to_GMII(
	//The RGMII RX output pins of PHY, 
  input					RXCLK_i,		// Clock recovered by PHY
  input	[3:0]			RXDATA_i,	// 
  input					RXCTL_i,		//  
  input					reset,
  
  output			GMII_RX_CLK_o,		// the same copy of RXCLK_i

  output [7:0]	GMII_RX_RXD_o,		// 8-bit RX data 
  output			GMII_RX_DV_o,		// RX data valid
  output			GMII_RX_ER_o		// error


 //-----\/----- EXCLUDED -----\/-----
//  output reg[7:0]	GMII_RX_RXD_o,		// 8-bit RX data 
//  output	reg		GMII_RX_DV_o,		// RX data valid
//  output	reg		GMII_RX_ER_o		// error
 //-----/\----- EXCLUDED -----/\----- 

);


   reg[3:0] 	 RXD_neg_reg;
   reg[3:0] 	 RXD_pos_reg;
	reg 			 CTL_neg_reg;	// 
	reg 			 CTL_pos_reg;	// 
	reg[7:0]		RXD_reg;
	reg			DV_reg;
	reg			ER_reg;
	wire			RX_CTL;
					
//***************************************************************************
// Code
//***************************************************************************

	assign GMII_RX_CLK_o = RXCLK_i;
// on rising edge


   always @(posedge RXCLK_i)
	begin
		if (reset)
		begin
			RXD_pos_reg <= 4'b0000;
			CTL_pos_reg <= 1'b0;
			GMII_RX_RXD_o <= 8'b0000_0000;
			GMII_RX_DV_o <= 1'b0;
			GMII_RX_ER_o <= 1'b0;
		end
		else
		begin
			RXD_pos_reg <= RXDATA_i;
			GMII_RX_RXD_o <= {RXD_neg_reg, RXD_pos_reg}; 	// combine to 8-bit data
			
			CTL_pos_reg <= RXCTL_i;
			GMII_RX_DV_o <= CTL_neg_reg;		// Data valid bit is latch at last negative recieve clock edge
			GMII_RX_ER_o <= CTL_neg_reg ^ CTL_pos_reg;
		end //end of if reset
		
	end		// end always	posedge RXCLK_i	

// on falling edge
   always @(negedge RXCLK_i)
	begin
		if(reset)
		begin
			RXD_neg_reg <= 4'b0000;
			CTL_neg_reg <= 1'b0;
		end
		else
		begin
			RXD_neg_reg <= RXDATA_i;
			CTL_neg_reg <= RXCTL_i;
		end
	end		// end always	posedge RXCLK_i	

//	assign GMII_RX_ER_o = RX_CTL ^ GMII_RX_DV_o;


/* -----\/----- EXCLUDED -----\/-----

   genvar i;
   generate
      for (i=0; i < 4; i=i+1) 
      begin: RXD_gen
               IDDR #(
	       .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
               //    or "SAME_EDGE_PIPELINED" 
	       .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	       .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	       .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
	       ) IDDR_inst (
			    .Q1(GMII_RX_RXD_o[i]), // 1-bit output for positive edge of clock 
			    .Q2(GMII_RX_RXD_o[i+4]), // 1-bit output for negative edge of clock
			    .C(RXCLK_i),   // 1-bit clock input
			    .CE(1), // 1-bit clock enable input
			    .D(RXDATA_i[i]),   // 1-bit DDR data input
			    .R(reset),   // 1-bit reset
			    .S(0)    // 1-bit set
			    );
      end
   endgenerate
               IDDR #(
	       .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
               //    or "SAME_EDGE_PIPELINED" 
	       .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
	       .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
	       .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
	       ) IDDR_inst (
			    .Q1(GMII_RX_DV_o), // 1-bit output for positive edge of clock 
			    .Q2(RX_CTL), // 1-bit output for negative edge of clock
			    .C(RXCLK_i),   // 1-bit clock input
			    .CE(1), // 1-bit clock enable input
			    .D(RXCTL_i),   // 1-bit DDR data input
			    .R(reset),   // 1-bit reset
			    .S(0)    // 1-bit set
			    );
 -----/\----- EXCLUDED -----/\----- */



endmodule
