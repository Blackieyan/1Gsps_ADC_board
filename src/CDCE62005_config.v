module CDCE62005_config(clk,clk_spi,en,spi_clk,spi_mosi,spi_miso,spi_le,spi_syn,spi_powerdn,cfg_finish,spi_revdata);
	input  clk,clk_spi;
	input  en;
	output spi_clk;
	output reg spi_mosi;
	input  spi_miso;
	output spi_le;
	output spi_syn;
	output spi_powerdn;
	output reg cfg_finish;
	output reg[31:0] spi_revdata;
	
	assign spi_syn		= 1'b1;
	assign spi_powerdn	= 1'b1;
	
	//operate parameter
	localparam  SM_confg_regiter0=8'h00,
					SM_confg_regiter1=8'h01,
					SM_confg_regiter2=8'h02,
					SM_confg_regiter3=8'h03,
					SM_confg_regiter4=8'h04,
					SM_confg_regiter5=8'h05,
					SM_confg_regiter6=8'h06,
					SM_spi_confg	  =8'h07,
					SM_spi_toEEPROM  =8'h08,
					SM_confg_finish  =8'h09,
					SM_Idle			  =8'h0a,
					SM_RdCommd_Set   =8'h0b,
					SM_RdCommd_Wr	  =8'h0c,
					SM_RdCommd_Rev	  =8'h0d,
					SM_RdCommd_RevPre=8'h0e,
					SM_spicfg_wait	  =8'h0f,
					SM_confg_regiter7=8'h10,
					SM_confg_regiter8=8'h11,
					SM_confg_regiter9=8'h12,
					SM_confg_regiter10=8'h13,
					SM_PDPre 		  =8'h14,			 //for calibration
					SM_PDDone 		  =8'h15;
   //functon register
	/*
   	localparam  Value_register0=32'hEB840300,//96MHZ
						Value_register1=32'h68840301,	        
						Value_register2=32'h68860302,
						Value_register3=32'h68860323,
						Value_register4=32'h68860314,								
						Value_register5=32'hFC000B25,
						Value_register6=32'h04000006,
						Value_register7=32'hBD0037F7,
						Value_register8=32'h80001808,
						Value_toEEPROM =32'h0000001f;
*/



/* -----\/----- EXCLUDED -----\/-----
   localparam  Value_register0=32'h81400320,	//1000MHZ aux in digital lock 会飘 led亮
     Value_register1=32'h81400301,	        
     Value_register2=32'h81400302,
     Value_register3=32'h68400323,
     Value_register4=32'h68400314,								
     Value_register5=32'h10000B25,
     Value_register6=32'h04BE03E6,
     Value_register7=32'hBD0037F7,
     Value_register8=32'h80009CD8, 
     Value_toEEPROM =32'h0000001f,
     Value_PDPre    =32'h80001008,	//for calibration
     Value_PDDone   =32'h80001808;
 -----/\----- EXCLUDED -----/\----- */




/* -----\/----- EXCLUDED -----\/-----
   localparam  Value_register0=32'h81400320,	//1000MHZ aux in10MHz  digital lock
     Value_register1=32'h81400301,	        
     Value_register2=32'h81400302,
     Value_register3=32'h68860303,
     Value_register4=32'hEB060314,								
     Value_register5=32'h90000B35,
     Value_register6=32'h04BE09E6,
     Value_register7=32'hBD0037F7,
     Value_register8=32'h80001808, 
     Value_toEEPROM =32'h0000001f,
     Value_PDPre    =32'h80001008,	//for calibration
     Value_PDDone   =32'h80001808;
 -----/\----- EXCLUDED -----/\----- */







