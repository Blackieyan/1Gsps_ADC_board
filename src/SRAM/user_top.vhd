-------------------------------------------------------------------------------
---- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
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
-- signalulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : $Name:  $
--  \   \         Application        : MIG
--  /   /         Filename           : user_top.v
-- /___/   /\     Timestamp          : Nov 18, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:34 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This entity
--  1. This is a wrapper which instantiates the PHY top Level which simplifies 
--     user interaction.  This wrapper supports both BL4 and BL2 designs.
--
--Revision History:
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity user_top is 
generic (
  ADDR_WIDTH         : integer := 19;          --Address Width
  DATA_WIDTH         : integer := 72;          --Data Width
  BW_WIDTH           : integer := 8;           --Byte Write Width
  BURST_LEN          : integer := 2;           --Burst Length
  CLK_PERIOD         : integer := 3752;        --Internal Fabric Clk Period (in ps)
  REFCLK_FREQ        : real    := 300.0;       --Ref. Clk Freq. for IODELAYs
  NUM_DEVICES        : integer := 2;           --Memory Devices
  FIXED_LATENCY_MODE : integer := 0;           --Use Fixed Latency Mode for read
  PHY_LATENCY        : integer := 0;           --Desired Latency
  CLK_STABLE         : integer := 2048;        --Cycles till CQ/CQ# is stable
  IODELAY_GRP        : string  := "IODELAY_MIG";--May be ed unique name 
                                                -- when mult IP cores in design
  MEM_TYPE           : string  := "QDR2PLUS";  --QDR Memory Type
  DEVICE_ARCH        : string  := "virtex6";   --Device Architecture
  RST_ACT_LOW        : integer := 1;           --System Reset is Active Low
  PHASE_DETECT       : string  := "OFF";       --Enable Phase detector
  SIM_CAL_OPTION     : string  := "NONE";      -- Skip various calibration steps
  SIM_INIT_OPTION    : string  := "NONE";      --Simulation only. "NONE", "SIM_MODE"
  IBUF_LPWR_MODE     : string  := "OFF";       -- Input buffer low power mode
  IODELAY_HP_MODE    : string  := "ON";        -- IODELAY High Performance Mode
  CQ_BITS            : integer := 1;           --clog2(NUM_DEVICES - 1)   
  Q_BITS             : integer := 7;           --clog2(DATA_WIDTH - 1)
  DEVICE_TAPS        : integer := 32;          -- Number of taps in the IDELAY chain
  TAP_BITS           : integer := 5;           -- clog2(DEVICE_TAPS - 1)   
  DEBUG_PORT         : string  := "ON";        -- Debug using Chipscope controls 
  TCQ                : integer := 100          --Register Delay
);
port (
  --System Signals
  clk               : in std_logic;                       --main system half freq clk
  rst_clk           : out std_logic;                      --reset sync to clk  
  sys_rst           : in std_logic;                       --unsync system clk reset
  clk_mem           : in std_logic;                       --full frequency clock
  clk_wr            : in std_logic;
  mmcm_locked       : in std_logic;                       --MMCM is locked
  iodelay_ctrl_rdy  : in std_logic;                       --IODELAY CTRL is ready

  --User Interface
  user_wr_cmd0      : in std_logic;                                         --wr command 0
  user_wr_cmd1      : in std_logic;                                         --wr command 1
  user_wr_addr0     : in std_logic_vector(ADDR_WIDTH-1 downto 0);           --wr address 0
  user_wr_addr1     : in std_logic_vector(ADDR_WIDTH-1 downto 0);           --wr address 1
  user_rd_cmd0      : in std_logic;                                         --rd command 0
  user_rd_cmd1      : in std_logic;                                         --rd command 1
  user_rd_addr0     : in std_logic_vector(ADDR_WIDTH-1 downto 0);           --rd address 0
  user_rd_addr1     : in std_logic_vector(ADDR_WIDTH-1 downto 0);           --rd address 1
  user_wr_data0     : in std_logic_vector(BURST_LEN*DATA_WIDTH-1 downto 0); --user write data 0
  user_wr_data1     : in std_logic_vector(2*DATA_WIDTH-1 downto 0);         --user write data 1
  user_wr_bw_n0     : in std_logic_vector(BURST_LEN*BW_WIDTH-1 downto 0);   --user byte writes 0
  user_wr_bw_n1     : in std_logic_vector(2*BW_WIDTH-1 downto 0);           --user byte writes 1

  user_cal_done     : out std_logic;
  user_rd_valid0    : out std_logic;                                        --Read valid for rd_data0
  user_rd_valid1    : out std_logic;                                        --Read valid for rd_data1
  user_rd_data0     : out std_logic_vector(BURST_LEN*DATA_WIDTH-1 downto 0);--Read data 0
  user_rd_data1     : out std_logic_vector(2*DATA_WIDTH-1 downto 0);        --Read data 1

  --Memory Interface
  qdr_dll_off_n     : out std_logic;                                        --QDR - turn off dll in mem
  qdr_k_p           : out std_logic_vector(NUM_DEVICES-1 downto 0);         --QDR clock K
  qdr_k_n           : out std_logic_vector(NUM_DEVICES-1 downto 0);         --QDR clock K#
  qdr_sa            : out std_logic_vector(ADDR_WIDTH-1 downto 0);          --QDR Memory Address
  qdr_w_n           : out std_logic;                                        --QDR Write 
  qdr_r_n           : out std_logic;                                        --QDR Read
  qdr_bw_n          : out std_logic_vector(BW_WIDTH-1 downto 0);            --QDR Byte Writes to Mem
  qdr_d             : out std_logic_vector(DATA_WIDTH-1 downto 0);          --QDR Data from Memory
  qdr_q             : in std_logic_vector(DATA_WIDTH-1 downto 0);           --QDR Data from Memory
  qdr_cq_p          : in std_logic_vector(NUM_DEVICES-1 downto 0);          --QDR echo clock CQ 
  qdr_cq_n          : in std_logic_vector(NUM_DEVICES-1 downto 0);          --QDR echo clock CQ# 

  --ChipScope Readpath Debug Signals
  dbg_phy_wr_cmd_n  : out std_logic_vector(1 downto 0);                     --cs debug - wr command
  dbg_phy_addr      : out std_logic_vector(ADDR_WIDTH*4-1 downto 0);        --cs debug - address
  dbg_phy_rd_cmd_n  : out std_logic_vector(1 downto 0);                     --cs debug - rd command
  dbg_phy_wr_data   : out std_logic_vector(DATA_WIDTH*4-1 downto 0);        --cs debug - wr data
  dbg_inc_cq_all    : in std_logic;                                         -- increment all CQs
  dbg_inc_cqn_all   : in std_logic;                                         -- increment all CQ#s
  dbg_inc_q_all     : in std_logic;                                         -- increment all Qs
  dbg_dec_cq_all    : in std_logic;                                         -- decrement all CQs   
  dbg_dec_cqn_all   : in std_logic;                                         -- decrement all CQ#s 
  dbg_dec_q_all     : in std_logic;                                         -- decrement all Qs   
  dbg_inc_cq        : in std_logic;                                         -- increment selected CQ  
  dbg_inc_cqn       : in std_logic;                                         -- increment selected CQ#
  dbg_inc_q         : in std_logic;                                         -- increment selected Q  
  dbg_dec_cq        : in std_logic;                                         -- decrement selected CQ  
  dbg_dec_cqn       : in std_logic;                                         -- decrement selected CQ# 
  dbg_dec_q         : in std_logic;                                         -- decrement selected Q   
  dbg_sel_cq        : in std_logic_vector(CQ_BITS-1 downto 0);              -- selected CQ bit
  dbg_sel_cqn       : in std_logic_vector(CQ_BITS-1 downto 0);              -- selected CQ# bit
  dbg_sel_q         : in std_logic_vector(Q_BITS-1 downto 0);               -- selected Q bit
  dbg_pd_off        : in std_logic;
  dbg_cq_tapcnt     : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);-- tap count for each cq
  dbg_cqn_tapcnt    : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);-- tap count for each cq#
  dbg_q_tapcnt      : out std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0); -- tap count for each q
  dbg_clk_rd        : out std_logic_vector(NUM_DEVICES-1 downto 0);         -- clk_rd in each domain
  dbg_rd_stage1_cal : out std_logic_vector(255 downto 0);                   -- stage 1 cal debug
  dbg_stage2_cal    : out std_logic_vector(127 downto 0);                   -- stage 2 cal debug
  dbg_cq_num        : out std_logic_vector(CQ_BITS-1 downto 0);             -- current cq/cq# being calibrated
  dbg_q_bit         : out std_logic_vector(Q_BITS-1 downto 0);              -- current q being calibrated 
  dbg_valid_lat     : out std_logic_vector(4 downto 0);                     -- latency of the system
  dbg_phase         : out std_logic_vector(NUM_DEVICES-1 downto 0);         -- data align phase indication
  dbg_inc_latency   : out std_logic_vector(NUM_DEVICES-1 downto 0);         -- increase latency for dcb
  dbg_dcb_wr_ptr    : out std_logic_vector(5*NUM_DEVICES-1 downto 0);       -- dcb write pointers
  dbg_dcb_rd_ptr    : out std_logic_vector(5*NUM_DEVICES-1 downto 0);       -- dcb read pointers
  dbg_dcb_din       : out std_logic_vector(4*DATA_WIDTH-1 downto 0);        -- dcb data in
  dbg_dcb_dout      : out std_logic_vector(4*DATA_WIDTH-1 downto 0);        -- dcb data out
  dbg_error_max_latency : out std_logic_vector(NUM_DEVICES-1 downto 0);     -- stage 2 cal max latency error
  dbg_error_adj_latency : out std_logic;                                    -- stage 2 cal latency adjustment error   
  dbg_pd_calib_start : out std_logic_vector(NUM_DEVICES-1 downto 0);        -- indicates phase detector to start
  dbg_pd_calib_done : out std_logic_vector(NUM_DEVICES-1 downto 0);         -- indicates phase detector is complete
  dbg_pd_calib_error   : out std_logic_vector(NUM_DEVICES-1 downto 0);
  dbg_phy_status    : out std_logic_vector(7 downto 0);                     -- phy status
  dbg_align_rd0     : out std_logic_vector(DATA_WIDTH-1 downto 0);
  dbg_align_rd1     : out std_logic_vector(DATA_WIDTH-1 downto 0);
  dbg_align_fd0     : out std_logic_vector(DATA_WIDTH-1 downto 0);
  dbg_align_fd1     : out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end user_top;

