-- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--/////////////////////////////////////////////////////////////////////////////
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 3.0
--  \   \         Application        : MIG
--  /   /         Filename           : phy_top.vhd
-- /___/   /\     Timestamp          : Nov 18, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This module
--  1. Instantiates all the modules used in the PHY
--Revision History:
--
--/////////////////////////////////////////////////////////////////////////////
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity qdr_phy_top is
  generic( 
    ADDR_WIDTH          : integer  := 19;     -- Adress Width
    DATA_WIDTH          : integer  := 72;     -- Data Width
    BW_WIDTH            : integer  := 8;      -- Byte Write Width
    BURST_LEN           : integer  := 4;      -- Burst Length
    CLK_PERIOD          : integer  := 3752;   -- Internal Fabric Clk Period (ps)
    REFCLK_FREQ         : real     := 300.0;  -- Reference Clk Feq for IODELAYs
    NUM_DEVICES         : integer  := 2;      -- Memory Devices
    FIXED_LATENCY_MODE  : integer  := 0;      -- Fixed Latency for data reads
    PHY_LATENCY         : integer  := 0;      -- Value for Fixed Latency Mode
    CLK_STABLE          : integer  := 2048;   -- Cycles till CQ/CQ# is stable
    IODELAY_GRP         : string   := "IODELAY_MIG"; -- May be assigned unique 
                                       -- name when mult IP cores : in design
    MEM_TYPE            : string   := "QDR2PLUS"; -- Memory Type (QDR2PLUS;QDR2)
    DEVICE_ARCH         : string   := "virtex6";  -- Device Architecture
    RST_ACT_LOW         : integer  := 1;          -- System Reset is active low
    PHASE_DETECT        : string   := "ON";       -- Enable Phase detector
    SIM_CAL_OPTION      : string   := "NONE";     -- Skip various calibration 
                                                  -- steps
    IBUF_LPWR_MODE      : string   := "OFF";      -- : in buffer low power mode
    IODELAY_HP_MODE     : string   := "ON";       -- IODELAY High Performance 
                                                  -- Mode
    CQ_BITS             : integer  := 1;          -- clog2(NUM_DEVICES - 1)   
    Q_BITS              : integer  := 7;          -- clog2(DATA_WIDTH - 1)
    DEVICE_TAPS         : integer  := 32;         -- Number of taps : in the 
                                                  -- IDELAY chain
    TAP_BITS            : integer  := 5;          -- clog2(DEVICE_TAPS - 1)
    DEBUG_PORT          : string   := "ON";       -- Debug using Chipscope 
                                                  -- controls 
    TCQ                 : integer  := 100;        -- register Delay
    SIM_INIT_OPTION     : string   := "NONE"      -- Simulation only. "NONE", "SIM_MODE"
  );
  port ( 
    -- System Signals
    clk                    : in  std_logic;       -- main system half freq clk
    rst_clk                : out std_logic;       -- reset sync to clk  
    sys_rst                : in  std_logic;       -- main write path reset  
    clk_wr                 : in  std_logic;       -- performance path clock
    clk_mem                : in  std_logic;       -- full frequency clock
    mmcm_locked            : in  std_logic;       -- MMCM is locked
    iodelay_ctrl_rdy       : in  std_logic;       -- ready from IODELAY CTLR
    
    -- PHY Write Path Interface
    wr_cmd0                : in std_logic;          -- wr command 0
    wr_cmd1                : in std_logic;          -- wr command 1
    -- wr address 0
    wr_addr0               : in std_logic_vector(ADDR_WIDTH-1 downto 0);  
    -- wr address 1  
    wr_addr1               : in std_logic_vector(ADDR_WIDTH-1 downto 0);       
    rd_cmd0                : in std_logic;          -- rd command 0
    rd_cmd1                : in std_logic;          -- rd command 1
    -- rd address 0
    rd_addr0               : in std_logic_vector(ADDR_WIDTH-1 downto 0);       
    -- rd address 1
    rd_addr1               : in std_logic_vector(ADDR_WIDTH-1 downto 0);       
    -- user write data 0
    wr_data0               : in std_logic_vector(DATA_WIDTH*2-1 downto 0);     
    -- user write data 1
    wr_data1               : in std_logic_vector(DATA_WIDTH*2-1 downto 0);     
    -- user byte writes 0
    wr_bw_n0               : in std_logic_vector(BW_WIDTH*2-1 downto 0);       
    -- user byte writes 1
    wr_bw_n1               : in std_logic_vector(BW_WIDTH*2-1 downto 0);       

    -- PHY Read Path Interface
    cal_done               : out std_logic;
    rd_valid0              : out std_logic;         -- Read valid for rd_data0
    rd_valid1              : out std_logic;         -- Read valid for rd_data1
    -- Read data 0
    rd_data0               : out std_logic_vector(DATA_WIDTH*2-1 downto 0);   
    -- Read data 1
    rd_data1               : out std_logic_vector(DATA_WIDTH*2-1 downto 0);   


    -- Memory Interface
    qdr_dll_off_n          : out std_logic;         -- QDR - turn off dll : in mem
    -- QDR clock K
    qdr_k_p                : out std_logic_vector(NUM_DEVICES-1 downto 0);    
    -- QDR clock K#
    qdr_k_n                : out std_logic_vector(NUM_DEVICES-1 downto 0);    
    -- QDR Memory Address
    qdr_sa                 : out std_logic_vector(ADDR_WIDTH-1 downto 0);     
    qdr_w_n                : out std_logic;         -- QDR Write 
    qdr_r_n                : out std_logic;         -- QDR Read
    -- QDR Byte Writes to Mem
    qdr_bw_n               : out std_logic_vector(BW_WIDTH-1 downto 0);       
    -- QDR Data to Memory
    qdr_d                  : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    -- QDR Data from Memory
    qdr_q                  : in  std_logic_vector(DATA_WIDTH-1 downto 0);     
    -- QDR echo clock CQ
    qdr_cq_p               : in std_logic_vector(NUM_DEVICES-1 downto 0);    
    -- QDR echo clock CQ#   
    qdr_cq_n               : in std_logic_vector(NUM_DEVICES-1 downto 0);    

    -- ChipScope Debug Signals
    -- cs debug - wr command
    dbg_phy_wr_cmd_n      : out std_logic_vector(1 downto 0);                
    -- cs debug - address
    dbg_phy_addr          : out std_logic_vector(ADDR_WIDTH*4-1 downto 0);   
    -- cs debug - rd command
    dbg_phy_rd_cmd_n      : out std_logic_vector(1 downto 0);                
    -- cs debug - wr data
    dbg_phy_wr_data       : out std_logic_vector(DATA_WIDTH*4-1 downto 0);   
    
    dbg_inc_cq_all        : in std_logic;           -- increment all CQs
    dbg_inc_cqn_all       : in std_logic;           -- increment all CQ#s
    dbg_inc_q_all         : in std_logic;           -- increment all Qs
    dbg_dec_cq_all        : in std_logic;           -- decrement all CQs   
    dbg_dec_cqn_all       : in std_logic;           -- decrement all CQ#s 
    dbg_dec_q_all         : in std_logic;           -- decrement all Qs   
    dbg_inc_cq            : in std_logic;           -- increment selected CQ  
    dbg_inc_cqn           : in std_logic;           -- increment selected CQ#
    dbg_inc_q             : in std_logic;           -- increment selected Q  
    dbg_dec_cq            : in std_logic;           -- decrement selected CQ  
    dbg_dec_cqn           : in std_logic;           -- decrement selected CQ# 
    dbg_dec_q             : in std_logic;           -- decrement selected Q
    -- selected CQ bit  
    dbg_sel_cq            : in std_logic_vector(CQ_BITS-1 downto 0);  
    -- selected CQ# bit
    dbg_sel_cqn           : in std_logic_vector(CQ_BITS-1 downto 0);  
    -- selected Q bit
    dbg_sel_q             : in std_logic_vector(Q_BITS-1 downto 0);   
    dbg_pd_off            : in std_logic;
    dbg_rd_stage1_cal     : out std_logic_vector(255 downto 0);                      
    dbg_cq_tapcnt         : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);  
    dbg_cqn_tapcnt        : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);  
    dbg_q_tapcnt          : out std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0);   
    dbg_clk_rd            : out std_logic_vector(NUM_DEVICES-1 downto 0);

    dbg_stage2_cal        : out std_logic_vector(127 downto 0);             -- stage 2 cal debug
    dbg_cq_num            : out std_logic_vector(CQ_BITS-1 downto 0);       -- current cq/cq# being calibrated
    dbg_q_bit             : out std_logic_vector(Q_BITS-1 downto 0);        -- current q being calibrated 
    dbg_valid_lat         : out std_logic_vector(4 downto 0);               -- latency of the system
    dbg_phase             : out std_logic_vector(NUM_DEVICES-1 downto 0);   -- data align phase indication
    dbg_inc_latency       : out std_logic_vector(NUM_DEVICES-1 downto 0);   -- increase latency for dcb
    dbg_dcb_wr_ptr        : out std_logic_vector(5*NUM_DEVICES-1 downto 0); -- dcb write pointers
    dbg_dcb_rd_ptr        : out std_logic_vector(5*NUM_DEVICES-1 downto 0); -- dcb read pointers
    dbg_dcb_din           : out std_logic_vector(4*DATA_WIDTH-1 downto 0);  -- dcb data in
    dbg_dcb_dout          : out std_logic_vector(4*DATA_WIDTH-1 downto 0);    -- dcb data out
    dbg_error_max_latency : out std_logic_vector(NUM_DEVICES-1 downto 0);   -- stage 2 cal max latency error
    dbg_error_adj_latency : out std_logic;                                  -- stage 2 cal latency adjustment error   
    dbg_pd_calib_start    : out std_logic_vector(NUM_DEVICES-1 downto 0);   -- indicates phase detector to start
    dbg_pd_calib_done     : out std_logic_vector(NUM_DEVICES-1 downto 0);   -- indicates phase detector is 
    dbg_pd_calib_error   : out std_logic_vector(NUM_DEVICES-1 downto 0);
    -- phy status
    dbg_phy_status        : out std_logic_vector(7 downto 0);
    dbg_align_rd0         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dbg_align_rd1         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dbg_align_fd0         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dbg_align_fd1         : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );  
  
