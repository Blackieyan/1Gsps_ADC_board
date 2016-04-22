//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Photoelectronics Engineering Lab., Quantum Physics & Quantum Information, USTC. PEL@QPQI.USTC
// Engineer: JX
//
// Modified: 11/30/2014
// Change to check dst MAC address and length field. If dst MAC and type don't match, discard the packet
// 
// Create Date:    18:15:01 07/28/2013 
// Design Name: 
// Module Name:    Mac_RX2 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//		接收以太网帧，，当以太网帧格式是正确的（比如CRC是对的），且果MAC地址相符或者是广播帧，且类型/长度域等于0xAA55，则把该帧存入缓冲器。
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Mac_RX2 #(
    
    parameter RAM_WIDTH = 8,			// default byte width
    parameter RAM_ADDR_BITS = 14,		// default 
//	parameter MAC_ADDR 			= 48'H4b_45_59_00_00_01	    //MAC address: 4B:45:59:00:00:01
	parameter MAC_ADDR_BROAD 	= 48'Hff_ff_ff_ff_ff_ff		//broadcast MAC address
    )(
	input 			  reset, // reset input

	//	local mac address
	input [47:0] 		  MAC_addr,

	//read port
	input 			  Rd_Clk, // read clk should run all the time
	input 			  Rd_en, // should jump to high when Frm_valid is high to start reading a valid frame, keep high during reading, and jump to low after the last address is provided to endup a frame read
	input [RAM_ADDR_BITS-1:0] Rd_Addr, // provide together with Rd_en, data will present on Rd_data next clock
	output [RAM_WIDTH-1:0] 	  Rd_data,
	output 			  Frm_valid, // at least one frame store at buffer, synchronous to Rd_Clk. 
	
/* -----\/----- EXCLUDED -----\/-----
      output buf_wr_en,
 -----/\----- EXCLUDED -----/\----- */
	// signals between FPGA and PHY
	input [3:0] 		  PHY_RXD,
	input 			  PHY_RXC,
	input 			  PHY_RXDV
	);

	
	//signals for RGMII_to_GMII module
	wire			GMII_RX_CLK;
	wire	[7:0]	GMII_RX_RXD;
	wire			GMII_RX_DV;
   reg			GMII_RX_DV1;
   reg		GMII_RX_DV2;
   
	wire			GMII_RX_ER;


	
/////////////////////////////////////////////////////////////////////////////
//receive data from PHY, write to RX_buffer
//
	reg	DV_last;
	// receive phase flags:
	reg	rev_StartPulse;	// start pulse at the start of frame 
	reg	rev_EndPulse;		// end pulse at the end of frame indicate by falling edge of GMII_RX_DV
	reg	rev_EndPulse2;		// end pulse delay one clock
	reg	rev_EndPulse3;		// end pulse delay two clock
	
	reg	rev_PRE;		// 7 bytes of 0x55 preamble
	reg	rev_SOF;		// 1 byte of 0xd5 start of frame flag
	reg	rev_MAC_dst;		// receive destination MAC address
	reg	rev_MAC_src;		// receive source MAC address
	reg	rev_TYPE;			// receive type/length field
	reg	rev_DATA;	// receive ethernet frame, preamble is excluded

	reg[RAM_ADDR_BITS:0]		rev_cnt;		//receive byte counter, //maximum 254 byte
	reg			rev_cnt_en;	// counter enable
	wire [31:0]	CRC_calc;	// combinational crc calculate result
	reg [31:0]		rev_crc;
	
	reg[7:0] Error_code;
	wire		Error;
	
	// signals for crc check
//	reg 			cal_CRC;		// caculate crc when high
//	reg[31:0]	rev_crc;
	wire [7:0]	rev_crc_data_r;
//	wire [31:0]	CRC_calc;	// combinational crc calculate result
	
	// signals for RX_buffer module
	reg[RAM_ADDR_BITS-1:0] 	buf_addr;	//buffer write address counter 