architecture arch of user_top is
  --Internal Wires
  signal mux_wr_cmd0   : std_logic;
  signal mux_wr_addr0  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal mux_wr_data0  : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal mux_wr_data1  : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal mux_wr_bw_n0  : std_logic_vector(BW_WIDTH*2-1 downto 0);
  signal mux_wr_bw_n1  : std_logic_vector(BW_WIDTH*2-1 downto 0);
  signal mux_rd_cmd1   : std_logic;
  signal mux_rd_addr1  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal rd_data0      : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal rd_data1      : std_logic_vector(DATA_WIDTH*2-1 downto 0);


  component qdr_phy_top
  generic( 
    ADDR_WIDTH          : integer; 
    DATA_WIDTH          : integer;     
    BW_WIDTH            : integer;     
    BURST_LEN           : integer;    
    CLK_PERIOD          : integer; 
    REFCLK_FREQ         : real;
    NUM_DEVICES         : integer;   
    FIXED_LATENCY_MODE  : integer;  
    PHY_LATENCY         : integer;
    CLK_STABLE          : integer;
    IODELAY_GRP         : string;
    MEM_TYPE            : string; 
    DEVICE_ARCH         : string; 
    RST_ACT_LOW         : integer; 
    PHASE_DETECT        : string;
    SIM_CAL_OPTION      : string;  
    IBUF_LPWR_MODE      : string; 
    IODELAY_HP_MODE     : string;
    CQ_BITS             : integer;
    Q_BITS              : integer;
    DEVICE_TAPS         : integer; 
    TAP_BITS            : integer; 
    DEBUG_PORT          : string; 
    TCQ                 : integer; 
    SIM_INIT_OPTION     : string
  );
  port ( 
    clk                   : in  std_logic;    
    rst_clk               : out std_logic;     
    sys_rst               : in  std_logic;    
    clk_mem               : in  std_logic;
    clk_wr                : in  std_logic;
    mmcm_locked           : in  std_logic;      
    iodelay_ctrl_rdy      : in  std_logic;      
    wr_cmd0               : in std_logic;       
    wr_cmd1               : in std_logic;        
    wr_addr0              : in std_logic_vector(ADDR_WIDTH-1 downto 0);  
    wr_addr1              : in std_logic_vector(ADDR_WIDTH-1 downto 0);       
    rd_cmd0               : in std_logic;         
    rd_cmd1               : in std_logic;          
    rd_addr0              : in std_logic_vector(ADDR_WIDTH-1 downto 0);       
    rd_addr1              : in std_logic_vector(ADDR_WIDTH-1 downto 0);       
    wr_data0              : in std_logic_vector(DATA_WIDTH*2-1 downto 0);     
    wr_data1              : in std_logic_vector(DATA_WIDTH*2-1 downto 0);     
    wr_bw_n0              : in std_logic_vector(BW_WIDTH*2-1 downto 0);       
    wr_bw_n1              : in std_logic_vector(BW_WIDTH*2-1 downto 0);       
    cal_done              : out std_logic;         
    rd_valid0             : out std_logic;        
    rd_valid1             : out std_logic;       
    rd_data0              : out std_logic_vector(DATA_WIDTH*2-1 downto 0);   
    rd_data1              : out std_logic_vector(DATA_WIDTH*2-1 downto 0);   
    qdr_dll_off_n         : out std_logic;         
    qdr_k_p               : out std_logic_vector(NUM_DEVICES-1 downto 0);    
    qdr_k_n               : out std_logic_vector(NUM_DEVICES-1 downto 0);    
    qdr_sa                : out std_logic_vector(ADDR_WIDTH-1 downto 0);     
    qdr_w_n               : out std_logic;        
    qdr_r_n               : out std_logic;       
    qdr_bw_n              : out std_logic_vector(BW_WIDTH-1 downto 0);       
    qdr_d                 : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    qdr_q                 : in  std_logic_vector(DATA_WIDTH-1 downto 0);     
    qdr_cq_p              : in std_logic_vector(NUM_DEVICES-1 downto 0);    
    qdr_cq_n              : in std_logic_vector(NUM_DEVICES-1 downto 0);    
    dbg_phy_wr_cmd_n      : out std_logic_vector(1 downto 0);                
    dbg_phy_addr          : out std_logic_vector(ADDR_WIDTH*4-1 downto 0);   
    dbg_phy_rd_cmd_n      : out std_logic_vector(1 downto 0);                
    dbg_phy_wr_data       : out std_logic_vector(DATA_WIDTH*4-1 downto 0);   
    dbg_inc_cq_all        : in std_logic;    
    dbg_inc_cqn_all       : in std_logic;     
    dbg_inc_q_all         : in std_logic;      
    dbg_dec_cq_all        : in std_logic;       
    dbg_dec_cqn_all       : in std_logic;        
    dbg_dec_q_all         : in std_logic;         
    dbg_inc_cq            : in std_logic;          
    dbg_inc_cqn           : in std_logic;           
    dbg_inc_q             : in std_logic;        
    dbg_dec_cq            : in std_logic;         
    dbg_dec_cqn           : in std_logic;          
    dbg_dec_q             : in std_logic;           
    dbg_sel_cq            : in std_logic_vector(CQ_BITS-1 downto 0);  
    dbg_sel_cqn           : in std_logic_vector(CQ_BITS-1 downto 0);  
    dbg_sel_q             : in std_logic_vector(Q_BITS-1 downto 0); 
    dbg_pd_off            : in std_logic;  
    dbg_rd_stage1_cal     : out std_logic_vector(255 downto 0);                      
    dbg_cq_tapcnt         : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);  
    dbg_cqn_tapcnt        : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);  
    dbg_q_tapcnt          : out std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0);   
    dbg_clk_rd            : out std_logic_vector(NUM_DEVICES-1 downto 0);
    dbg_stage2_cal        : out std_logic_vector(127 downto 0);             
    dbg_cq_num            : out std_logic_vector(CQ_BITS-1 downto 0);       
    dbg_q_bit             : out std_logic_vector(Q_BITS-1 downto 0);        
    dbg_valid_lat         : out std_logic_vector(4 downto 0);               
    dbg_phase             : out std_logic_vector(NUM_DEVICES-1 downto 0);   
    dbg_inc_latency       : out std_logic_vector(NUM_DEVICES-1 downto 0);   
    dbg_dcb_wr_ptr        : out std_logic_vector(5*NUM_DEVICES-1 downto 0); 
    dbg_dcb_rd_ptr        : out std_logic_vector(5*NUM_DEVICES-1 downto 0); 
    dbg_dcb_din           : out std_logic_vector(4*DATA_WIDTH-1 downto 0);  
    dbg_dcb_dout          : out std_logic_vector(4*DATA_WIDTH-1 downto 0);  
    dbg_error_max_latency : out std_logic_vector(NUM_DEVICES-1 downto 0);  
    dbg_error_adj_latency : out std_logic;                                 
    dbg_pd_calib_start    : out std_logic_vector(NUM_DEVICES-1 downto 0);  
    dbg_pd_calib_done     : out std_logic_vector(NUM_DEVICES-1 downto 0);  
    dbg_pd_calib_error   : out std_logic_vector(NUM_DEVICES-1 downto 0);
    dbg_phy_status        : out std_logic_vector(7 downto 0);
    dbg_align_rd0         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dbg_align_rd1         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dbg_align_fd0         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dbg_align_fd1         : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
  end component;