/* -----\/----- EXCLUDED -----\/-----
   localparam  Value_register0=32'h81400320,	//1000MHZ aux in analog lock 也会飘
     Value_register1=32'h81400321,	        
     Value_register2=32'h81400302,
     Value_register3=32'h68860323,
     Value_register4=32'h68860314,								
     Value_register5=32'hD0000B35,
     Value_register6=32'h04BE03E6,
     Value_register7=32'hBD0037F7,
     Value_register8=32'h20009D98, 
     Value_toEEPROM =32'h0000001f,
     Value_PDPre    =32'h80001008,	//for calibration
     Value_PDDone   =32'h80001808;
 -----/\----- EXCLUDED -----/\----- */







   localparam  Value_register0=32'h81400320,	//1000MHZ sec ttl in 不会飘,channel5 100MHz output 
     Value_register1=32'h81400321,	        
     Value_register2=32'h81400302,
     Value_register3=32'h68860303,
     Value_register4=32'hEB060314,								
     Value_register5=32'h90000EB5,
     Value_register6=32'h04BF09E6,
     Value_register7=32'hBD0037F7,
     Value_register8=32'h80001808, 
     Value_toEEPROM =32'h0000001f,
     Value_PDPre    =32'h80001008,	//for calibration
     Value_PDDone   =32'h80001808;







/* -----\/----- EXCLUDED -----\/-----
   localparam  Value_register0=32'h81400320,	//1000MHZ sec ttl in 不会飘
     Value_register1=32'h81400321,	        
     Value_register2=32'h81400302,
     Value_register3=32'h68860323,
     Value_register4=32'h68860314,								
     Value_register5=32'hD0000AB5,
     Value_register6=32'h04BE09E6,
     Value_register7=32'hBD0037F7,
     Value_register8=32'h20009D98, 
     Value_toEEPROM =32'h0000001f,
     Value_PDPre    =32'h80001008,	//for calibration
     Value_PDDone   =32'h80001808;
 -----/\----- EXCLUDED -----/\----- */


 
 

 