//	reg							buf_addr_cnt_en;			
	reg buf_wr_en;
	reg [RAM_WIDTH-1:0]buf_wr_data;		// data will be delay one clock
	reg buf_wr_frm_ok;
   reg 	    buf_wr_frm_ok_last;
	reg[RAM_ADDR_BITS-1:0] frm_length;

// convert 4-bit RGMII receive interface to 8bit GMII interface
RGMII_to_GMII u_RGMII_to_GMII1 (
    .RXCLK_i(PHY_RXC), 
    .RXDATA_i(PHY_RXD), 
    .RXCTL_i(PHY_RXDV), 
	 .reset(reset),
	 
    .GMII_RX_CLK_o(GMII_RX_CLK), 
    .GMII_RX_RXD_o(GMII_RX_RXD), 
    .GMII_RX_DV_o(GMII_RX_DV), 
    .GMII_RX_ER_o(GMII_RX_ER)
    );

	// detect start and end
   	always @ (posedge GMII_RX_CLK)
		if(reset)
			GMII_RX_DV1 <= 1'b0;
		else
			GMII_RX_DV1 <= GMII_RX_DV;
   
   	always @ (posedge GMII_RX_CLK)
		if(reset)
			GMII_RX_DV2 <= 1'b0;
		else
			GMII_RX_DV2 <= GMII_RX_DV1;
   
	always @ (posedge GMII_RX_CLK)
		if(reset)
			DV_last <= 1'b0;
		else
			DV_last <= GMII_RX_DV2;
	
	always @ *
	// if data valid without error and the first byte is 0x55 at reset desserted, a new packet is started
	rev_StartPulse <= !DV_last & GMII_RX_DV2 & !GMII_RX_ER & (GMII_RX_RXD == 8'h55) & !reset;//dv上升沿并且收到的帧头是h55
	 // rev_StartPulse <= !DV_last & GMII_RX_DV2  & (GMII_RX_RXD == 8'h55) & !reset;
	always @ *
	// if data valid without error and the first byte is 0x55 at reset desserted, a new packet is started
		rev_EndPulse <= GMII_RX_DV1 & !GMII_RX_DV;//dv下降沿
	always @ (posedge GMII_RX_CLK) rev_EndPulse2 <= rev_EndPulse;
	always @ (posedge GMII_RX_CLK) rev_EndPulse3 <= rev_EndPulse2;
			
	//rev_cnt_en
	always @ (posedge GMII_RX_CLK)
		if(rev_StartPulse)
			rev_cnt_en <= 1'b1;
		else	if( reset | rev_EndPulse | Error)
			rev_cnt_en <= 1'b0;
		
	// byte counter
	//rev_cnt
   always @(posedge GMII_RX_CLK)
	begin
      if (reset | (!rev_cnt_en ) | Error)
         rev_cnt <= 'd1;	 
      else if (rev_cnt_en)
         rev_cnt <= rev_cnt + 1;
	end

	// receive packet phase flags
	always @(posedge GMII_RX_CLK) 
		if(reset | rev_EndPulse | Error) //reset or 
		begin
			rev_PRE 		<= 1'b0;
			rev_SOF 		<= 1'b0;
			rev_MAC_dst <= 1'b0;
			rev_MAC_src <= 1'b0;
			rev_TYPE 	<= 1'b0;
			rev_DATA 	<= 1'b0;
			
		end
		else
			case (rev_cnt)
				8'd01: begin
					rev_PRE <= (rev_StartPulse) ? 1'b1 : rev_PRE;
					end
				8'd06: begin
					rev_PRE <= 1'b0;
					rev_SOF <= 1'b1; 
					end
				8'd07: begin
					rev_SOF 		<= 1'b0;
					rev_MAC_dst <= 1'b1; 
					rev_DATA 	<= 1'b1; 
					end
				8'd13: begin
					rev_MAC_dst	<= 1'b0;
					rev_MAC_src <= 1'b1; 
					end
				8'd19: begin
					rev_MAC_src	<= 1'b0;
					rev_TYPE 	<= 1'b1; 
					end
				8'd21: begin
					rev_TYPE 	<= 1'b0;
					rev_DATA 	<= 1'b1; 
					end
				default:
					if(rev_EndPulse) rev_DATA <= 1'b0;
			endcase

//////////////////-------- receive destination MAC address and length/type ------------//////////////	
	//receive destination MAC address
	//MAC_dst
	reg [47:0] MAC_dst;
	always @ (posedge GMII_RX_CLK)
		if(rev_MAC_dst)
			MAC_dst <= {MAC_dst[39:0],GMII_RX_RXD};

	//receive length/type
	//Type_length
	reg [15:0] Type_length;
	always @ (posedge GMII_RX_CLK)
		if(rev_TYPE)
			Type_length <= {Type_length[7:0],GMII_RX_RXD};

/////////////////// ---------- check crc -------- ////////////////////////	
			
	//CRC calculation
	always @ (posedge GMII_RX_CLK)
		if(reset || rev_StartPulse || rev_EndPulse || Error)
			rev_crc <= 32'hffff_ffff;
		else if(rev_DATA)
			rev_crc <= CRC_calc;

	//将数据比特顺序反转
	assign rev_crc_data_r = {GMII_RX_RXD[0],GMII_RX_RXD[1],GMII_RX_RXD[2],GMII_RX_RXD[3],GMII_RX_RXD[4],GMII_RX_RXD[5],GMII_RX_RXD[6],GMII_RX_RXD[7]};
	crc32_d8	 crc32_d8(
		.C		(rev_crc),	//
		.D		(rev_crc_data_r),	//input data, [7:0]rev_crc_data_r
		.C_OUT	(CRC_calc)	// combinational output
	);
//	wire [7:0]	 rev_crc_r;
//	assign rev_crc_r = ~{ rev_crc[24],rev_crc[25],rev_crc[26],rev_crc[27],rev_crc[28],rev_crc[29],rev_crc[30],rev_crc[31]};
	
	
	// error detection
	always @ (posedge GMII_RX_CLK) if(rev_PRE & (GMII_RX_RXD != 8'h55)) 			 	Error_code[0] <= 1'b1; else if (rev_StartPulse | reset) Error_code[0] <= 1'b0;	//preamble error
	always @ (posedge GMII_RX_CLK) if(rev_SOF & (GMII_RX_RXD != 8'hd5)) 			 	Error_code[1] <= 1'b1; else if (rev_StartPulse | reset) Error_code[1] <= 1'b0;	//preamble error
	always @ (posedge GMII_RX_CLK) if(rev_EndPulse & ((MAC_dst != MAC_addr) & (MAC_dst != MAC_ADDR_BROAD))) 		Error_code[2] <= 1'b1; else if (rev_StartPulse | reset) Error_code[2] <= 1'b0;	// mac address not match or not broadcast address
	always @ (posedge GMII_RX_CLK) if(rev_EndPulse & (Type_length != 'hAA55)) 		Error_code[3] <= 1'b1; else if (rev_StartPulse | reset) Error_code[3] <= 1'b0;	// not IEEE 802.2 LLC protocal. All IP packets will be filtered out
	always @ (posedge GMII_RX_CLK) if(rev_EndPulse & (rev_crc != 32'hc704dd7b)) 	Error_code[4] <= 1'b1; else if (rev_StartPulse | reset) Error_code[4] <= 1'b0;	// CRC error
	always @ (posedge GMII_RX_CLK) if(reset)	Error_code[6:5] <= 4'b0;
	
	assign Error = |Error_code[6:0];
	always @ (posedge GMII_RX_CLK)
			Error_code[7] <= Error;
	
/////////////////// ---------- write data to rx_buffer -------- ////////////////////////	
	//buf_wr_en
   always @(posedge GMII_RX_CLK)
		if(reset || rev_EndPulse3)		//buf_wr_en will be reset three clocks after GMII_RX_DV2 be low
			buf_wr_en <= 1'b0;
		else if(rev_DATA)					//buf_wr_en will be set one clock after rev_DATA
			buf_wr_en <= 1'b1;
			
	//buf_addr,  buffer address counter
   always @(posedge GMII_RX_CLK)
	begin
      if (reset || rev_StartPulse)
         buf_addr <= 8'd1;	 				// frame data will be write from address 0x02
      else if (rev_DATA & GMII_RX_DV)
         buf_addr <= buf_addr + 1;
		else if (rev_EndPulse)
         buf_addr <= 0;						// write low byte of frame length word to address 0
		else if (rev_EndPulse2)
         buf_addr <= 1;						// write high byte of frame length word to address 1
	end

	//buf_wr_data，要定入乒乓缓冲的数据，先是以太网数据，最后把帧长写入缓冲区的开始
   always @(posedge GMII_RX_CLK)
		if(reset || rev_EndPulse3)		//buf_wr_data will be reset three clocks after GMII_RX_DV2 be low
			buf_wr_data <= 8'b0;
		else if(rev_DATA  & GMII_RX_DV)		//GMII_RX_RXD will be one clock delay
			buf_wr_data <= GMII_RX_RXD;
		else if (rev_EndPulse)
         buf_wr_data <= {2'b00, frm_length[RAM_ADDR_BITS-1:8]};						// write low byte of frame length word to address 0
		else if (rev_EndPulse2)
         buf_wr_data <= frm_length[7:0];						// write low byte of frame length word to address 1

	//frm_length
   always @(posedge GMII_RX_CLK)
		if(reset || rev_StartPulse)		//buf_wr_en will be reset three clocks after GMII_RX_DV2 be low
			frm_length <= 16'b1;
		else if(rev_DATA & GMII_RX_DV)	//buf_wr_en will be set one clock after rev_DATA
			frm_length <= frm_length +1;		// include four bytes CRC

	//buf_wr_frm_ok，在完成当前帧写入后，告诉乒乓缓冲当前写入的帧是否是有效帧
   always @(posedge GMII_RX_CLK)
		if(reset || rev_StartPulse)		
			buf_wr_frm_ok <= 1'b0;
		else
			buf_wr_frm_ok <= rev_EndPulse2 & !Error;		// include for bytes CRC 从pulse3改成了2
   always @(posedge GMII_RX_CLK)
		  buf_wr_frm_ok_last <= buf_wr_frm_ok;  //补齐了时序
   
/* -----\/----- EXCLUDED -----\/-----
   always @(posedge GMII_RX_clk)
     rd_en<=buf_wr_en;

   always @(posedge GMII_RX_clk)
   if(reset || rev_StartPulse) 
     rd_addr<=14'b0;
   else if(rd_en)
     rd_addr<=rd_addr+1;
 -----/\----- EXCLUDED -----/\----- */
   
     
	
	//乒乓缓冲
	//instantiation of rx buffer
	PP_buffer #(
		.RAM_WIDTH(RAM_WIDTH),
		.RAM_ADDR_BITS(RAM_ADDR_BITS)
	)u_RX_buffer (
		 .reset(reset), 
		 .Rd_Clk(Rd_Clk), 
		 .Rd_en(Rd_en), 
		 .Rd_Addr(Rd_Addr), 
		 .Rd_data(Rd_data), 
		 
		 .Wr_Clk(GMII_RX_CLK), 
		 .Wr_en(buf_wr_en), 
		 .Wr_Addr(buf_addr), 
		 .Wr_data(buf_wr_data), 
		 .Wr_frm_ok(buf_wr_frm_ok_last), 
		 .Wr_ready(),
		 
		 .Frm_valid_o(Frm_valid)
		 );
endmodule
