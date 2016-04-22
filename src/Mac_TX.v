`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Photoelectronics Engineering Lab., Quantum Physics & Quantum Information, USTC. PEL@QPQI.USTC
// Engineer: JX
// 
// Create Date:    20:08:06 07/29/2014 
// Design Name: 
// Module Name:    Mac_TX 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 	根据触发来往PHY发数据。当Trig_i在clk的上升沿被检测到由低到高的变化时，开始从缓冲区接口读入完整的以太网帧发送，并计算CRC；在适当的时候，Data_Strobe会变高，表明下一个时钟周期的Data_in将要被	
//	发送到以太网上，有一个时钟周期的延迟是为了便于数据源准备将要被发送的数据；当检测到Last_byte为高时，Data_Strobe将变低，表明下一个时钟周期的Data_in是最后一个被发送的字节。			
// 
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Mac_TX(
    input clk,		//125MHz
	 input Reset_i,		// active high
	 
	 input 			Trig_i,		// 
	 
	 input [7:0] 	Data_in,		// input data to send
	 input			Last_byte,	// tell transmitter that the current byte on Data_in is the last byte to send, should be only one clock period. The total data to send at one frame should be less than 9kB
	 output	reg	Data_Strobe,	// if Data_Strobe is high on posedge of clk, the next byte on Data_in will be sent
	 output reg		Busy,				// indicate that PHY is busy in transmiting data
	 
	 // signals between FPGA and PHY
	 //TX
	 output  PHY_TXEN_o,
	 output  PHY_GTXCLK_o,		// TX clock, should be 125MHz for GbE
	 output [3:0] PHY_TXD_o
    );

	// detect start and end
	//Trig_last
	reg Trig_last;
	always @ (posedge clk)
		if(Reset_i)
			Trig_last <= 1'b0;
		else
			Trig_last <= Trig_i;
	
	//start pulse
	reg start_pulse;
	always @ *
	// if rising edge is detect and not busy at clock edge
		start_pulse <= !Trig_last &  Trig_i & !Busy & !Reset_i;

	//start pulse2
	reg start_pulse2;
	always @ (posedge clk)
	// if rising edge is detect and not busy at clock edge
		start_pulse2 <= start_pulse;

	//Busy
	always @ (posedge clk)
		if(end_blank | Reset_i)
			Busy <= 1'b0;
		else	if(start_pulse)
			Busy <= 1'b1;
	
	//Sending
	reg Sending;
	always @ (posedge clk)
		if(end_pulse | Reset_i)
			Sending <= 1'b0;
		else	if(start_pulse2)
			Sending <= 1'b1;
	
	//TX_byte_cnt
	reg[6:0]		TX_byte_cnt; 
   always @(posedge clk)
	begin
      if (Reset_i | start_pulse | ((dataComplete | Last_byte_last) & minByteSent))
         TX_byte_cnt <= 'd0;	
      else if (Sending & !(minByteSent))	//only count the preamble, first 60 data bytes and FCS
         TX_byte_cnt <= TX_byte_cnt + 1;
	end
	
	//Last_byte_last
	reg Last_byte_last;
	always @ (posedge clk)
		Last_byte_last <= Last_byte;

	//minByteSent
	reg minByteSent;	// indicate that minimun ethernet bytes, 8 preamble + 12 src & dst MAC + 2 length + 46 data = 68, has been sent
	always @ (posedge clk)
		if(TX_byte_cnt == 'd67)
			minByteSent <= 1;
		else if(Reset_i | (dataComplete | Last_byte_last))
			minByteSent <= 0;

	//dataComplete
	reg dataComplete;	// indicate that all data has been sent
	always @ (posedge clk)
		if(Last_byte_last)
			dataComplete <= 1;
		else if(Reset_i | minByteSent | end_pulse)
			dataComplete <= 0;
		
	
	//end_pulse
	reg end_pulse;
	always @ (posedge clk)
		end_pulse <= (TX_byte_cnt == 'd3) & Send_FCS;




	//Send_DATA
	reg Send_DATA;
	always @ (posedge clk)
		if(Reset_i | start_pulse | end_pulse | ((dataComplete | Last_byte_last) & minByteSent))
			Send_DATA <= 1'b0;
		else if(TX_byte_cnt == 'd8)
			Send_DATA <= 1'b1;
		
	//Send_FCS
	reg Send_FCS;
	always @ (posedge clk)
		if(Reset_i | start_pulse | (TX_byte_cnt == 'd3) )
			Send_FCS <= 1'b0;
		else if((dataComplete | Last_byte_last) & minByteSent)
			Send_FCS <= 1'b1;

	
	//Data_Strobe
	always@(posedge clk)
		if(Reset_i | Last_byte )
			Data_Strobe <= 1'b0;
		else if(start_pulse)
			Data_Strobe <= 1'b1;


	//blanking between frames
	//phy_frm_blanking_cnt_en
	reg phy_frm_blanking_cnt_en;
	always @(posedge clk) 
		if(Reset_i | end_blank)
			phy_frm_blanking_cnt_en <= 1'b0;
		else if(end_pulse)
			phy_frm_blanking_cnt_en <= 1'b1;
	
	wire end_blank = (phy_frm_blanking_cnt=='d15);
	
	//phy_frm_blanking_cnt
	reg[3:0] phy_frm_blanking_cnt;
	always @(posedge clk)
		if(Reset_i | Last_byte_last)
			phy_frm_blanking_cnt = 4'b0;
		else if(phy_frm_blanking_cnt_en)
			phy_frm_blanking_cnt = phy_frm_blanking_cnt + 1;;
	


	/////////////////////// CRC ////////////////
	//CRC calculation
		
	//CRC_Cal
	reg CRC_Cal;
	always @*
		CRC_Cal <= Send_DATA;
	
	//CRC
	reg[31:0] CRC;
	always @ (posedge clk)
		if(Reset_i | start_pulse | end_pulse)
			CRC <= 32'hffff_ffff;
		else if(CRC_Cal)
			CRC <= CRC_calc;
		else if (Send_FCS)
			CRC <= {CRC[23:0],8'b0};
			
	// crc
	wire[7:0]	Data_in_r;		//reverse sequence of Data_in, use to caculate CRC
	assign Data_in_r = {Data_in_buf[0],Data_in_buf[1],Data_in_buf[2],Data_in_buf[3],Data_in_buf[4],Data_in_buf[5],Data_in_buf[6],Data_in_buf[7]};
	wire [31:0] CRC_calc;
	crc32_d8	 crc32_d8(
		.C		(CRC),	//
		.D		(Data_in_r),	//input data, [7:0]rev_crc_data_r
		.C_OUT	(CRC_calc)	// combinational output
	);
	wire [7:0]	CRC_r;
	assign CRC_r = ~{ CRC[24],CRC[25],CRC[26],CRC[27],CRC[28],CRC[29],CRC[30],CRC[31]};

	////////////// output to PHY GMII interface /////////////
	//end_pulse_quar //new add
//	reg end_pulse_quar;
//	always @ (posedge clk)
//	 end_pulse_quar<=end_pulse;
	 
	//TX_EN //changed
	reg TX_EN;
	always @ (posedge clk)
		if(Reset_i | end_pulse )
			TX_EN <= 1'b0;
		else if((TX_byte_cnt == 'd1))
			TX_EN <= 1'b1;
	
	//GMII_TX_TXD, send out data
	reg[7:0]		Data_in_buf;
	always @ (posedge clk) 
		Data_in_buf <= Data_in;
		
	//GMII_TX_TXD, send out data
	reg[7:0]		GMII_TX_TXD;
	always @ (posedge clk) 
		if(Send_FCS)
			GMII_TX_TXD <= CRC_r;
		else //if(Data_Strobe)
			GMII_TX_TXD <= Data_in_buf;
//		else
//			GMII_TX_TXD <= 0;
			
			
	GMII_to_RGMII u_GMII_to_RGMII1(
		 .GMII_TX_CLK_i(clk), 
		 .GMII_TX_TXD_i(GMII_TX_TXD), 
		 .GMII_TX_EN_i(TX_EN), 
		 .GMII_TX_ER_i(1'b0), 
		 .PHY_GTXCLK_o(PHY_GTXCLK_o), 
		 .PHY_TXD_o(PHY_TXD_o), 
		 .PHY_TXEN_o(PHY_TXEN_o)
		 );

endmodule