/* -----\/----- EXCLUDED -----\/-----
   	localparam  Value_register0=32'h81400300,    //鎵撳紑1ghz lvpel锛宑rystal
						Value_register1=32'h81400301,	        
						Value_register2=32'h81400302,
						Value_register3=32'hE8400303,		//鍏抽棴1000MHz
						Value_register4=32'hE8400304,		//鍏抽棴1000MHz								
						Value_register5=32'h10008F35,		//1000MHz
						Value_register6=32'h04BE03E6,
						Value_register7=32'hBD0037F7,
						Value_register8=32'h80001808,
						Value_toEEPROM =32'h0000001f;
 -----/\----- EXCLUDED -----/\----- */

				
	reg[31:0] spi_data;
	reg[7:0]  SM,SM_next;						//State Machine
	reg[7:0]  cfg_cnt,spird_cnt;
	reg[3:0]  spi_reg_addr;
	reg[31:0] wait_cnt;
	reg 	  	 spi_le_rd,spi_le_wr,spi_rd_reqrd,spi_rd_reqack;
	reg 	  	 spi_clken;
				
	assign spi_clk	= spi_clken ? clk_spi : 1'b0;
	assign spi_le	= spi_rd_reqrd ? spi_le_rd : spi_le_wr;
	
	always@(posedge clk)
		if(!en)
			begin
			spi_rd_reqrd<=1'b0;
			spi_le_wr<=1'b1;
			spi_mosi<=1'b0;
			cfg_cnt<=8'h0;
			cfg_finish<=1'b1;
			spi_reg_addr<=4'h0;
			wait_cnt<=32'h0;
			spi_clken<=1'b0;
			SM<=SM_Idle;
			end
		else
			case(SM)
			SM_Idle:
				if(en)
					begin
					SM<=SM_confg_regiter0;
					cfg_cnt<=8'h0;
					end
			SM_confg_regiter0:
				begin
				spi_data<=Value_register0;
				SM<=SM_spi_confg;
				SM_next<=SM_confg_regiter1;
				end
			SM_confg_regiter1:
				begin
				spi_data<=Value_register1;
				SM<=SM_spi_confg;
				SM_next<=SM_confg_regiter2;
				end		
			SM_confg_regiter2:
				begin
				spi_data<=Value_register2;
				SM<=SM_spi_confg;
				SM_next<=SM_confg_regiter3;
				end				
			SM_confg_regiter3:
				begin
				spi_data<=Value_register3;
				SM<=SM_spi_confg;
				SM_next<=SM_confg_regiter4;
				end			
			SM_confg_regiter4:
				begin
				spi_data<=Value_register4;
				SM<=SM_spi_confg;
				SM_next<=SM_confg_regiter5;
				end	
			SM_confg_regiter5:
				begin
				spi_data<=Value_register5;
				SM<=SM_spi_confg;
				SM_next<=SM_confg_regiter6;
				end		
			SM_confg_regiter6:
				begin
				spi_data<=Value_register6;
				SM<=SM_spi_confg;
				SM_next<=SM_confg_regiter7;
				end
			SM_confg_regiter7:
				begin
				spi_data<=Value_register7;
				SM<=SM_spi_confg;
				SM_next<=SM_confg_regiter8;
				end
			SM_confg_regiter8:
				begin
				spi_data<=Value_register8;
				SM<=SM_spi_confg;
				//SM_next <= SM_RdCommd_Set;
				SM_next <= SM_PDPre;
				end
			SM_spi_toEEPROM:
				begin
				spi_data<=Value_toEEPROM;
				SM<=SM_spi_confg;
				//SM_next<=SM_RdCommd_Set;
				SM_next <= SM_confg_finish;
				end
			SM_spi_confg:
				if(cfg_cnt>=36)
					begin
					cfg_cnt<=8'h0;
					SM<=SM_spicfg_wait;
					end
				else
					begin
					if(cfg_cnt>=32)
						begin
						spi_clken<=1'b0;
						cfg_cnt<=cfg_cnt+1'b1;
						spi_le_wr<=1'b1;
						end
					else	
						begin
						spi_clken<=1'b1;
						spi_le_wr<=1'b0;
						spi_mosi<=spi_data[0];
						spi_data<=spi_data>>1'b1;
						cfg_cnt<=cfg_cnt+1'b1;	
						end
					end
			SM_spicfg_wait:
				begin
				wait_cnt<=wait_cnt+1'b1;
				if(wait_cnt>=32'd600)
					begin
					wait_cnt<=32'h0;
					SM<=SM_next;
					end
				end
			SM_confg_finish:
				begin
				cfg_finish<=1'b0;
				end
			SM_RdCommd_Set:
				begin
				spi_data<={24'h0,spi_reg_addr,4'he};
				spi_reg_addr <= spi_reg_addr + 1'd1;	//modified by guocheng
				if(spi_reg_addr>=4'h8)
					SM<=SM_confg_finish;
				else
					SM<=SM_RdCommd_Wr;
				end
			SM_RdCommd_Wr:
				if(cfg_cnt>=32)
					begin
					cfg_cnt<=8'h0;
					SM<=SM_RdCommd_RevPre;
					spi_clken<=1'b0;
					spi_le_wr<=1'b1;
					end	
				else
					begin
					spi_clken<=1'b1;
					spi_le_wr<=1'b0;
					spi_mosi<=spi_data[0];
					spi_data<=spi_data>>1'b1;
					cfg_cnt<=cfg_cnt+1'b1;					
					end
			SM_RdCommd_RevPre:
				if(spi_rd_reqack)
					begin
					SM<=SM_RdCommd_Set;
					spi_rd_reqrd<=1'b0;	//write enable
					end
				else
					spi_rd_reqrd<=1'b1; //read enable
			SM_PDPre:
				begin
				spi_data<=Value_PDPre;
				SM<=SM_spi_confg;
				SM_next <= SM_PDDone;
				end
			SM_PDDone:
				begin
				spi_data<=Value_PDDone;
				SM<=SM_spi_confg;
				SM_next <= SM_spi_toEEPROM;
				end
			default:
				SM<=SM_Idle;
			endcase
			
	always@(posedge clk_spi)
			if(spird_cnt>=36)
				begin
				spi_revdata<=32'h0; 
				spird_cnt<=8'h0;
				end
			else
				begin
				if(spird_cnt>=32)
					begin
					spi_rd_reqack<=1'b1;
					spi_le_rd<=1'b1;
					spird_cnt<=spird_cnt+1'b1;
					end
				else
					if(spi_rd_reqrd)
						begin
						spi_rd_reqack<=1'b0;
						spi_le_rd<=1'b0;
						spird_cnt<=spird_cnt+1'b1;
						spi_revdata[31]<=spi_miso;
						spi_revdata[30:0]<=spi_revdata[31:1];
						end	
				end	
endmodule