begin

  mux_data_bl4 :
  if (BURST_LEN = 4) generate 
    begin
       mux_wr_data0 <= user_wr_data0(DATA_WIDTH*4-1 downto DATA_WIDTH*2);
       mux_wr_bw_n0 <= user_wr_bw_n0(BW_WIDTH*4-1 downto BW_WIDTH*2);
    end
  generate;

  mux_data_bl2 :
  if (BURST_LEN = 2) generate 
    begin
       mux_wr_data0 <= user_wr_data0;
       mux_wr_bw_n0 <= user_wr_bw_n0;
    end
  generate;

  mux_wr_data1  <= user_wr_data0(DATA_WIDTH*2-1 downto 0) when (BURST_LEN = 4) else user_wr_data1;
  mux_wr_bw_n1  <= user_wr_bw_n0(BW_WIDTH*2-1 downto 0) when (BURST_LEN = 4) else user_wr_bw_n1;
  user_rd_data0 <= (rd_data0 & rd_data1) when (BURST_LEN = 4) else rd_data0;
  user_rd_data1 <= rd_data1;
  
  --Instantiate the Top of the PHY
  u_qdr_phy_top : qdr_phy_top 
  generic map(
    ADDR_WIDTH         => ADDR_WIDTH,
    DATA_WIDTH         => DATA_WIDTH,
    BW_WIDTH           => BW_WIDTH,
    BURST_LEN          => BURST_LEN,
    CLK_PERIOD         => CLK_PERIOD,
    REFCLK_FREQ        => REFCLK_FREQ,
    NUM_DEVICES        => NUM_DEVICES,
    FIXED_LATENCY_MODE => FIXED_LATENCY_MODE,
    PHY_LATENCY        => PHY_LATENCY,
    CLK_STABLE         => CLK_STABLE,
    IODELAY_GRP        => IODELAY_GRP,
    MEM_TYPE           => MEM_TYPE,
    DEVICE_ARCH        => DEVICE_ARCH,
    SIM_CAL_OPTION     => SIM_CAL_OPTION,
    SIM_INIT_OPTION    => SIM_INIT_OPTION,
    PHASE_DETECT       => PHASE_DETECT,
    RST_ACT_LOW        => RST_ACT_LOW,
    IBUF_LPWR_MODE     => IBUF_LPWR_MODE,
    IODELAY_HP_MODE    => IODELAY_HP_MODE,
    CQ_BITS            => CQ_BITS,
    Q_BITS             => Q_BITS,
    TAP_BITS           => TAP_BITS,
    DEVICE_TAPS        => DEVICE_TAPS,
    DEBUG_PORT         => DEBUG_PORT,
    TCQ                => TCQ
  ) 
  port map (
    clk                    => clk, 
    rst_clk                => rst_clk,
    sys_rst                => sys_rst,          
    clk_mem                => clk_mem,
    clk_wr                 => clk_wr,
    mmcm_locked            => mmcm_locked,
    iodelay_ctrl_rdy       => iodelay_ctrl_rdy,
    wr_cmd0                => user_wr_cmd0, 
    wr_cmd1                => user_wr_cmd1,          
    wr_addr0               => user_wr_addr0, 
    wr_addr1               => user_wr_addr1,    
    rd_cmd0                => user_rd_cmd0,          
    rd_cmd1                => user_rd_cmd1,         
    rd_addr0               => user_rd_addr0,        
    rd_addr1               => user_rd_addr1,  
    wr_data0               => mux_wr_data0,        
    wr_data1               => mux_wr_data1,        
    wr_bw_n0               => mux_wr_bw_n0,        
    wr_bw_n1               => mux_wr_bw_n1,        
    cal_done               => user_cal_done,
    rd_valid0              => user_rd_valid0,       
    rd_valid1              => user_rd_valid1,        
    rd_data0               => rd_data0,       
    rd_data1               => rd_data1,       
    qdr_k_p                => qdr_k_p,        
    qdr_k_n                => qdr_k_n,        
    qdr_sa                 => qdr_sa,         
    qdr_w_n                => qdr_w_n,         
    qdr_r_n                => qdr_r_n,        
    qdr_bw_n               => qdr_bw_n,       
    qdr_d                  => qdr_d,          
    qdr_q                  => qdr_q,          
    qdr_cq_p               => qdr_cq_p,        
    qdr_cq_n               => qdr_cq_n,   
    qdr_dll_off_n          => qdr_dll_off_n,
    dbg_phy_wr_cmd_n       => dbg_phy_wr_cmd_n, 
    dbg_phy_addr           => dbg_phy_addr,    
    dbg_phy_rd_cmd_n       => dbg_phy_rd_cmd_n, 
    dbg_phy_wr_data        => dbg_phy_wr_data,
    dbg_inc_cq_all         => dbg_inc_cq_all,    
    dbg_inc_cqn_all        => dbg_inc_cqn_all,   
    dbg_inc_q_all          => dbg_inc_q_all,     
    dbg_dec_cq_all         => dbg_dec_cq_all,    
    dbg_dec_cqn_all        => dbg_dec_cqn_all,   
    dbg_dec_q_all          => dbg_dec_q_all,     
    dbg_inc_cq             => dbg_inc_cq,        
    dbg_inc_cqn            => dbg_inc_cqn,       
    dbg_inc_q              => dbg_inc_q,         
    dbg_dec_cq             => dbg_dec_cq,        
    dbg_dec_cqn            => dbg_dec_cqn,       
    dbg_dec_q              => dbg_dec_q,         
    dbg_sel_cq             => dbg_sel_cq,        
    dbg_sel_cqn            => dbg_sel_cqn,       
    dbg_sel_q              => dbg_sel_q,
    dbg_pd_off             => dbg_pd_off,
    dbg_cq_tapcnt          => dbg_cq_tapcnt, 
    dbg_cqn_tapcnt         => dbg_cqn_tapcnt,
    dbg_q_tapcnt           => dbg_q_tapcnt,  
    dbg_clk_rd             => dbg_clk_rd,
    dbg_rd_stage1_cal      => dbg_rd_stage1_cal,
    dbg_stage2_cal         => dbg_stage2_cal,
    dbg_cq_num             => dbg_cq_num,
    dbg_q_bit              => dbg_q_bit,
    dbg_valid_lat          => dbg_valid_lat,
    dbg_phase              => dbg_phase,
    dbg_inc_latency        => dbg_inc_latency,
    dbg_dcb_wr_ptr         => dbg_dcb_wr_ptr,
    dbg_dcb_rd_ptr         => dbg_dcb_rd_ptr,
    dbg_dcb_din            => dbg_dcb_din,
    dbg_dcb_dout           => dbg_dcb_dout,
    dbg_error_max_latency  => dbg_error_max_latency,
    dbg_error_adj_latency  => dbg_error_adj_latency,
    dbg_pd_calib_start     => dbg_pd_calib_start,
    dbg_pd_calib_done      => dbg_pd_calib_done,
    dbg_pd_calib_error     => dbg_pd_calib_error,
    dbg_phy_status         => dbg_phy_status,
    dbg_align_rd0          => dbg_align_rd0,
    dbg_align_rd1          => dbg_align_rd1,
    dbg_align_fd0          => dbg_align_fd0,
    dbg_align_fd1          => dbg_align_fd1
  );

end architecture arch;
