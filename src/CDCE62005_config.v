module CDCE62005_config(clk,clk_spi,en,spi_clk,spi_mosi,spi_miso,spi_le,spi_syn,spi_powerdn,cfg_finish,spi_revdata);
	input clk,clk_spi;
	input en;
	output spi_clk;
	output reg spi_mosi;
	input spi_miso;
	output spi_le;
	output spi_syn;
	output spi_powerdn;
	output reg cfg_finish;
	output reg[31:0] spi_revdata;
	
	assign spi_syn=1'b1;
	assign spi_powerdn=1'b1;
	
	localparam SM_confg_regiter0=8'h00,SM_confg_regiter1=8'h01,SM_confg_regiter2=8'h02,SM_confg_regiter3=8'h03,
				SM_confg_regiter4=8'h04,SM_confg_regiter5=8'h05,SM_confg_regiter6=8'h06,SM_spi_confg=8'h07,SM_spi_toEEPROM=8'h08,
	  SM_confg_finish=8'h09,SM_Idle=8'h0a,SM_RdCommd_Set=8'h0b,SM_RdCommd_Wr=8'h0c,SM_RdCommd_Rev=8'h0d,SM_RdCommd_RevPre=8'h0e,SM_spicfg_wait=8'h0f,SM_confg_regiter7=8'h10,
   SM_confg_regiter8=8'h11, SM_confg_regiter9=8'h12,SM_confg_regiter10=8'h13;
   
//	localparam Value_register0=32'hEB840300,		//250MHz
//					Value_register1=32'hEB840301,		//250MHz
//					Value_register2=32'hEB060302,		//100Mhz
//					Value_register3=32'hEA0E0303,		//No
//					Value_register4=32'hEA0E0314,		//No
//					Value_register5=32'h10108F35,		//
//					Value_register6=32'h04BE25E6,		//
//					Value_toEEPROM=32'h0000001f;		//
					
//	localparam  Value_register0=32'hEB800300,		//300MHz
//					Value_register1=32'hEB800301,		//300MHz
//					Value_register2=32'hEB800302,		//300MHz
//					Value_register3=32'hEB800303,		//300MHz
//					Value_register4=32'hEB800304,		//300MHz				
//					Value_register4=32'hEB140314,		//25MHz					
//					Value_register5=32'h10008F35,		//300MHz
//					Value_register6=32'h04BE02A6,		//
//					Value_toEEPROM=32'h0000001f;		//		

	// localparam  Value_register0=32'hE9800300,		//280MHz
					// Value_register1=32'hE9800301,		//280MHz
					// Value_register2=32'hE9800302,		//280MHz
					// Value_register3=32'hE9800303,		//280MHz
					// Value_register4=32'hE9800304,		//280MHz				
// //					Value_register4=32'hEB140314,		//25MHz					
// //					Value_register5=32'h10108F35,		//280MHz
// //					Value_register6=32'h04BE0D56,		//
					// Value_register5=32'h10248F35,		//280MHz
					// Value_register6=32'h04BE1D56,
					// Value_toEEPROM=32'h0000001f;		//	
		

/* -----\/----- EXCLUDED -----\/-----
 localparam  Value_register0=32'hE9800300,		//200MHz
					Value_register1=32'hE9800301,		//200MHz
					Value_register2=32'hE9800302,		//200MHz
					Value_register3=32'hE9800303,		//200MHz
					Value_register4=32'hE9800304,		//200MHz				
//					Value_register4=32'hEB140314,		//					
//					Value_register5=32'h10108F35,		/
////					Value_register6=32'h04BE0D56,		//
					Value_register5=32'h10008F35,		//200MHz
					Value_register6=32'h04BE0106,
					Value_toEEPROM=32'h0000001f;		//		
 -----/\----- EXCLUDED -----/\----- */

				



/* -----\/----- EXCLUDED -----\/-----right
//	localparam  Value_register0=32'hE9400300,		//打开1000MHz lvds
   	localparam  Value_register0=32'h81400300,               //打开1ghz lvpel，crystal
	            Value_register1=32'h81400301,	        
//		    Value_register2=32'hE8400302,		//关闭1000MHz lvds
	            Value_register2=32'h81400302,
		    Value_register3=32'hE8400303,		//关闭1000MHz
//	            Value_register4=32'h81400304,
		    Value_register4=32'hE8400304,		//关闭1000MHz				
//	            Value_register4=32'hEB140314,		//					
		    Value_register5=32'h10008F35,		//1000MHz
		    Value_register6=32'h04BE03E6,
		    Value_toEEPROM=32'h0000001f;
 -----/\----- EXCLUDED -----/\----- */

