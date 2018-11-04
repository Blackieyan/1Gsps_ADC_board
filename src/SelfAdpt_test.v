`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:24:18 09/29/2018 
// Design Name: 
// Module Name:    SelfAdpt_cmd_adpt 
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
module SelfAdpt_test( 
    input 				clk250,
    input 				cmd_adpt_n,
    input 				trig,//monitor the meta-stability
    output 		 		cmd_adpt,//anti jitter
    output  			trig_monitor//anti jitter
    );

	 
///////////////////////signal declaration/////////////////////////////////

////cmd_adpt////	
//(* KEEP="TRUE" *)	 wire 				cmd_adpt_int;
//(* KEEP="TRUE" *)	 reg 					cmd_adpt_buf;
//(* KEEP="TRUE" *)	 reg 					cmd_adpt_buf1;
//(* KEEP="TRUE" *)	 wire 				cmd_adpt_posedge;
//(* KEEP="TRUE" *)	 reg [19:0] 		cnt;
//	 
////trig_output////
	 reg trig_buf;
	 reg trig_buf1;


	assign cmd_adpt = !cmd_adpt_n;
/*
///////////////////////cmd_adpt/////////////////////////////////	 
	assign cmd_adpt_int = cmd_adpt_n;		
	
	always @(posedge clk250) begin
		cmd_adpt_buf<=cmd_adpt_int;
		cmd_adpt_buf1<=cmd_adpt_buf;
	 end
	
	 assign cmd_adpt_posedge = !cmd_adpt_buf1 & cmd_adpt_buf;

	 always @(posedge clk250) begin
		if (cmd_adpt_posedge & (cnt==0)) begin
			cnt<=1;
		end else if(cnt!=0) begin
			if(cnt!=50000001) begin
				cnt<=cnt+1;
			end else begin
				cnt<=0;
			end
		end else begin
			cnt<=0;
		end
	 end

	 always @(posedge clk250) begin
		if(cnt==50000000) begin
			cmd_adpt<=1;
		end else begin
			cmd_adpt<=0;
		end
	 end*/
	 
	 
 ///////////////////////trig_output_monitor/////////////////////////////////
 
	 always @(posedge clk250) begin
		trig_buf<=trig;
		trig_buf1<=trig_buf;
	 end
	 
	 assign trig_monitor = !trig_buf1 & trig_buf;

endmodule
