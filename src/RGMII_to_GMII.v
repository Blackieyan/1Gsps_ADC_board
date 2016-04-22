
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
  output reg[7:0]	GMII_RX_RXD_o,		// 8-bit RX data 
  output	reg		GMII_RX_DV_o,		// RX data valid
  output	reg		GMII_RX_ER_o		// error

);


   reg[3:0] 	 RXD_neg_reg;
   reg[3:0] 	 RXD_pos_reg;
	reg 			 CTL_neg_reg;	// 
	reg 			 CTL_pos_reg;	// 
	reg[7:0]		RXD_reg;
	reg			DV_reg;
	reg			ER_reg;
					
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



endmodule
