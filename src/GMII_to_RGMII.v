
//-----------------------------------------------------------------------------
//  
//  Copyright (c) Photoelectronics Engineering Lab., Quantum Physics & Quantum Information, USTC. PEL@QPQI.USTC
//
//  Designer : JX
//  Created  : 2014-07-29
//
//  Project  : GBE
//  Module   : GMII_to_RGMII.v
//  Children : None
//
//  Description: 
//     convert the 8-bit GMII interface to 4-bit DDR-like interface
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

module GMII_to_RGMII(

  input					GMII_TX_CLK_i,		// 125MHz clock, continuous
  input [7:0]			GMII_TX_TXD_i,		// 8-bit TX data 
  input					GMII_TX_EN_i,		// TX data valid
  input					GMII_TX_ER_i,	// error
  
	//The RGMII TX input pins of PHY, 
  output 			PHY_GTXCLK_o,		// Clock to PHY, the same as GMII_TX_CLK_i, should be continuous to make PHY work, 
  output	[3:0]		PHY_TXD_o,			// 
  output				PHY_TXEN_o			// TX enable and Err control
  

);

	// output clock
   ODDR2 #(
      .DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1" 
      .INIT(1'b0),    			// Sets initial state of the Q output to 1'b0 or 1'b1
      .SRTYPE("SYNC")			// Specifies "SYNC" or "ASYNC" set/reset
   ) u_TXC (
      .Q(PHY_GTXCLK_o),     	// 1-bit DDR output data
      .C0(GMII_TX_CLK_i),  	// 1-bit clock input
      .C1(~GMII_TX_CLK_i), 	// 1-bit clock input
      .CE(1'b1),      			// 1-bit clock enable input
      .D0(1'b0), 					// 1-bit data input (associated with C0)
      .D1(1'b1), 					// 1-bit data input (associated with C1)
      .R(1'b0),   				// 1-bit reset input
      .S(1'b0)   					// 1-bit set input
   );

	// output TXCTL
   ODDR2 #(
      .DDR_ALIGNMENT("NONE"), 			// Sets output alignment to "NONE", "C0" or "C1" 
      .INIT(1'b0),    						// Sets initial state of the Q output to 1'b0 or 1'b1
      .SRTYPE("SYNC")						// Specifies "SYNC" or "ASYNC" set/reset
   ) u_TXCTL (
      .Q(PHY_TXEN_o),     					// 1-bit DDR output data
      .C0(GMII_TX_CLK_i),  				// 1-bit clock input
      .C1(~GMII_TX_CLK_i), 				// 1-bit clock input
      .CE(1'b1),      						// 1-bit clock enable input
      .D0(GMII_TX_EN_i^GMII_TX_ER_i), 					// 1-bit data input (associated with C0)
      .D1(GMII_TX_EN_i), 	// 1-bit data input (associated with C1)
      .R(1'b0),   							// 1-bit reset input
      .S(1'b0)   								// 1-bit set input
   );

	// output data
   genvar i;
   generate
      for (i=0; i < 4; i=i+1) 
      begin : txdata_out
			ODDR2 #(
				.DDR_ALIGNMENT("NONE"), 	// Sets output alignment to "NONE", "C0" or "C1" 
				.INIT(1'b0),    				// Sets initial state of the Q output to 1'b0 or 1'b1
				.SRTYPE("SYNC") 				// Specifies "SYNC" or "ASYNC" set/reset
			) u_TXD (
				.Q(PHY_TXD_o[i]),     		// 1-bit DDR output data
				.C0(GMII_TX_CLK_i),  		// 1-bit clock input
				.C1(~GMII_TX_CLK_i), 		// 1-bit clock input
				.CE(1'b1),      				// 1-bit clock enable input
				.D0(GMII_TX_TXD_i[i+4]), 		// 1-bit data input (associated with C0)
				.D1(GMII_TX_TXD_i[i]), 	// 1-bit data input (associated with C1)
				.R(1'b0),   					// 1-bit reset input
				.S(1'b0)   						// 1-bit set input
			);
      end
   endgenerate
	


endmodule