end qdr_phy_top;

architecture arch of qdr_phy_top is
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arch : ARCHITECTURE IS
    "mig_v3_9_qdriip_V6, Coregen 13.3";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arch : ARCHITECTURE IS "qdriip_V6_phy,mig_v3_9,{LANGUAGE=VHDL, SYNTHESIS_TOOL=ISE, AXI_ENABLE=0, LEVEL=PHY, NO_OF_CONTROLLERS=1, INTERFACE_TYPE=QDR_II+_SRAM, CLK_PERIOD=16000, MEMORY_TYPE=components, MEMORY_PART=cy7c1565v18-400bzxc, DQ_WIDTH=36, NUM_DEVICES=1, FIXED_LATENCY_MODE=1, PHY_LATENCY=20, REFCLK_FREQ=200, MMCM_ADV_BANDWIDTH=OPTIMIZED, CLKFBOUT_MULT_F=11, CLKOUT_DIVIDE=11, DEBUG_PORT=OFF, IODELAY_HP_MODE=ON, INTERNAL_VREF=1, DCI_INOUTS=1, INPUT_CLK_TYPE=SINGLE_ENDED}";
  -- Width of each memory
  constant MEMORY_WIDTH     : integer := DATA_WIDTH / NUM_DEVICES;  

  -- Signal Delcarations
  signal rst_wr_clk         : std_logic;                          
  signal cal_stage1_start   : std_logic;                          
  signal cal_stage2_start   : std_logic;                          
  signal init_done          : std_logic;                          
  signal int_rd_cmd_n       : std_logic_vector(1 downto 0);              
  signal clk_rd             : std_logic_vector(NUM_DEVICES-1 downto 0);  
  signal rst_clk_rd         : std_logic_vector(NUM_DEVICES-1 downto 0);  
  signal int_wr_cmd_n       : std_logic_vector(1 downto 0);                    
  signal iob_addr_rise0     : std_logic_vector(ADDR_WIDTH-1 downto 0);       
  signal iob_addr_fall0     : std_logic_vector(ADDR_WIDTH-1 downto 0);      
  signal iob_addr_rise1     : std_logic_vector(ADDR_WIDTH-1 downto 0);      
  signal iob_addr_fall1     : std_logic_vector(ADDR_WIDTH-1 downto 0);      
  signal iob_data_rise0     : std_logic_vector(DATA_WIDTH-1 downto 0);       
  signal iob_data_fall0     : std_logic_vector(DATA_WIDTH-1 downto 0);      
  signal iob_data_rise1     : std_logic_vector(DATA_WIDTH-1 downto 0);       
  signal iob_data_fall1     : std_logic_vector(DATA_WIDTH-1 downto 0);      
  signal iob_bw_rise0       : std_logic_vector(BW_WIDTH-1 downto 0);         
  signal iob_bw_fall0       : std_logic_vector(BW_WIDTH-1 downto 0);          
  signal iob_bw_rise1       : std_logic_vector(BW_WIDTH-1 downto 0);         
  signal iob_bw_fall1       : std_logic_vector(BW_WIDTH-1 downto 0);   
  signal cq_dly_ce          : std_logic_vector(NUM_DEVICES-1 downto 0);          
  signal cq_dly_inc         : std_logic_vector(NUM_DEVICES-1 downto 0);          
  signal cq_dly_rst         : std_logic_vector(NUM_DEVICES-1 downto 0);          
  signal cq_dly_load        : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal cqn_dly_ce         : std_logic_vector(NUM_DEVICES-1 downto 0);          
  signal cqn_dly_inc        : std_logic_vector(NUM_DEVICES-1 downto 0);         
  signal cqn_dly_rst        : std_logic_vector(NUM_DEVICES-1 downto 0);         
  signal cqn_dly_load       : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal q_dly_ce           : std_logic_vector(DATA_WIDTH-1 downto 0);             
  signal q_dly_inc          : std_logic_vector(NUM_DEVICES-1 downto 0);           
  signal q_dly_rst          : std_logic_vector(DATA_WIDTH-1 downto 0);           
  signal q_dly_load         : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal q_dly_clkinv       : std_logic_vector(NUM_DEVICES-1 downto 0);        
  signal iserdes_rd0        : std_logic_vector(DATA_WIDTH-1 downto 0);          
  signal iserdes_fd0        : std_logic_vector(DATA_WIDTH-1 downto 0);          
  signal iserdes_rd1        : std_logic_vector(DATA_WIDTH-1 downto 0);          
  signal iserdes_fd1        : std_logic_vector(DATA_WIDTH-1 downto 0);          
  signal clk_cq             : std_logic_vector(NUM_DEVICES-1 downto 0);            
  signal clk_cqn            : std_logic_vector(NUM_DEVICES-1 downto 0);  

  signal cal_done_sig           : std_logic;
  signal rst_clk_sig            : std_logic;
  signal iserdes_rst            : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_pd_calib_done_int  : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_pd_calib_error_int : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_pd_calib_start_int : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal pd_source              : std_logic_vector(NUM_DEVICES-1 downto 0);   
  
  attribute syn_keep   : boolean;
  attribute syn_keep of clk_rd  : signal is TRUE;

  component phy_write_top 
  generic( 
    BURST_LEN               : integer ;     -- Burst Length
    REFCLK_FREQ             : real    ;     -- Ref. Clk Freq. for IODELAYs
    CLK_PERIOD              : integer ;     -- Internal Fabric Clk Period (in ps)
    NUM_DEVICES             : integer ;     -- Memory Devices
    DATA_WIDTH              : integer ;     -- Data Width
    BW_WIDTH                : integer ;     -- Byte Write Width
    ADDR_WIDTH              : integer ;     -- Address Width
    IODELAY_GRP             : string;       -- May be assigned unique name 
                                            -- when mult IP cores in design
    TCQ                     : integer       -- register Delay
  );
  port ( 
    clk                : in std_logic;       -- main system half freq clk
    rst_wr_clk         : in std_logic;       -- main write path reset  
    clk_mem            : in std_logic;       -- full frequency clock 
    cal_done            : in  std_logic;      -- calibration done
    cal_stage1_start   : in  std_logic;      -- stage 1 calibration start
    cal_stage2_start   : in  std_logic;      -- stage 2 calibration start
    init_done          : out std_logic;      -- init done cal can begin  
    wr_cmd0       : in std_logic;                                -- wr command 0
    wr_cmd1       : in std_logic;                                -- wr command 1
    wr_addr0      : in std_logic_vector(ADDR_WIDTH-1 downto 0);  -- wr address 0
    wr_addr1      : in std_logic_vector(ADDR_WIDTH-1 downto 0);  -- wr address 1
    rd_cmd0       : in std_logic;                                -- rd command 0
    rd_cmd1       : in std_logic;                                -- rd command 1
    rd_addr0      : in std_logic_vector(ADDR_WIDTH-1 downto 0);  -- rd address 0
    rd_addr1      : in std_logic_vector(ADDR_WIDTH-1 downto 0);  -- rd address 1
    wr_data0      : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
    wr_data1      : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
    wr_bw_n0      : in std_logic_vector(BW_WIDTH*2-1 downto 0);  
    wr_bw_n1      : in std_logic_vector(BW_WIDTH*2-1 downto 0); 
    int_rd_cmd_n          : out std_logic_vector(1 downto 0);                
    int_wr_cmd_n          : out std_logic_vector(1 downto 0);                
    iob_addr_rise0        : out std_logic_vector(ADDR_WIDTH-1 downto 0);     
    iob_addr_fall0        : out std_logic_vector(ADDR_WIDTH-1 downto 0);     
    iob_addr_rise1        : out std_logic_vector(ADDR_WIDTH-1 downto 0);     
    iob_addr_fall1        : out std_logic_vector(ADDR_WIDTH-1 downto 0);      
    iob_data_rise0        : out  std_logic_vector(DATA_WIDTH-1 downto 0);     
    iob_data_fall0        : out  std_logic_vector(DATA_WIDTH-1 downto 0);     
    iob_data_rise1        : out  std_logic_vector(DATA_WIDTH-1 downto 0);     
    iob_data_fall1        : out  std_logic_vector(DATA_WIDTH-1 downto 0);     
    iob_bw_rise0          : out  std_logic_vector(BW_WIDTH-1 downto 0);       
    iob_bw_fall0          : out  std_logic_vector(BW_WIDTH-1 downto 0);       
    iob_bw_rise1          : out  std_logic_vector(BW_WIDTH-1 downto 0);       
    iob_bw_fall1          : out  std_logic_vector(BW_WIDTH-1 downto 0);  
    dbg_phy_wr_cmd_n     : out  std_logic_vector(1 downto 0);               
    dbg_phy_addr         : out  std_logic_vector(ADDR_WIDTH*4-1 downto 0);  
    dbg_phy_rd_cmd_n     : out  std_logic_vector(1 downto 0);               
    dbg_phy_wr_data      : out  std_logic_vector(DATA_WIDTH*4-1 downto 0)   
  );  
  end component;

  component phy_read_top
  generic (
    BURST_LEN           : integer ;     -- Burst Length
    DATA_WIDTH          : integer ;     -- Total data width across all memories
    NUM_DEVICES         : integer ;     -- Number of memory devices
    FIXED_LATENCY_MODE  : integer ;     -- fixed latency mode
    PHY_LATENCY         : integer ;     -- Indicates the desired latency for 
                                        -- fixed latency mode
    CLK_PERIOD          : integer ;     -- Indicates the number of picoseconds for 
                                        -- one CLK period
    REFCLK_FREQ         : real    ;     -- Indicates the IDELAYCTRL reference 
                                        -- clock frequency
    DEVICE_TAPS         : integer ;     -- Number of taps in target IODELAY
    PHASE_DETECT        : string  ;     -- Enable Phase detector
    TAP_BITS            : integer ;     -- Number of bits needed to represent 
                                        -- DEVICE_TAPS
    MEMORY_WIDTH        : integer ;     -- Width of each memory
    IODELAY_GRP         : string  ;     -- May be assigned unique name when mult 
                                        -- IP cores in design
    SIM_CAL_OPTION      : string  ;     -- Skip various calibration steps - 
                                        -- "NONE; "FAST_CAL"; "SKIP_CAL"
    SIM_INIT_OPTION     : string  ;
    MEM_TYPE            : string  ;     -- Memory Type (QDR2PLUS; QDR2)
    CQ_BITS             : integer ;     -- clog2(NUM_DEVICES - 1)   
    Q_BITS              : integer ;     -- clog2(DATA_WIDTH - 1)  
    DEBUG_PORT          : string;       -- Debug using Chipscope controls 
    TCQ                 : integer       -- register delay
  );
  port(
    clk                   : in  std_logic;     -- main system half freq clk
    clk_rd                : in  std_logic_vector(NUM_DEVICES-1 downto 0);            
    rst_clk               : in  std_logic;     -- main read path reset sync to clk
    rst_clk_rd            : in  std_logic_vector(NUM_DEVICES-1 downto 0);           
    cq_dly_ce             : out std_logic_vector(NUM_DEVICES-1 downto 0);            
    cq_dly_inc            : out std_logic_vector(NUM_DEVICES-1 downto 0);             
    cq_dly_rst            : out std_logic_vector(NUM_DEVICES-1 downto 0);             
    cq_dly_load           : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);    
    cqn_dly_ce            : out std_logic_vector(NUM_DEVICES-1 downto 0);             
    cqn_dly_inc           : out std_logic_vector(NUM_DEVICES-1 downto 0);             
    cqn_dly_rst           : out std_logic_vector(NUM_DEVICES-1 downto 0);             
    cqn_dly_load          : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);    
    q_dly_ce              : out std_logic_vector(DATA_WIDTH-1 downto 0);              
    q_dly_inc             : out std_logic_vector(NUM_DEVICES-1 downto 0);             
    q_dly_rst             : out std_logic_vector(DATA_WIDTH-1 downto 0);              
    q_dly_load            : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);    
    q_dly_clkinv          : out std_logic_vector(NUM_DEVICES-1 downto 0);             
    iserdes_rst           : out std_logic_vector(NUM_DEVICES-1 downto 0);
    iserdes_rd0           : in  std_logic_vector(DATA_WIDTH-1 downto 0);              
    iserdes_fd0           : in  std_logic_vector(DATA_WIDTH-1 downto 0);              
    iserdes_rd1           : in  std_logic_vector(DATA_WIDTH-1 downto 0);              
    iserdes_fd1           : in  std_logic_vector(DATA_WIDTH-1 downto 0);              
    cal_done              : out std_logic;        -- calibration done
    rd_data0              : out std_logic_vector(DATA_WIDTH*2-1 downto 0);       
    rd_data1              : out std_logic_vector(DATA_WIDTH*2-1 downto 0);       
    rd_valid0             : out std_logic;        -- user read data 0 valid
    rd_valid1             : out std_logic;        -- user read data 1 valid
    init_done             : in  std_logic;        -- initialization complete
    cal_stage1_start      : out std_logic;        -- stage 1 calibration start
    cal_stage2_start      : out std_logic;        -- stage 2 calibration start
    int_rd_cmd_n          : in  std_logic_vector(1 downto 0);   -- internal rd cmd
    clk_cq                : in std_logic_vector(NUM_DEVICES-1 downto 0);             
    clk_cqn               : in std_logic_vector(NUM_DEVICES-1 downto 0);             
    pd_source             : in std_logic_vector(NUM_DEVICES-1 downto 0);  
    clk_mem               : in std_logic;         -- Full frequency clock
    clk_wr                : in std_logic;
    rst_wr_clk            : in std_logic;         -- Reset write path reset
    dbg_inc_cq_all        : in std_logic;           -- increment all CQ#s
    dbg_inc_cqn_all      : in std_logic;          -- increment all CQn#s
    dbg_inc_q_all        : in std_logic;          -- increment all Qs
    dbg_dec_cq_all       : in std_logic;          -- decrement all CQs   
    dbg_dec_cqn_all      : in std_logic;          -- decrement all CQ#s 
    dbg_dec_q_all        : in std_logic;          -- decrement all Qs   
    dbg_inc_cq           : in std_logic;          -- increment selected CQ  
    dbg_inc_cqn          : in std_logic;          -- increment selected CQ#
    dbg_inc_q            : in std_logic;          -- increment selected Q  
    dbg_dec_cq           : in std_logic;          -- decrement selected CQ  
    dbg_dec_cqn          : in std_logic;          -- decrement selected CQ# 
    dbg_dec_q            : in std_logic;          -- decrement selected Q   
    dbg_sel_cq           : in std_logic_vector(CQ_BITS-1 downto 0);  
    dbg_sel_cqn          : in std_logic_vector(CQ_BITS-1 downto 0);                 
    dbg_sel_q            : in std_logic_vector(Q_BITS-1 downto 0);
    dbg_pd_off           : in std_logic;                  
    dbg_rd_stage1_cal    : out std_logic_vector(255 downto 0);
    dbg_stage2_cal       : out std_logic_vector(127 downto 0);
    dbg_cq_num           : out std_logic_vector(CQ_BITS-1 downto 0);
    dbg_q_bit            : out std_logic_vector(Q_BITS-1 downto 0);
    dbg_valid_lat        : out std_logic_vector(4 downto 0);
    dbg_phase            : out std_logic_vector(NUM_DEVICES-1 downto 0);
    dbg_inc_latency      : out std_logic_vector(NUM_DEVICES-1 downto 0);
    dbg_dcb_wr_ptr       : out std_logic_vector(5*NUM_DEVICES-1 downto 0);
    dbg_dcb_rd_ptr       : out std_logic_vector(5*NUM_DEVICES-1 downto 0);
    dbg_dcb_din          : out std_logic_vector(4*DATA_WIDTH-1 downto 0);
    dbg_dcb_dout         : out std_logic_vector(4*DATA_WIDTH-1 downto 0);
    dbg_error_max_latency: out std_logic_vector(NUM_DEVICES-1 downto 0);
    dbg_error_adj_latency: out std_logic;
    dbg_pd_calib_start   : out std_logic_vector(NUM_DEVICES-1 downto 0);
    dbg_pd_calib_done    : out std_logic_vector(NUM_DEVICES-1 downto 0); 
    dbg_pd_calib_error   : out std_logic_vector(NUM_DEVICES-1 downto 0);
    dbg_align_rd0        : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dbg_align_rd1        : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dbg_align_fd0        : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dbg_align_fd1        : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
  end component;

  component phy_iob
  generic(
    DATA_WIDTH      : integer;            -- Data Width
    ADDR_WIDTH      : integer;            -- Adress Width
    BW_WIDTH        : integer;            -- Byte Write Width
    REFCLK_FREQ     : real;               -- Reference Clk Feq for IODELAYs
    CLK_PERIOD      : integer;            -- Internal Fabric Clk Period (ps)
    BURST_LEN       : integer;            -- Burst Length
    NUM_DEVICES     : integer;            -- Memory Devices
    IODELAY_GRP     : string;             -- May be assigned unique name 
                                          -- when mult IP cores in design
    DEVICE_TAPS     : integer;            -- Number of taps in target IODELAY
    TAP_BITS        : integer;            -- Number of bits needed to represent
                                          -- DEVICE_TAPS
    MEMORY_WIDTH    : integer;            -- Width of each memory
    IBUF_LPWR_MODE  : string;             -- Input buffer low power mode
    IODELAY_HP_MODE : string;             -- IODELAY High Performance Mode
    SIM_INIT_OPTION : string;             -- Simulation Only mode
    TCQ             : integer             -- register Delay
  );
  port(
    clk             : in  std_logic;      -- main system half freq clk   
    rst_clk         : in  std_logic;      
    rst_wr_clk      : in  std_logic;      -- main write path reset 
    clk_mem         : in  std_logic;      -- full frequency clock
    clk_rd          : out std_logic_vector(NUM_DEVICES-1 downto 0);               
    rst_clk_rd      : in  std_logic_vector(NUM_DEVICES-1 downto 0); 
    int_rd_cmd_n    : in  std_logic_vector(1 downto 0);             
    int_wr_cmd_n    : in  std_logic_vector(1 downto 0);             
    iob_addr_rise0  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  
    iob_addr_fall0  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  
    iob_addr_rise1  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  
    iob_addr_fall1  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  
    iob_data_rise0  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  
    iob_data_fall0  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  
    iob_data_rise1  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  
    iob_data_fall1  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  
    iob_bw_rise0    : in  std_logic_vector(BW_WIDTH-1 downto 0);    
    iob_bw_fall0    : in  std_logic_vector(BW_WIDTH-1 downto 0);    
    iob_bw_rise1    : in  std_logic_vector(BW_WIDTH-1 downto 0);    
    iob_bw_fall1    : in  std_logic_vector(BW_WIDTH-1 downto 0);                  
    clk_cq          : out std_logic_vector(NUM_DEVICES-1 downto 0);            
    clk_cqn         : out std_logic_vector(NUM_DEVICES-1 downto 0);            
    pd_source       : out std_logic_vector(NUM_DEVICES-1 downto 0);            
    cq_dly_ce       : in  std_logic_vector(NUM_DEVICES-1 downto 0);            
    cq_dly_inc      : in  std_logic_vector(NUM_DEVICES-1 downto 0);            
    cq_dly_rst      : in  std_logic_vector(NUM_DEVICES-1 downto 0);            
    cq_dly_load     : in  std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);   
    dbg_cq_tapcnt   : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);       
    cqn_dly_ce      : in  std_logic_vector(NUM_DEVICES-1 downto 0);            
    cqn_dly_inc     : in  std_logic_vector(NUM_DEVICES-1 downto 0);            
    cqn_dly_rst     : in  std_logic_vector(NUM_DEVICES-1 downto 0);            
    cqn_dly_load    : in  std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);   
    dbg_cqn_tapcnt  : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);      
    q_dly_ce        : in  std_logic_vector(DATA_WIDTH-1 downto 0);        
    q_dly_inc       : in  std_logic_vector(NUM_DEVICES-1 downto 0);            
    q_dly_rst       : in  std_logic_vector(DATA_WIDTH-1 downto 0);             
    q_dly_load      : in  std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);   
    dbg_q_tapcnt    : out std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0);    
    q_dly_clkinv    : in  std_logic_vector(NUM_DEVICES-1 downto 0);            
    iserdes_rst     : in  std_logic_vector(NUM_DEVICES-1 downto 0);
    iserdes_rd0     : out std_logic_vector(DATA_WIDTH-1 downto 0);             
    iserdes_fd0     : out std_logic_vector(DATA_WIDTH-1 downto 0);             
    iserdes_rd1     : out std_logic_vector(DATA_WIDTH-1 downto 0);             
    iserdes_fd1     : out std_logic_vector(DATA_WIDTH-1 downto 0);             
    dbg_clk_rd      : out std_logic_vector(NUM_DEVICES-1 downto 0);           
    mem_k_p         : out std_logic_vector(NUM_DEVICES-1 downto 0);  
    mem_k_n         : out std_logic_vector(NUM_DEVICES-1 downto 0);  
    mem_sa          : out std_logic_vector(ADDR_WIDTH-1 downto 0);   
    mem_w_n         : out std_logic;                 
    mem_r_n         : out std_logic;                
    mem_bw_n        : out std_logic_vector(BW_WIDTH-1 downto 0);                  
    mem_d           : out std_logic_vector(DATA_WIDTH-1 downto 0);                
    mem_cq_p        : in std_logic_vector(NUM_DEVICES-1 downto 0);               
    mem_cq_n        : in std_logic_vector(NUM_DEVICES-1 downto 0);           
    mem_q           : in  std_logic_vector(DATA_WIDTH-1 downto 0)             
    );
  end component;

  component phy_reset_sync
  generic(
    CLK_STABLE       : integer;            -- Cycles till CQ/CQ# are stable
    CLK_PERIOD       : integer;            -- Internal Fabric Clk Period (in ps)
    RST_ACT_LOW      : integer;            -- sys reset is active low
    NUM_DEVICES      : integer;            -- No. of Memory Devices
    SIM_INIT_OPTION  : string;             -- Simulation Only mode
    TCQ              : integer             -- Register Delay
  );
  port(
    sys_rst          : in  std_logic;      -- System Reset from MMCM
    clk              : in  std_logic;      -- Half Freq. System Clock
    rst_clk          : out std_logic;      -- Reset Sync to CLK
    rst_wr_clk       : out std_logic;      -- Reset Sync to CLK for write path only
    -- Read Path clock generated from CQ/CQ#
    clk_rd           : in  std_logic_vector(NUM_DEVICES-1 downto 0);  
    -- Reset Sync to CLK_RD
    rst_clk_rd       : out std_logic_vector(NUM_DEVICES-1 downto 0);  
    mmcm_locked      : in  std_logic;      -- MMCM clocks are locked
    iodelay_ctrl_rdy : in  std_logic;      -- IODELAY controller ready signal
    mem_dll_off_n    : out std_logic       -- DLL off signal to Memory Device
  );                                                             
  end component;                                                  

   
  function or_br ( 
    var : std_logic_vector
  ) return std_logic is
    variable tmp : std_logic := '0' ;
  begin
    for i in 0 to (var'length-1) loop
      tmp := tmp or var(i);
    end loop;
    return tmp;
  end function or_br;                                                
 

begin

  -- assign output
  cal_done            <= cal_done_sig;
  rst_clk             <= rst_clk_sig;
  dbg_pd_calib_start  <= dbg_pd_calib_start_int;
  dbg_pd_calib_done   <= dbg_pd_calib_done_int;
  dbg_pd_calib_error  <= dbg_pd_calib_error_int;

  -- Debug Signals
  dbg_phy_status(0) <= iodelay_ctrl_rdy;  
  dbg_phy_status(1) <= mmcm_locked; 
  dbg_phy_status(2) <= init_done;
  dbg_phy_status(3) <= cal_stage1_start;
  dbg_phy_status(4) <= cal_stage2_start;
  dbg_phy_status(5) <= or_br(dbg_pd_calib_start_int);
  dbg_phy_status(6) <= or_br(dbg_pd_calib_done_int);
  dbg_phy_status(7) <= cal_done_sig;

  -- Instantiate the Top of the Write Path
  u_phy_write_top : phy_write_top 
  generic map(
    BURST_LEN        => BURST_LEN,
    REFCLK_FREQ      => REFCLK_FREQ,
    CLK_PERIOD       => CLK_PERIOD,
    NUM_DEVICES      => NUM_DEVICES,
    DATA_WIDTH       => DATA_WIDTH,
    BW_WIDTH         => BW_WIDTH,
    ADDR_WIDTH       => ADDR_WIDTH,
    IODELAY_GRP      => IODELAY_GRP,
    TCQ              => TCQ
  )    
  port map( 
    clk              => clk,            
    rst_wr_clk       => rst_wr_clk,  
    clk_mem          => clk_mem,  
    cal_done         => cal_done_sig,  
    cal_stage1_start => cal_stage1_start,
    cal_stage2_start => cal_stage2_start,
    init_done        => init_done, 
    int_rd_cmd_n     => int_rd_cmd_n,
    int_wr_cmd_n     => int_wr_cmd_n,
    wr_cmd0          => wr_cmd0,
    wr_cmd1          => wr_cmd1,
    wr_addr0         => wr_addr0,
    wr_addr1         => wr_addr1, 
    rd_cmd0          => rd_cmd0, 
    rd_cmd1          => rd_cmd1, 
    rd_addr0         => rd_addr0, 
    rd_addr1         => rd_addr1,  
    wr_data0         => wr_data0, 
    wr_data1         => wr_data1,  
    wr_bw_n0         => wr_bw_n0,  
    wr_bw_n1         => wr_bw_n1,
    iob_addr_rise0   => iob_addr_rise0, 
    iob_addr_fall0   => iob_addr_fall0, 
    iob_addr_rise1   => iob_addr_rise1, 
    iob_addr_fall1   => iob_addr_fall1,
    iob_data_rise0   => iob_data_rise0,
    iob_data_fall0   => iob_data_fall0, 
    iob_data_rise1   => iob_data_rise1,
    iob_data_fall1   => iob_data_fall1,
    iob_bw_rise0     => iob_bw_rise0, 
    iob_bw_fall0     => iob_bw_fall0, 
    iob_bw_rise1     => iob_bw_rise1,  
    iob_bw_fall1     => iob_bw_fall1,
    dbg_phy_wr_cmd_n => dbg_phy_wr_cmd_n,
    dbg_phy_addr     => dbg_phy_addr,    
    dbg_phy_rd_cmd_n => dbg_phy_rd_cmd_n,
    dbg_phy_wr_data  => dbg_phy_wr_data
    );

    -- Instantiate the top of the read path
  u_phy_read_top : phy_read_top 
  generic map(
    BURST_LEN          => BURST_LEN,
    DATA_WIDTH         => DATA_WIDTH,
    NUM_DEVICES        => NUM_DEVICES,
    FIXED_LATENCY_MODE => FIXED_LATENCY_MODE,
    PHY_LATENCY        => PHY_LATENCY,
    CLK_PERIOD         => CLK_PERIOD,
    REFCLK_FREQ        => REFCLK_FREQ,
    DEVICE_TAPS        => DEVICE_TAPS,
    PHASE_DETECT       => PHASE_DETECT,
    TAP_BITS           => TAP_BITS,
    MEMORY_WIDTH       => MEMORY_WIDTH,
    IODELAY_GRP        => IODELAY_GRP,
    SIM_CAL_OPTION     => SIM_CAL_OPTION,
    SIM_INIT_OPTION    => SIM_INIT_OPTION,
    MEM_TYPE           => MEM_TYPE,
    CQ_BITS            => CQ_BITS,
    Q_BITS             => Q_BITS,
    DEBUG_PORT         => DEBUG_PORT, 
    TCQ                => TCQ
  )    
  port map( 
    clk                     => clk,
    clk_rd                  => clk_rd,
    rst_clk                 => rst_clk_sig,
    rst_clk_rd              => rst_clk_rd,
    cq_dly_ce               => cq_dly_ce,
    cq_dly_inc              => cq_dly_inc,
    cq_dly_rst              => cq_dly_rst,
    cq_dly_load             => cq_dly_load,
    cqn_dly_ce              => cqn_dly_ce,
    cqn_dly_inc             => cqn_dly_inc,
    cqn_dly_rst             => cqn_dly_rst,
    cqn_dly_load            => cqn_dly_load,
    q_dly_ce                => q_dly_ce,
    q_dly_inc               => q_dly_inc,
    q_dly_rst               => q_dly_rst,
    q_dly_load              => q_dly_load,
    q_dly_clkinv            => q_dly_clkinv,
    iserdes_rst             => iserdes_rst,
    iserdes_rd0             => iserdes_rd0,
    iserdes_fd0             => iserdes_fd0,
    iserdes_rd1             => iserdes_rd1,
    iserdes_fd1             => iserdes_fd1,
    cal_done                => cal_done_sig,
    rd_data0                => rd_data0,
    rd_data1                => rd_data1,
    rd_valid0               => rd_valid0,
    rd_valid1               => rd_valid1,
    init_done               => init_done,
    cal_stage1_start        => cal_stage1_start,
    cal_stage2_start        => cal_stage2_start,
    int_rd_cmd_n            => int_rd_cmd_n,
    clk_cq                  => clk_cq,
    clk_cqn                 => clk_cqn,
    pd_source               => pd_source,
    clk_mem                 => clk_mem,
    clk_wr                  => clk_wr,
    rst_wr_clk              => rst_wr_clk,
    dbg_rd_stage1_cal       => dbg_rd_stage1_cal,
    dbg_inc_cq_all          => dbg_inc_cq_all,    
    dbg_inc_cqn_all         => dbg_inc_cqn_all,   
    dbg_inc_q_all           => dbg_inc_q_all,     
    dbg_dec_cq_all          => dbg_dec_cq_all,    
    dbg_dec_cqn_all         => dbg_dec_cqn_all,   
    dbg_dec_q_all           => dbg_dec_q_all,     
    dbg_inc_cq              => dbg_inc_cq,        
    dbg_inc_cqn             => dbg_inc_cqn,       
    dbg_inc_q               => dbg_inc_q,         
    dbg_dec_cq              => dbg_dec_cq,        
    dbg_dec_cqn             => dbg_dec_cqn,       
    dbg_dec_q               => dbg_dec_q,         
    dbg_sel_cq              => dbg_sel_cq,        
    dbg_sel_cqn             => dbg_sel_cqn,       
    dbg_sel_q               => dbg_sel_q,
    dbg_pd_off              => dbg_pd_off,
    dbg_stage2_cal          => dbg_stage2_cal,
    dbg_cq_num              => dbg_cq_num,
    dbg_q_bit               => dbg_q_bit,
    dbg_valid_lat           => dbg_valid_lat,
    dbg_phase               => dbg_phase,
    dbg_inc_latency         => dbg_inc_latency,
    dbg_dcb_wr_ptr          => dbg_dcb_wr_ptr,
    dbg_dcb_rd_ptr          => dbg_dcb_rd_ptr,
    dbg_dcb_din             => dbg_dcb_din,
    dbg_dcb_dout            => dbg_dcb_dout,
    dbg_error_max_latency   => dbg_error_max_latency,
    dbg_error_adj_latency   => dbg_error_adj_latency,
    dbg_pd_calib_start      => dbg_pd_calib_start_int,
    dbg_pd_calib_done       => dbg_pd_calib_done_int,
    dbg_pd_calib_error      => dbg_pd_calib_error_int,
    dbg_align_rd0           => dbg_align_rd0,
    dbg_align_rd1           => dbg_align_rd1,
    dbg_align_fd0           => dbg_align_fd0,
    dbg_align_fd1           => dbg_align_fd1
    );  
    
    -- Instantiate the IOB module
  u_phy_iob : phy_iob 
  generic map(
    DATA_WIDTH       => DATA_WIDTH,
    ADDR_WIDTH       => ADDR_WIDTH,
    BW_WIDTH         => BW_WIDTH,
    REFCLK_FREQ      => REFCLK_FREQ,
    CLK_PERIOD       => CLK_PERIOD,
    BURST_LEN        => BURST_LEN,
    NUM_DEVICES      => NUM_DEVICES,
    IODELAY_GRP      => IODELAY_GRP,
    DEVICE_TAPS      => DEVICE_TAPS,
    TAP_BITS         => TAP_BITS,
    MEMORY_WIDTH     => MEMORY_WIDTH,
    IBUF_LPWR_MODE   => IBUF_LPWR_MODE,
    IODELAY_HP_MODE  => IODELAY_HP_MODE,
    SIM_INIT_OPTION  => SIM_INIT_OPTION,
    TCQ              => TCQ
    )  
  port map( 
    clk             => clk,         
    rst_clk         => rst_clk_sig,   
    rst_wr_clk      => rst_wr_clk,
    clk_mem         => clk_mem,
    clk_rd          => clk_rd,
    rst_clk_rd      => rst_clk_rd,
    int_rd_cmd_n    => int_rd_cmd_n,
    int_wr_cmd_n    => int_wr_cmd_n,     
    iob_addr_rise0  => iob_addr_rise0, 
    iob_addr_fall0  => iob_addr_fall0, 
    iob_addr_rise1  => iob_addr_rise1, 
    iob_addr_fall1  => iob_addr_fall1,
    iob_data_rise0  => iob_data_rise0,
    iob_data_fall0  => iob_data_fall0, 
    iob_data_rise1  => iob_data_rise1,
    iob_data_fall1  => iob_data_fall1,
    iob_bw_rise0    => iob_bw_rise0, 
    iob_bw_fall0    => iob_bw_fall0, 
    iob_bw_rise1    => iob_bw_rise1,  
    iob_bw_fall1    => iob_bw_fall1,
    clk_cq          => clk_cq,
    clk_cqn         => clk_cqn,
    pd_source       => pd_source,
    cq_dly_ce       => cq_dly_ce,
    cq_dly_inc      => cq_dly_inc,
    cq_dly_rst      => cq_dly_rst,
    cq_dly_load     => cq_dly_load,    
    cqn_dly_ce      => cqn_dly_ce,
    cqn_dly_inc     => cqn_dly_inc,
    cqn_dly_rst     => cqn_dly_rst,
    cqn_dly_load    => cqn_dly_load,  
    q_dly_ce        => q_dly_ce,
    q_dly_inc       => q_dly_inc,
    q_dly_rst       => q_dly_rst,
    q_dly_load      => q_dly_load,
    dbg_cq_tapcnt   => dbg_cq_tapcnt, 
    dbg_cqn_tapcnt  => dbg_cqn_tapcnt,
    dbg_q_tapcnt    => dbg_q_tapcnt,
    q_dly_clkinv    => q_dly_clkinv,
    iserdes_rst     => iserdes_rst,
    iserdes_rd0     => iserdes_rd0,
    iserdes_fd0     => iserdes_fd0,
    iserdes_rd1     => iserdes_rd1,
    iserdes_fd1     => iserdes_fd1,
    mem_k_p         => qdr_k_p,  
    mem_k_n         => qdr_k_n,
    mem_sa          => qdr_sa,          
    mem_r_n         => qdr_r_n,          
    mem_w_n         => qdr_w_n,          
    mem_d           => qdr_d,         
    mem_bw_n        => qdr_bw_n,
    mem_cq_p        => qdr_cq_p,
    mem_cq_n        => qdr_cq_n,
    mem_q           => qdr_q,
    dbg_clk_rd      => dbg_clk_rd
    );  

  u_phy_reset_sync : phy_reset_sync 
  generic map(
    CLK_STABLE       => CLK_STABLE,
    CLK_PERIOD       => CLK_PERIOD,
    RST_ACT_LOW      => RST_ACT_LOW,
    NUM_DEVICES      => NUM_DEVICES,
    SIM_INIT_OPTION  => SIM_INIT_OPTION,
    TCQ              => TCQ
    )
  port map( 
    sys_rst            => sys_rst,       
    clk                => clk,            
    rst_clk            => rst_clk_sig,        
    rst_wr_clk         => rst_wr_clk,    
    clk_rd             => clk_rd,  
    rst_clk_rd         => rst_clk_rd,  
    mmcm_locked        => mmcm_locked,     
    iodelay_ctrl_rdy   => iodelay_ctrl_rdy,
    mem_dll_off_n      => qdr_dll_off_n  
    );


end architecture arch;

