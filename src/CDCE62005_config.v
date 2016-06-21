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
	
	localparam SM_confg_regiter0=4'h0,SM_confg_regiter1=4'h1,SM_confg_regiter2=4'h2,SM_confg_regiter3=4'h3,
				SM_confg_regiter4=4'h4,SM_confg_regiter5=4'h5,SM_confg_regiter6=4'h6,SM_spi_confg=4'h7,SM_spi_toEEPROM=4'h8,
				SM_confg_finish=4'h9,SM_Idle=4'ha,SM_RdCommd_Set=4'hb,SM_RdCommd_Wr=4'hc,SM_RdCommd_Rev=4'hd,SM_RdCommd_RevPre=4'he,SM_spicfg_wait=4'hf;
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
		   // Value_toEEPROM=32'h0000001f;
	  Value_toEEPROM=32'h80009cd8;
		 		


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
	reg[3:0]SM,SM_next;
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
				SM_next<=SM_spi_toEEPROM;
				end	
			SM_spi_toEEPROM:
				begin
				spi_data<=Value_toEEPROM;
				SM<=SM_spi_confg;
				SM_next<=SM_RdCommd_Set;				
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
				if(wait_cnt>=32'd60000)
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



				
			
