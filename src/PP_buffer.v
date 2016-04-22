`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 		JX
// 
// Design Name: 
// Module Name:    PP_buffer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: a ping-pong buffer for TX and RX. Two dp rams are instantiationized 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module PP_buffer(
	input reset,
	
	//read port
	input 							Rd_Clk,
	input								Rd_en,		// should jump to high when Frm_valid is high to start reading a valid frame, keep high during reading, and jump to low after the last address is provided to endup a frame read
	input	[RAM_ADDR_BITS-1:0]	Rd_Addr,		// provide together with Rd_en
	output [RAM_WIDTH-1:0]		Rd_data,		// data will be one clock delay after address
	
	//write port
	input 							Wr_Clk,
	input								Wr_en,		// should keep valid during a frame writing. If last frame is pending, Wr_en will be ignored. Wr_en should be low at least two clock between two write operation
	input	[RAM_ADDR_BITS-1:0]	Wr_Addr,
	input	[RAM_WIDTH-1:0]		Wr_data,
	input 							Wr_frm_ok,	// the writer should indicate if the frame just wrote is valid at the falling edge of Wr_en detected by Wr_Clk
	output reg						Wr_ready,	// when high, it is ready for a new write
	
	//status port
	output reg	Frm_valid_o	// at least one frame store at buffer, synchronous to Rd_Clk. when finish writing of a new frame, Frm_valid will be pull low and than pull high 
    );

   parameter RAM_WIDTH = 8;			// default byte width
   parameter RAM_ADDR_BITS = 14;		// default 
	
	// signals for RAM_dp1
	wire								Rd_en1;
	wire 	[RAM_WIDTH-1:0]		Rd_data1;
	wire								Wr_en1;	
	
	// signals for RAM_dp2
	wire								Rd_en2;
	wire 	[RAM_WIDTH-1:0]		Rd_data2;
	wire								Wr_en2;	
	
	///////////////////////
	// code start
	///////////////////////////
	//detect write start and end
	//判断写开始和结束
	reg wr_start, wr_end, Wr_en_last;
	always @ (posedge Wr_Clk)	if(reset)	Wr_en_last <= 1'b0; else Wr_en_last <= Wr_en;
	always @ * 	wr_start <= !Wr_en_last & Wr_en;		// wr_start will be one clock 
	always @ * 	wr_end <= Wr_en_last & !Wr_en;		// wr_end will be one clock 
			
	//detect read start and end
	//判断读开始和结束
	reg rd_start, rd_end, Rd_en_last, Rd_en_last2;
	always @ (posedge Rd_Clk)	if(reset)	Rd_en_last  <= 1'b0; else Rd_en_last  <= Rd_en;
	always @ (posedge Rd_Clk)	if(reset)	Rd_en_last2 <= 1'b0; else Rd_en_last2 <= Rd_en_last;	// eliminate metastable
	always @ (posedge Rd_Clk)	rd_start <= !Rd_en_last2 & Rd_en_last;	// rd_start will be two clock delay
	always @ (posedge Rd_Clk)	rd_end <= Rd_en_last2 & !Rd_en_last;	// rd_end will be two clock delay
	
	//ending，高电平时，正在结束读操作
	reg ending;
	always @ (posedge Rd_Clk)
		if(reset | !Frm_valid)
			ending <= 1'b0;
		else if(rd_end)
			ending <= 1'b1;
	reg ending_last,ending_last2;	
	
	//把结束读操作的信号传递到写时钟域
	always @ (posedge Wr_Clk)	ending_last <= ending;	//
	always @ (posedge Wr_Clk)	ending_last2 <= ending_last;	//
	
	//表明是否有一个新的有效帧写入到缓冲区中
	//new_frm
	reg new_frm; // indicate that a new frame is written to ram
	always @ (posedge Wr_Clk)
		if(reset || ram_switch)	// new_frm will be reset at ping-pong ram switching
			new_frm <= 1'b0;
		else if(wr_end & Wr_frm_ok & wr_en_int) // new frame is recognized at the end of write with OK flag 
			new_frm <= 1'b1;
			
	//指示是否可以往乒乓缓冲中写入新的帧		
	//Wr_ready
	always @(posedge Wr_Clk)
		if(wr_en_int | reset)
			Wr_ready <= 1'b0;
		else 
			Wr_ready <= !new_frm;
		
	//表明是否在做乒乓切换
	//ram_switch		
	reg ram_switch;	// ping-pong ram will switch at this signal. Read by Wr_Clk
	always @ *
		ram_switch <= (!Frm_valid_int & !Frm_valid_fb & new_frm & !ending_last2);	// switch when no valid frame on other ram, and new frame arrive
	
	//Frm_valid_int,    indicate that at least one frame in ram is ready to be read, @Wr_Clk, internal use only
	reg Frm_valid_int;
//	always @ (posedge Wr_Clk )
//		if(reset /*|| wr_end*/ || ending_last2)	// new_frm will be reset at the start of a new write of frame
//			Frm_valid_int <= 1'b0;
//		else if(ram_switch)
//			Frm_valid_int <= 1'b1;
	always @ (posedge Wr_Clk or posedge ending)
		if(ending | reset)
//		if(reset /*|| wr_end*/ || ending_last2)	// new_frm will be reset at the start of a new write of frame
			Frm_valid_int <= 1'b0;
		else if(ram_switch)
			Frm_valid_int <= 1'b1;
			
	//forward Frm_valid_int from write clock to read clock as Frm_valid
	reg Frm_valid_int_last, Frm_valid_int_last2;
	reg Frm_valid;
	always @ (posedge Rd_Clk)	if(reset )	Frm_valid_int_last  <= 1'b0; else Frm_valid_int_last  <= Frm_valid_int;
	always @ (posedge Rd_Clk)	if(reset )	Frm_valid_int_last2 <= 1'b0; else Frm_valid_int_last2 <= Frm_valid_int_last;	// eliminate metastable
	always @ (posedge Rd_Clk)	
		if(reset || (!Frm_valid_int_last2 & !Frm_valid_int_last))
			Frm_valid <= 1'b0;
		else if (Frm_valid_int_last2 & Frm_valid_int_last)
			Frm_valid <= 1'b1;
	always @ *//(posedge Rd_Clk)	
		Frm_valid_o <= Frm_valid;
//	always @ (posedge Rd_Clk)	
//		if(reset | rd_end)
//			Frm_valid_o <= 1'b0;
//		else if (Frm_valid_int_last2 & Frm_valid_int_last)
//			Frm_valid_o <= 1'b1;
	//forward Frm_valid back to write clock as Frm_valid_fb
	reg Frm_valid_last, Frm_valid_last2, Frm_valid_fb;
	always @ (posedge Wr_Clk)	if(reset)	Frm_valid_last  <= 1'b0; else Frm_valid_last  <= Frm_valid;
	always @ (posedge Wr_Clk)	if(reset)	Frm_valid_last2 <= 1'b0; else Frm_valid_last2 <= Frm_valid_last;	// eliminate metastable
	always @ (posedge Wr_Clk)	
		if(reset || (!Frm_valid_last2 & !Frm_valid_last) /*|| ending*/)
			Frm_valid_fb <= 1'b0;
		else if (Frm_valid_last2 & Frm_valid_last)
			Frm_valid_fb <= 1'b1;
	
	//maintain the ram to store next arriving frame
	reg	wr_ram;		// current ram to write to. the other ram is for read, synchronous to write clock
	always @ (posedge Wr_Clk)
		if(reset)
			wr_ram <= 1'b0;
		else if(ram_switch)
			wr_ram <= ~wr_ram;
	
	//wr_en_int, generate internal wr_en
	reg	wr_en_int;
	wire	wr_en_int_w;
	always @ (posedge Wr_Clk)
		if(reset || wr_end)
			wr_en_int <= 1'b0;
		else if(!new_frm & wr_start)
			wr_en_int <= 1'b1;
	assign wr_en_int_w = (wr_en_int | (wr_start & !new_frm)) & Wr_en;
	
	//generate wr_en for internal two dp rams
	assign Wr_en1 = wr_ram ? 1'b0 : wr_en_int_w ;
	assign Wr_en2 = wr_ram ? wr_en_int_w : 1'b0 ;
	
	//generate rd_en for internal two dp rams
	assign Rd_en1 = wr_ram ? Rd_en & Frm_valid : 1'b0 ;
	assign Rd_en2 = wr_ram ? 1'b0 : Rd_en & Frm_valid ;
	
	//output read data
	assign Rd_data = wr_ram ? Rd_data1 : Rd_data2;
	
RAM_dp #(
	.RAM_WIDTH(RAM_WIDTH),
	.RAM_ADDR_BITS(RAM_ADDR_BITS)
	)RAM_dp1 (
    .Rd_Clk(Rd_Clk), 
    .Rd_en(Rd_en1), 
    .Rd_Addr(Rd_Addr), 
    .Rd_data(Rd_data1), 
    .Wr_Clk(Wr_Clk), 
    .Wr_en(Wr_en1), 
    .Wr_Addr(Wr_Addr), 
    .Wr_data(Wr_data)
	);
RAM_dp #(
	.RAM_WIDTH(RAM_WIDTH),
	.RAM_ADDR_BITS(RAM_ADDR_BITS)
	)RAM_dp2 (
    .Rd_Clk(Rd_Clk), 
    .Rd_en(Rd_en2), 
    .Rd_Addr(Rd_Addr), 
    .Rd_data(Rd_data2), 
    .Wr_Clk(Wr_Clk), 
    .Wr_en(Wr_en2), 
    .Wr_Addr(Wr_Addr), 
    .Wr_data(Wr_data)
	);

endmodule
