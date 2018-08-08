`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   08:38:16 07/14/2018
// Design Name:   Dmod_Seg
// Module Name:   C:/Current_Key_Projects/1Gsps_ADC_board_V4_algromth/Dmod_Seg_tb_linjin.v
// Project Name:  ZJUproject
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Dmod_Seg
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Dmod_Seg_tb_linjin;

	// Inputs
	reg clk=0;
	reg posedge_sample_trig=0;
	reg rst_n=0;
	reg [15:0] cmd_smpl_depth=1008;
	reg [31:0] Pstprc_RAMQ_dina=0;
	wire Pstprc_RAMQ_clka;
	wire Pstprc_RAMQ_clkb;
	reg [31:0] Pstprc_RAMI_dina=0;
	reg Pstprc_RAMI_clka;
	wire Pstprc_RAMI_clkb;
	reg [14:0] demoWinln_twelve=1000;
	reg [14:0] demoWinstart_twelve=4;
	reg [24:0] Pstprc_DPS_twelve=6291456;//375M
	reg pstprc_num_en=0;
	reg [3:0] Pstprc_num=0;
	reg [31:0] Estmr_A_eight=0;
	reg [31:0] Estmr_B_eight=0;
	reg [63:0] Estmr_C_eight=0;
	reg Estmr_num_en=0;
	reg [3:0] Estmr_num=0;
	reg Estmr_sync_en=0;
	reg clk_Estmr=0;
	reg clk_Oserdes=0;

	// Outputs
	wire [63:0] pstprc_IQ_seq_o;
	wire Pstprc_finish;
	wire pstprc_fifo_wren;
	wire Estmr_OQ;

	// Instantiate the Unit Under Test (UUT)
	Dmod_Seg uut (
		.clk(clk), 
		.posedge_sample_trig(posedge_sample_trig), 
		.rst_n(rst_n), 
		.cmd_smpl_depth(cmd_smpl_depth), 
		.Pstprc_RAMQ_dina(Pstprc_RAMQ_dina), 
		.Pstprc_RAMQ_clka(Pstprc_RAMQ_clka), 
		.Pstprc_RAMQ_clkb(Pstprc_RAMQ_clkb), 
		.Pstprc_RAMI_dina(Pstprc_RAMI_dina), 
		.Pstprc_RAMI_clka(Pstprc_RAMI_clka), 
		.Pstprc_RAMI_clkb(Pstprc_RAMI_clkb), 
		.demoWinln_twelve(demoWinln_twelve), 
		.demoWinstart_twelve(demoWinstart_twelve), 
		.pstprc_IQ_seq_o(pstprc_IQ_seq_o), 
		.Pstprc_finish(Pstprc_finish), 
		.Pstprc_DPS_twelve(Pstprc_DPS_twelve), 
		.pstprc_num_en(pstprc_num_en), 
		.Pstprc_num(Pstprc_num), 
		.pstprc_fifo_wren(pstprc_fifo_wren), 
		.Estmr_A_eight(Estmr_A_eight), 
		.Estmr_B_eight(Estmr_B_eight), 
		.Estmr_C_eight(Estmr_C_eight), 
		.Estmr_num_en(Estmr_num_en), 
		.Estmr_num(Estmr_num), 
		.Estmr_sync_en(Estmr_sync_en), 
		.clk_Estmr(clk_Estmr), 
		.clk_Oserdes(clk_Oserdes), 
		.Estmr_OQ(Estmr_OQ)
	);
	parameter C_SAMPLE_DEPTH = 1000;
	parameter PERIOD = 8;
	parameter ADC_CLK_PERIOD = 4;
	parameter C_TRIG_INTERVAL = 4000;
	parameter C_TRIG_COUNT = 500;
	parameter C_START_POS = 236/4;//每一个起始位置 4字节
	parameter C_ROW_LENGTH = 2008/4;//每4字节一个数据
  //产生主处理时钟 125M
   initial begin
      forever begin
        #(PERIOD/2) clk=!clk; clk_Estmr = !clk_Estmr;
      end
   end
  //产生ADC处理时钟 250M
   initial begin
	Pstprc_RAMI_clka = 0;
      forever begin
        #(ADC_CLK_PERIOD/2) Pstprc_RAMI_clka=!Pstprc_RAMI_clka;
      end
   end	
	assign Pstprc_RAMI_clkb = clk;
	assign Pstprc_RAMQ_clka = Pstprc_RAMI_clka;
	assign Pstprc_RAMQ_clkb = clk;
  //产生oserdes时钟 250M
  
   initial begin
      forever begin
        #(PERIOD/4) clk_Oserdes=!clk_Oserdes;
      end
   end
	//每2us产生一次触发，触发宽度一个时钟周期
	reg ram_addr_en = 0;
	reg [19:0]ram_start_addr = 0;
	reg load_data_finish = 0;
	reg [15:0]trig_cnt = 0;
	initial begin
		@(posedge load_data_finish);
		trig_cnt = 0;
		//产生500次触发，对应的读数据使能和计数
      forever begin
        #200                  ram_addr_en=1;ram_start_addr = trig_cnt*C_ROW_LENGTH+C_START_POS;
		  #PERIOD					posedge_sample_trig=0;
		  #PERIOD               posedge_sample_trig=1;
		  #PERIOD               posedge_sample_trig=0;
		  #(PERIOD*(C_SAMPLE_DEPTH/4-4))ram_addr_en=0; 
		  #PERIOD               trig_cnt = trig_cnt+1;
		  #2000;
      end
   end
	
	//触发上升沿到来，读取1000个数据出来
	reg [17:0] ram_addr;
	reg [9:0] addr_steps;
	always @(posedge clk) begin
		if(ram_addr_en) begin
			addr_steps = addr_steps+1;
		end
		else begin
			addr_steps = 0;
		end
		
		ram_addr = ram_start_addr + addr_steps;
	end
  
  
//  always @(posedge clk) begin
//	    
//  end
   reg [31:0] data_i [C_ROW_LENGTH*C_TRIG_COUNT:0];
   reg [31:0] data_q [C_ROW_LENGTH*C_TRIG_COUNT:0];
	
   
	reg[4:0] n;
   task load_I_data;
      begin
         $display("start read I data");
			$readmemh ("C:/Current_Key_Projects/1Gsps_ADC_board_V4_algromth/375_wave_I.mem", data_i,0);
			
			for(n=0;n<=7;n=n+1)
				$display("%h",data_i[n]);
			$display("stop read I data");
      end
   endtask
   task load_Q_data;
      begin
         $display("start read Q data");
			$readmemh ("C:/Current_Key_Projects/1Gsps_ADC_board_V4_algromth/375_wave_Q.mem", data_q,0);
			
			for(n=0;n<=7;n=n+1)
				$display("%h",data_q[n]);
			$display("stop read Q data");
      end
   endtask

//	task begin
//	   $display("start read data");
//      $readmemh ("C:/Current_Key_Projects/1Gsps_ADC_board_V4_algromth/375_wave_I.mem", data_i,C_START_POS);
//		$display("stop read data");
//		for(n=0;n<=7;n=n+1)
//			$display("%h",data_i[n]);
//	end
	always @(posedge clk) begin
		Pstprc_RAMQ_dina <= data_q[ram_addr];
		Pstprc_RAMI_dina <= data_i[ram_addr];
	end
	
	initial begin
		// Initialize Inputs
		rst_n = 0;
		load_data_finish = 0;
		// Wait 100 ns for global reset to finish
		#100;
		rst_n = 1;
		load_I_data();
		load_Q_data();
		
//		#10000
//		Pstprc_num          <= 0;
//      pstprc_num_en       <= 1;
//		#8
//		pstprc_num_en       <= 0;
		#10000
		$display("enable trig");
		load_data_finish = 1;
		#(C_TRIG_COUNT*C_TRIG_INTERVAL);
      $stop;   
		// Add stimulus here

	end
      
endmodule