//外部输入10MHz，lvpecl输出1GHz	 		
//	localparam  Value_register0=32'hE9400300,		//打开1000MHz lvds
   	localparam  Value_register0=32'hEB400320,               //打开1ghz lvpel，crystal
	            Value_register1=32'hEB400321,	        
//		    Value_register2=32'hE8400302,		//关闭1000MHz lvds
	            Value_register2=32'hEB400302,
		    Value_register3=32'h68840303,		//关闭1000MHz
//	            Value_register4=32'h81400304,
		    Value_register4=32'h68800314,		//关闭1000MHz				
//	            Value_register4=32'hEB140314,		//					
		    Value_register5=32'h10000E65,		//1000MHz
		    Value_register6=32'h04BE09E6,
	  Value_register7=32'hBD0037F7,
	   Value_register8=32'h80001808,
/* -----\/----- EXCLUDED -----\/-----
	  Value_register9=32'h800094D8,
	  Value_register10=32'h80009CD8,
 -----/\----- EXCLUDED -----/\----- */
		    Value_toEEPROM=32'h0000001f;

/* -----\/----- EXCLUDED -----\/-----
//	localparam  Value_register0=32'hE9400300,		//打开1000MHz lvds
   	localparam  Value_register0=32'h81400300,               //打开1ghz lvpel，crystal
	            Value_register1=32'h81400301,	        
//		    Value_register2=32'hE8400302,		//关闭1000MHz lvds
	            Value_register2=32'h81400302,
		    Value_register3=32'hE8400303,		//关闭1000MHz
//	            Value_register4=32'h81400304,
		    Value_register4=32'hE8400304,		//关闭1000MHz				
//	            Value_register4=32'hEB140314,		//					
		    Value_register5=32'h10008EB5,		//1000MHz sec_sel lvds input i=1
		    Value_register6=32'h04BE09E6, //Fin*100
		    Value_toEEPROM=32'h0000001f;	
 -----/\----- EXCLUDED -----/\----- */// 外部输入10mhz lvds参考时钟
				
	reg[31:0] spi_data;
	reg[7:0]SM,SM_next;
	reg[7:0] cfg_cnt,spird_cnt;
	reg[3:0] spi_reg_addr;
	reg[31:0] wait_cnt;
	reg spi_le_rd,spi_le_wr,spi_rd_reqrd,spi_rd_reqack;
	reg spi_clken;
				
	assign spi_clk=spi_clken ? clk_spi : 1'b0;
	assign spi_le=spi_rd_reqrd ? spi_le_rd : spi_le_wr;
	
	always@(posedge clk)
		if(!en)
			begin
			spi_rd_reqrd<=1'b0;
			spi_le_wr<=1'b1;
			spi_mosi<=1'b0;
			cfg_cnt<=8'h0;
			cfg_finish<=1'b0;
			spi_reg_addr<=8'h0;
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
				SM_next<=SM_spi_toEEPROM;
				end
			  SM_spi_toEEPROM:
				begin
				spi_data<=Value_toEEPROM;
				SM<=SM_spi_confg;
				SM_next<=SM_RdCommd_Set;			
				end
/* -----\/----- EXCLUDED -----\/-----
			  SM_confg_regiter9:
				begin
				spi_data<=Value_register9;
				SM<=SM_spi_confg;
				SM_next<=SM_confg_regiter10;
				end
			  SM_confg_regiter10:
			    begin
				spi_data<=Value_register10;
				SM<=SM_spi_confg;
				SM_next<=SM_RdCommd_Set;
				end
 -----/\----- EXCLUDED -----/\----- */

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
				cfg_finish<=1'b1;
				end
			SM_RdCommd_Set:
				begin
				spi_data<={24'h0,spi_reg_addr,4'he};
//				spi_reg_addr<=spi_reg_addr+1'b1;
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
					spi_rd_reqrd<=1'b0;
					end
				else
					spi_rd_reqrd<=1'b1;
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



				
			
