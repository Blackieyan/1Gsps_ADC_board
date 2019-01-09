`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:57:52 11/03/2018 
// Design Name: 
// Module Name:    board_status_collect 
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
module board_status_collect(
    input 	  sys_clk,
    input 	  rst_n,
	 //来自于命令解析模块1
    input [63:0]  cmd_0_data,
    input [3:0]   cmd_0_addr,
    input 	  cmd_0_en,
	 //来自于命令解析模块2
    input [127:0] cmd_1_data,
    input [2:0]   cmd_1_addr,
    input 	  cmd_1_en,
	 //来自于内部逻辑，根据需要增加
    output reg 	  updating_status,
    input [31:0]  status_1,
    input [31:0]  status_2,
    input [31:0]  status_3,
    input [31:0]  status_4,
    input [31:0]  status_5,
    input [31:0]  status_6,
    input [31:0]  status_7,
    input [31:0]  status_8,
    input [31:0]  status_9,
	 //读出接口
    output [63:0] status_ram_data,
    output 	  status_ram_data_vld,
    input [6:0]   status_ram_addr,
    input 	  status_ram_rd_en
    );
parameter REG_CNT = 127;
reg [7:0]   ram_wr_addr;	 
reg [31:0]  ram_wr_data;	 
reg			ram_wr_en; 
wire [63:0] ram_out;
assign status_ram_data = {ram_out[31:0], ram_out[63:32]};
status_ram status_ram_inst (
  .clka(sys_clk), // input clka
  .wea(ram_wr_en), // input [0 : 0] wea
  .addra(ram_wr_addr), // input [7 : 0] addra
  .dina(ram_wr_data), // input [31 : 0] dina
  .clkb(sys_clk), // input clkb
  .addrb(status_ram_addr), // input [6 : 0] addrb
  .doutb(ram_out) // output [63 : 0] doutb
);

reg status_ram_rd_en_d1;
reg status_ram_rd_en_d2;
//RAM 配置为读取延时为2个clk
assign status_ram_data_vld = status_ram_rd_en_d2;
always @(posedge sys_clk) begin
	status_ram_rd_en_d1 <= status_ram_rd_en;
	status_ram_rd_en_d2 <= status_ram_rd_en_d1;
end

//  定时器100 us 更新一次  

reg [15:0] time_cnt;
reg 			time_wr;
always @(posedge sys_clk) begin
	if(time_cnt < 12500)	time_cnt	<= time_cnt + 1;
	else 						time_cnt	<= 0;
end

always @(posedge sys_clk) begin
	if(time_cnt < REG_CNT)	time_wr  <= 1;
	else 							time_wr  <= 0;
end

reg [31: 0] heart_beat=0;
always @(posedge sys_clk) begin
	if(time_cnt == 0)			heart_beat  <= heart_beat + 1;
end
always @(posedge sys_clk) begin
	if(time_cnt == 0)			updating_status  <= 1;
	else							updating_status  <= 0;
end
reg cmd_0_en_d1;
reg cmd_0_wr1;
reg cmd_0_wr2;

reg cmd_1_en_d1;
reg cmd_1_wr1;
reg cmd_1_wr2;
reg cmd_1_wr3;
reg cmd_1_wr4;
always @(posedge sys_clk) begin
	cmd_0_en_d1 <= cmd_0_en;
	cmd_0_wr1   <= !cmd_0_en_d1 & cmd_0_en;
	cmd_0_wr2   <= cmd_0_wr1;
	cmd_1_en_d1 <= cmd_0_en;
	cmd_1_wr1   <= !cmd_1_en_d1 & cmd_1_en;
	cmd_1_wr2   <= cmd_1_wr1;
	cmd_1_wr3   <= cmd_1_wr2;
	cmd_1_wr4   <= cmd_1_wr3;

	if(cmd_0_wr1 == 1)	begin //命令写入在0地址 32个32位 最多可容纳16组频点的参数，实际上只有8个有效
		ram_wr_en	<= 1;
		ram_wr_data <= cmd_0_data[31:0];
		ram_wr_addr <= {3'b000,cmd_0_addr[3:0],1'b0};
	end
	else 	if(cmd_0_wr2 == 1)	begin 
		ram_wr_en	<= 1;
		ram_wr_data <= cmd_0_data[63:32];
		ram_wr_addr <= {3'b000,cmd_0_addr[3:0],1'b1};
	end
	else 	if(cmd_1_wr1 == 1)	begin //命令写入在32地址开始 32个32位 最多8组参数
		ram_wr_en	<= 1;
		ram_wr_data <= cmd_1_data[31:0];
		ram_wr_addr <= {3'b001,cmd_1_addr[2:0],2'b00};
	end
	else 	if(cmd_1_wr2 == 1)	begin 
		ram_wr_en	<= 1;
		ram_wr_data <= cmd_1_data[63:32];
		ram_wr_addr <= {3'b001,cmd_1_addr[2:0],2'b01};
	end
	else 	if(cmd_1_wr3 == 1)	begin 
		ram_wr_en	<= 1;
		ram_wr_data <= cmd_1_data[95:64];
		ram_wr_addr <= {3'b001,cmd_1_addr[2:0],2'b10};
	end
	else 	if(cmd_1_wr4 == 1)	begin 
		ram_wr_en	<= 1;
		ram_wr_data <= cmd_1_data[127:96];
		ram_wr_addr <= {3'b001,cmd_1_addr[2:0],2'b11};
	end
	else if(time_wr == 1 ) begin //寄存器在低128个地址
		ram_wr_addr <= {1'b1,time_cnt[6:0]};
		case(time_cnt[6:0])
			0:	begin ram_wr_data <= heart_beat; ram_wr_en	<= 1; end
			1:	begin ram_wr_data <= status_1;   ram_wr_en	<= 1; end
			2:	begin ram_wr_data <= status_2;   ram_wr_en	<= 1; end
			3:	begin ram_wr_data <= status_3;   ram_wr_en	<= 1; end
			4:	begin ram_wr_data <= status_4;   ram_wr_en	<= 1; end
			5:	begin ram_wr_data <= status_5;   ram_wr_en	<= 1; end
			6:	begin ram_wr_data <= status_6;   ram_wr_en	<= 1; end
			7:	begin ram_wr_data <= status_7;   ram_wr_en	<= 1; end
		  	8:	begin ram_wr_data <= status_8;   ram_wr_en	<= 1; end
		        9:	begin ram_wr_data <= status_9;   ram_wr_en	<= 1; end
			default : begin ram_wr_data <= ram_wr_data; ram_wr_en	<= 0; end
		endcase
	end
	else begin
		ram_wr_en	<= 0;
	end
end

endmodule
