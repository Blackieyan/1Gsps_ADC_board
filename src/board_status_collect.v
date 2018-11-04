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
    input sys_clk,
    input rst_n,
	 //来自于命令解析模块
    input [31:0]  cmd_0_data,
    input [6:0]	cmd_0_addr,
    input 			cmd_0_en,
	 //来自于内部逻辑，根据需要增加
    input [31:0] 	status_1,
    input [31:0] 	status_2,
    input [31:0] 	status_3,
    input [31:0] 	status_4,
	 //读出接口
	 output [63:0]	status_ram_data,
	 output     	status_ram_data_vld,
	 input [6:0]	status_ram_addr,
	 input      	status_ram_rd_en
    );
parameter REG_CNT = 128;
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
	if(cmd_0_en == 1)	begin //命令写入在高128个地址
		ram_wr_en	<= 1;
		ram_wr_data <= cmd_0_data;
		ram_wr_addr <= {1'b1,cmd_0_addr};
	end
	else if(time_wr == 1 ) begin //寄存器在低128个地址
		ram_wr_addr <= {1'b0,time_cnt[6:0]};
		case(time_cnt[6:0])
			0:	begin ram_wr_data <= heart_beat; ram_wr_en	<= 1; end
			1:	begin ram_wr_data <= status_1;   ram_wr_en	<= 1; end
			2:	begin ram_wr_data <= status_2;   ram_wr_en	<= 1; end
			3:	begin ram_wr_data <= status_3;   ram_wr_en	<= 1; end
			4:	begin ram_wr_data <= status_4;   ram_wr_en	<= 1; end
			default : begin ram_wr_data <= ram_wr_data; ram_wr_en	<= 0; end
		endcase
	end
	else begin
		ram_wr_en	<= 0;
	end
end

endmodule
