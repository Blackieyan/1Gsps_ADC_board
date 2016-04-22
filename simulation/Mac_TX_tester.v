`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: Photoelectronics Engineering Lab., Quantum Physics & Quantum Information, USTC. PEL@QPQI.USTC
// Engineer: JX
//
// Create Date:   20:18:37 07/29/2014
// Design Name:   Mac_TX
// Module Name:   
// Project Name:  Mac_RX
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Mac_TX
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Mac_TX_tester;

	// Inputs
	reg clk;
	reg Trig_i;
	reg Reset_i;
	reg [7:0] Data_in;
	reg Last_byte;

	// Outputs
	wire Busy;
	wire Data_Strobe;
	wire PHY_TXEN_o;
	wire PHY_GTXCLK_o;
	wire [3:0] PHY_TXD_o;

	// Instantiate the Unit Under Test (UUT)
	Mac_TX uut (
    .clk(clk), 
    .Reset_i(Reset_i), 
	 
    .Trig_i(Trig_i), 
    .Data_in(Data_in), 
    .Last_byte(Last_byte), 
    .Data_Strobe(Data_Strobe), 
    .Busy(Busy), 
	 
    .PHY_TXEN_o(PHY_TXEN_o), 
    .PHY_GTXCLK_o(PHY_GTXCLK_o), 
    .PHY_TXD_o(PHY_TXD_o)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		Trig_i = 0;
		Reset_i = 1;
		Data_in = 8'b0;
		Last_byte = 0;
		

		// Wait 100 ns for global reset to finish
		#100;
		Reset_i = 0;
		
		#100
		Trig_i = 1;
		
		#101
		Trig_i = 0;
		
//		repeat(100) begin
//			Data_in = Data_in + 1;
//			#8;
//		end
//		#1;
//		Last_byte = 1;
//		Data_in = Data_in + 1;
//		#8;
//		Last_byte = 0;
//		Data_in = Data_in + 1;
		
		// Add stimulus here

	end
	
	
	//Last_byte
	always @ (posedge clk)
		Last_byte <= (wr_addr == 'd58);
		
	//wr_addr
	reg[9:0] wr_addr;
	always@(posedge clk)
		if(Reset_i | Last_byte)
			wr_addr <= 0;
		else if(Busy)
			wr_addr <= wr_addr + 1;	//delay mode
	
			
	//wr_data
	reg [7:0] wr_data;
	always@(posedge clk)
		case(wr_addr)
			'd0:	wr_data <= 8'h55;                               
			'd1:	wr_data <= 8'h55;                               
			'd2:	wr_data <= 8'h55;                                   
			'd3:	wr_data <= 8'h55;                                   
			'd4:	wr_data <= 8'h55;                                   
			'd5:	wr_data <= 8'h55;                                   
			'd6:	wr_data <= 8'h55;                                   
			'd7:	wr_data <= 8'hd5;
			                                   
			'd8:	wr_data <= 8'h4b;                                     
			'd9:	wr_data <= 8'h45;                                     
			'd10:	wr_data <= 8'h59;                                 
			'd11:	wr_data <= 8'h00;                                 
			'd12:	wr_data <= 8'h00;                                 
			'd13:	wr_data <= 8'h01;    
			                             
			'd14:	wr_data <= 8'h3c;                                 
			'd15:	wr_data <= 8'h97;                                 
			'd16:	wr_data <= 8'h0e;                                 
			'd17:	wr_data <= 8'h38;                                 
			'd18:	wr_data <= 8'h46;                                 
			'd19:	wr_data <= 8'hf0;    
			                             
			'd20:	wr_data <= 8'h00;                               
			'd21:	wr_data <= 8'h0c;		//ethernet length is 12 byte
			
			'd22:	wr_data <= 8'h42;                                   
			'd23:	wr_data <= 8'h01;		//flag                        
			'd24:	wr_data <= 8'h80; 	//cmd_h                            
			'd25:	wr_data <= 8'h00;	  //cmd_l                            
			'd26:	wr_data <= 8'h00;                                   
			'd27:	wr_data <= 8'h04;		//data length is 4 byte         
			'd28:	wr_data <= 8'h00;                       
			'd29:	wr_data <= 8'h34;		//rst_id                        
			'd30:	wr_data <= 8'h00;		//                  
			'd31:	wr_data <= 8'h00;		//                  
			'd32:	wr_data <= 8'h00;		//                  
			'd33:	wr_data <= 8'h00;		//   addr
			
			//fcs                 
//			'd60:	wr_data <= 8'h12;		//                    
//			'd61:	wr_data <= 8'h34;		//                    
//			'd62:	wr_data <= 8'h56;		//                    
//			'd63:	wr_data <= 8'h78;		//                    
			
           default: 	wr_data <=8'h00;
         endcase	
	
	always @*
		Data_in <= wr_data;
	
	always 
	begin
		clk = 1'b0;
		#4 clk = 1'b1;
		#4;
	end  

      
endmodule

