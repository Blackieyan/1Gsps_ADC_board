`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC
// Engineer: SLH
// Create Date:    21:57:32 07/02/2018 
// Module Name:    SelfAdpt 
// Revision 0.01 - File Created


//////////////////////////////////////////////////////////////////////////////////

module SelfAdpt(
							input 				clk250,//250MHz clock for sampling trig signal
							input 				clk200,//200MHz clock for IODELAYE1
							input 				rst_n,
							input   				RDY,// flag indicate that the idelayctrl is ready
							input 				cmd_adpt,// the start command for ADC Self-adaption
							input 				trig_input,// trig input from DAC
							input 				trig_from_trig_ctrl,// trig_posedge from AD Trig_ctrl
							
							output 				trig_output, // trig output from IODELAY
							output reg 			adpt_led //the completion mark for ADC Self-Adaption
    );
	
	
///////////////////////parameter declaration/////////////////////////////////
	
							parameter [19:0] 	CNT_TRIG_INTERVAL=100;
							parameter [19:0] 	CNT_TRIG_COUNT=1000000;
							parameter [4:0] 	TAP_VALUE=31;
							parameter [4:0] 	TAP_DETECT=22;
	
	
///////////////////////signal declaration/////////////////////////////////
	
	////rst////
							wire 					rst;
							reg 					rst_buf;
							reg 					rst_buf1;
	(* KEEP="TRUE" *)	wire 					reset;//posedge of rst for clk200
							reg 					reset_buf;
							reg 					reset_buf1;
							wire 					reset_8ns;//8ns width of rst for clk200
							reg 					reset_8ns_buf;
							reg 					reset_8ns_buf1;
							wire 					reset_clk200;//posedge of rst for clk200
							reg [4:0] 			cnt_rst;	//the count of reset for RST_IDELAYECTRL
						  
  ////cmd_adpt////
	(* KEEP="TRUE" *)	reg 					cmd_adpt_buf;
	(* KEEP="TRUE" *)	reg 					cmd_adpt_buf1;
	(* KEEP="TRUE" *)	wire 					cmd_adpt_posedge;//posedge of cmd_adpt for clk250
	(* KEEP="TRUE" *) reg 					cmd_adpt_posedge_buf;
	(* KEEP="TRUE" *)	reg 					cmd_adpt_posedge_buf1;
	(* KEEP="TRUE" *)	wire 					cmd_adpt_8ns;//8ns width of cmd_adpt for clk200
	(* KEEP="TRUE" *)	reg 					cmd_adpt_8ns_buf;
	(* KEEP="TRUE" *)	reg 					cmd_adpt_8ns_buf1;
	(* KEEP="TRUE" *)	wire 					cmd_adpt_clk200;//posedge of cmd_adpt for clk200
  
  ////adpt_complete////
	 (* KEEP="TRUE" *)reg 					adpt_complete;//the completion mark of ADC Self-Adaption for clk250
							reg 					adpt_complete_buf;
							wire 					adpt_complete_8ns;//8ns width of adpt_complete for clk200
							reg 					adpt_complete_8ns_buf;
							reg 					adpt_complete_8ns_buf1;
							wire 					adpt_complete_clk200;//posedge of adpt_complete for clk250
  
  ////change_tap////
							reg 					change_tap;//the mark for IODELAYE1 to change the tap value under clk250 domain
							reg 					change_tap_buf;
							wire 					change_tap_8ns;//8ns width of change_tap for clk200
							reg 					change_tap_8ns_buf;
							reg 					change_tap_8ns_buf1;
							wire 					change_tap_200M;// posedge of change_tap for clk200
	
  ////IODELAYE1////
	(* KEEP="TRUE" *)	reg 					RST_IDELAYCTRL;//RST for IDELAYECTRL
	(* KEEP="TRUE" *)	reg 					RST_IDELAYE;//RST for IODELAYE1
//	(* KEEP="TRUE" *)	wire 					RDY;// rdy signal from IDELAYECTRL
							wire 					dataout;
							reg 					CE;
	(* KEEP="TRUE" *)	reg 					INC;					  
							reg [4:0]			cntvaluein;

	////trig////
							reg 					trig_from_trig_ctrl_buf;//switch for Self-adaption
	(* KEEP="TRUE" *)	wire 					trig_posedge;//switch for Self-adaption
	(* KEEP="TRUE" *)	reg 					adpt_switch;//switch for Self-adaption

	////detection////
	(* KEEP="TRUE" *)	reg [19:0] 			cnt_trig_interval;
							reg [19:0] 			cnt_trig_count;
							reg [4:0] 			cnt_tap;//the current position of IODELAYE1 tap delay chain
							reg [31:0] 			err_tmp;//record the meta-stability
							wire[63:0] 			err;
							reg 					detect_complete;//the completion mark for detection
	
	////judgement////
							reg 					judge_start;
							reg [5:0] 			cnt_err;
							reg [5:0] 			no_err;//the number of meta-stability
							reg [5:0] 			tap_final;//the final position of IODELAYE1 tap delay chain
	
	
////////////////// rst /////////////////////////////////////////////////
	
	////rst from input////	
	assign rst = !rst_n;
//	assign RDY = 1;
	
	always @(posedge clk250) begin
		rst_buf<=rst;
		rst_buf1<=rst_buf;
	end
	
   assign reset = !rst_buf1 & rst_buf;//posedge of rst for clk250
	
	always @(posedge clk250) begin
		reset_buf<=reset;
		reset_buf1<=reset_buf;
	end
	
	assign reset_8ns = reset_buf1 | reset_buf;//8ns width reset for clk200
	
	always @(posedge clk200) begin
		reset_8ns_buf<=reset_8ns;
		reset_8ns_buf1<=reset_8ns_buf;
	end
	
	assign reset_clk200 = !reset_8ns_buf1 & reset_8ns_buf;//posedge of rst for clk200
	
	
	////RST for IDELAYECTRL////	
	always @(posedge clk250) begin //asynchronous RST for IDELAYRCTRL, needs to be >50ns
		if(reset) begin
			cnt_rst<=1;
			RST_IDELAYCTRL<=1'b1;
		end else if(cnt_rst!=0) begin
			if(cnt_rst!=20) begin 
				cnt_rst<=cnt_rst+1'b1;
			end else begin
				cnt_rst<=0;
				RST_IDELAYCTRL<=0;
			end
		end else begin
			cnt_rst<=0;
			RST_IDELAYCTRL<=0;
		end
	end
	
	
	////RST for IODELAYE1////	
	always @(posedge clk200) begin  //RST for IDELAYE, reset the tap delay to CNTVALUEIN
		if (reset_clk200) begin
			RST_IDELAYE<=0;
		end else if (cmd_adpt_clk200) begin  // when cmd_adpt is active, reset the IDELAYE to CNTVALUEIN
			RST_IDELAYE<=1;
		end else if (adpt_complete_clk200) begin  //when adpt_complete is active,reset the IDELAYE to CNTVALUEIN(tap_final)
			RST_IDELAYE<=1;
		end else begin
			RST_IDELAYE<=0;
		end
	end
	
	
//////////////////////// cmd_adpt //////////////////////////////////////////////////////////////////////
	
	always @(posedge clk250) begin
		cmd_adpt_buf <=cmd_adpt;
		cmd_adpt_buf1 <=cmd_adpt_buf;	
	end

	assign cmd_adpt_posedge = !cmd_adpt_buf1 & cmd_adpt_buf;//posedge of cmd_adpt for clk250
	
	always @(posedge clk250) begin
		cmd_adpt_posedge_buf<=cmd_adpt_posedge;
		cmd_adpt_posedge_buf1<=cmd_adpt_posedge_buf;
	end
	
	assign cmd_adpt_8ns = cmd_adpt_posedge_buf | cmd_adpt_posedge_buf1;  //8ns width of cmd_adpt for clk200
	
	always @(posedge clk200) begin
		cmd_adpt_8ns_buf <= cmd_adpt_8ns;
		cmd_adpt_8ns_buf1 <= cmd_adpt_8ns_buf;
	end
	
	assign cmd_adpt_clk200 = !cmd_adpt_8ns_buf1 & cmd_adpt_8ns_buf;//posedge of cmd_adpt for clk200
	
	
//////////////////IDELAYCTRL & IODELAYE1 /////////////////////////////////////////////////
	
	//// two IODELAYE1 cascade////
   // IDELAYCTRL: IDELAY Tap Delay Value Control
   //             Virtex-6
   // Xilinx HDL Language Template, version 13.3

	//   (* IODELAY_GROUP = "IDELAYCTRL_X0Y4" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
//   IDELAYCTRL IDELAYCTRL_inst (
//      .RDY(RDY),       // 1-bit Ready output
//      .REFCLK(clk200), // 1-bit Reference clock input
//      .RST(RST_IDELAYCTRL)        // 1-bit Reset input
//   );

   
   // IODELAYE1: Input / Output Fixed or Variable Delay Element
   //            Virtex-6
   // Xilinx HDL Language Template, version 13.3

   IODELAYE1 #(
      .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (TRUE/FALSE)
      .DELAY_SRC("I"),                 // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
      .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter (TRUE), Reduced power (FALSE)
      .IDELAY_TYPE("VAR_LOADABLE"),         // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
      .IDELAY_VALUE(0),                // Input delay tap setting (0-31)
      .ODELAY_TYPE("FIXED"),           // "FIXED", "VARIABLE", or "VAR_LOADABLE" 
      .ODELAY_VALUE(0),                // Output delay tap setting (0-31)
      .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz
      .SIGNAL_PATTERN("DATA")          // "DATA" or "CLOCK" input signal
   )
   IODELAYE1_inst (
      .CNTVALUEOUT(), // 5-bit output: Counter value output
      .DATAOUT(dataout),         // 1-bit output: Delayed data output
      .C(clk200),                     // 1-bit input: Clock input
      .CE(CE),                   // 1-bit input: Active high enable increment/decrement input
      .CINVCTRL(1'b0),       // 1-bit input: Dynamic clock inversion input
      .CLKIN(),             // 1-bit input: Clock delay input
      .CNTVALUEIN(cntvaluein),   // 5-bit input: Counter value input
      .DATAIN(),           // 1-bit input: Internal delay data input
      .IDATAIN(trig_input),         // 1-bit input: Data input from the I/O
      .INC(INC),                 // 1-bit input: Increment / Decrement tap delay input
      .ODATAIN(),         // 1-bit input: Output delay data input
      .RST(RST_IDELAYE),                 // 1-bit input: Active-high reset tap-delay input
      .T()                      // 1-bit input: 3-state input
   );
	
	
	IODELAYE1 #(
      .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (TRUE/FALSE)
      .DELAY_SRC("DATAIN"),                 // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
      .HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter (TRUE), Reduced power (FALSE)
      .IDELAY_TYPE("VAR_LOADABLE"),         // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
      .IDELAY_VALUE(0),                // Input delay tap setting (0-31)
      .ODELAY_TYPE("VAR_LOADABLE"),           // "FIXED", "VARIABLE", or "VAR_LOADABLE" 
      .ODELAY_VALUE(0),                // Output delay tap setting (0-31)
      .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz
      .SIGNAL_PATTERN("DATA")          // "DATA" or "CLOCK" input signal
   )
   IODELAYE1_inst2 (
      .CNTVALUEOUT(), // 5-bit output: Counter value output
      .DATAOUT(trig_output),         // 1-bit output: Delayed data output
      .C(clk200),                     // 1-bit input: Clock input
      .CE(CE),                   // 1-bit input: Active high enable increment/decrement input
      .CINVCTRL(1'b0),       // 1-bit input: Dynamic clock inversion input
      .CLKIN(),             // 1-bit input: Clock delay input
      .CNTVALUEIN(cntvaluein),   // 5-bit input: Counter value input
      .DATAIN(dataout),// 1-bit input: Internal delay data input
      .IDATAIN(),         // 1-bit input: Data input from the I/O
      .INC(INC),                 // 1-bit input: Increment / Decrement tap delay input
      .ODATAIN(),         // 1-bit input: Output delay data input
      .RST(RST_IDELAYE),                 // 1-bit input: Active-high reset tap-delay input
      .T()                      // 1-bit input: 3-state input
   );
	
	
	////CE,INC,cnt_tap////	
	always @(posedge clk200) begin  
		if(reset_clk200) begin
			cnt_tap<=0;//record the current position of tap delay chain
			CE<=0;
			INC<=0;//increment the tap delay line
		end else if(cmd_adpt_clk200) begin
			cnt_tap<=0;
			CE<=0;
			INC<=0;
		end else if(change_tap_200M) begin
			if(cnt_tap !=TAP_VALUE) begin
				cnt_tap<=cnt_tap+1'b1;
				CE<=1;  
				INC<=1;
			end 
		end else begin
			CE<=0;
			INC<=0;
		end
	end

	
	////cntvaluein////	
	always @(posedge clk250) begin //CNTVALUEIN for IDELAYE
		if(reset) begin
			cntvaluein<=0;
		end else if (cmd_adpt_posedge) begin
			cntvaluein<=0;
		end else begin
			cntvaluein<=tap_final[4:0];//the final position of tap delay chain after ADC Self_adaption
		end
	end
	

////////////////////////////trig for ADC sampling and detection///////////////////////////////////////////////	
	
	////adpt_switch////	
	always @(posedge clk250) begin // switch for Self_adption 0: detection off  1£ºdetection on
		if(reset) begin
			adpt_switch<=0; 
		end else if(cmd_adpt_posedge & (RDY==1)) begin
			adpt_switch<=1;// trig detection on
		end else if(adpt_complete) begin
			adpt_switch<=0;
 		end
	end
	
////////////////////////////detection///////////////////////////////////////////////////////////////////////////	
	////trig////
	always @(posedge clk250) begin
		trig_from_trig_ctrl_buf <=trig_from_trig_ctrl;
	end
	
	assign trig_posedge = !trig_from_trig_ctrl_buf & trig_from_trig_ctrl;

	////detect////	
	always @(posedge clk250) begin  // record the interval of trig
		if(reset) begin
			cnt_trig_interval<=0;
		end else if(cmd_adpt_posedge) begin
			cnt_trig_interval<=0;
		end else if(trig_posedge & adpt_switch) begin
			if(cnt_trig_count !=(CNT_TRIG_COUNT-1)) begin
				cnt_trig_interval<=1;
			end else begin
				cnt_trig_interval<=0;
			end
		end else if(cnt_trig_interval!=0) begin
			cnt_trig_interval<=cnt_trig_interval+1'b1;
		end
	end
			
	always @(posedge clk250) begin //record the count of trig
		if(reset) begin
			cnt_trig_count<=0;
		end else if(cmd_adpt_posedge) begin
			cnt_trig_count<=0;
		end else if(trig_posedge & adpt_switch & (cnt_trig_count!=CNT_TRIG_COUNT)) begin
			cnt_trig_count<=cnt_trig_count+1'b1;
		end else if(cnt_trig_count==CNT_TRIG_COUNT)begin //8ns width for clk200
			cnt_trig_count<=0;
		end 
	end
	
	
	/////change_tap////
	always @(posedge clk250) begin//the mark for IODELAYE1 to change the tap value
		if(reset) begin
			change_tap<=0;
		end else if(cmd_adpt_posedge) begin
			change_tap<=0;
		end else if(cnt_trig_count==CNT_TRIG_COUNT) begin
			change_tap<=1'b1;
		end else begin
			change_tap<=0;
		end
	end
	
	always @(posedge clk250) begin
		change_tap_buf<=change_tap;
	end
		
	assign change_tap_8ns = change_tap_buf | change_tap;	//8ns width of change_tap for clk200
	
	always @(posedge clk200) begin
		change_tap_8ns_buf<=change_tap_8ns;
		change_tap_8ns_buf1<=change_tap_8ns_buf;
	end
	
	assign change_tap_200M = !change_tap_8ns_buf1 & change_tap_8ns_buf;//posedge of change_tap for clk200		
		
	
	////record the meta-stability////	
	always @(posedge clk250) begin  // record the position of meta-stability
		if (reset) begin
			err_tmp<=0;
		end else if (cmd_adpt_posedge) begin
			err_tmp<=0;
		end else if (trig_posedge & (cnt_trig_interval!=0)) begin
			if (cnt_trig_interval != CNT_TRIG_INTERVAL) begin
				err_tmp[cnt_tap]<=1;
			end
		end
	end
	
	assign err ={err_tmp,err_tmp};
	
	
	////detect_complete////	
	always @(posedge clk250) begin  // trig detect complete
		if(reset) begin
			detect_complete<=0;
		end else if(cmd_adpt_posedge) begin
			detect_complete<=0;
		end else if ((cnt_trig_count==CNT_TRIG_COUNT) & (cnt_tap==TAP_VALUE))begin
			detect_complete<=1;
		end else begin
			detect_complete<=0;
		end
	end
			
	
////////////////////////////judgement////////////////////////////////////////////////////////////////////	
	
	////judge_start////	
	always @(posedge clk250) begin  // generate cnt_err for reading err
		if (reset) begin
			cnt_err<=0;
		end else if(cmd_adpt_posedge) begin
			cnt_err<=0;
		end else if(detect_complete) begin
			cnt_err<=1;
		end else if (cnt_err!=0) begin
			if(cnt_err!=2*(TAP_VALUE+1)) begin
				cnt_err<=cnt_err+1'b1;
			end else begin
				cnt_err<=0;
			end
		end
	end
	
	always @(posedge clk250) begin  //the mark for judgement
		if (reset) begin
			judge_start<=0;
		end else if(cmd_adpt_posedge) begin
			judge_start<=0;
		end else if(detect_complete) begin
			judge_start<=1;
		end else if (cnt_err==2*TAP_VALUE) begin
			judge_start<=0;
		end
	end
	
	
	////judge the meta_stability////	
	always @(posedge clk250) begin  //find the position for stability
		if(reset) begin
			no_err<=0;
			adpt_complete<=0;
			tap_final<=0;
		end else if(cmd_adpt_posedge) begin
			no_err<=0;
			adpt_complete<=0;
			tap_final<=0;
		end else if((judge_start) & (cnt_trig_count==0)) begin//setting (cnt_trig_count==0) is a protect mechanism in case of trig_count error from DAC
			if(err[cnt_err-1]==0) begin//when judge_start=1,cnt_err=1~64
				no_err<=no_err+1'b1;
				adpt_complete<=0;
			end else if(no_err>TAP_DETECT) begin
				no_err<=0;
				adpt_complete<=1;
				if((cnt_err-(no_err>>1))>32) begin//(cnt_err-1)-(no_err>>1)>31
					tap_final<=cnt_err-(no_err>>1)-6'b100000;//cnt_err-32
				end else begin
					tap_final<=cnt_err-6'b000001-(no_err>>1);
				end
			end else begin
				no_err<=0;
				adpt_complete<=0;
			end
		end
	end
	
	
	////adpt_complete////	
	always @(posedge clk250) begin
		adpt_complete_buf<=adpt_complete;
	end
	
	assign adpt_complete_8ns = adpt_complete | adpt_complete_buf;  //8ns width of adpt_complete for clk200
	
	always @(posedge clk200) begin
		adpt_complete_8ns_buf <= adpt_complete_8ns;
		adpt_complete_8ns_buf1 <= adpt_complete_8ns_buf;
	end
	
	assign adpt_complete_clk200 = !adpt_complete_8ns_buf1 & adpt_complete_8ns_buf;//posedge of adpt_complete for clk200
	
	always @(posedge clk250) begin // the completion mark for self_adaption  0: led off, Self_adaption is uncompleted 1: led on,Self_adption is completed
		if (reset) begin
			adpt_led<=0;
		end else if(cmd_adpt_posedge) begin  // posedge of the cmd_adpt, self_adaption start
			adpt_led<=0;
		end else if(adpt_complete) begin // self_adaption complete
			adpt_led<=1;
		end 
	end
	
endmodule
