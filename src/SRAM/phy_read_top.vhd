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

--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : $Name:  $
--  \   \         Application        : MIG
--  /   /         Filename           : phy_read_top.v
-- /___/   /\     Timestamp          : Nov 17, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--  This module
--  1. Instantiates all the read path submodules
--
--Revision History:
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity phy_read_top is
generic(
  BURST_LEN           : integer := 4;            -- 4 : intger : Burst Length 4
                                                 -- , 2 : intger : Burst Length 2
  DATA_WIDTH          : integer := 72;           -- Total data width across all 
                                                 -- memories
  NUM_DEVICES         : integer := 2;            -- Number of memory devices
  FIXED_LATENCY_MODE  : integer := 0;            -- 0 : intger : minimum latency mode
                                                 -- , 1 : intger : fixed latency mode
  PHY_LATENCY         : integer := 16;           -- Indicates the desired latency 
                                                 -- for fixed latency mode
  CLK_PERIOD          : integer := 1876;         -- Indicates the number of 
                                                 -- picoseconds for one CLK period
  REFCLK_FREQ         : real := 300.0;           -- Indicates the IDELAYCTRL 
                                                 -- reference clock frequency
  DEVICE_TAPS         : integer := 32;           -- Number of taps in target IODELAY
  TAP_BITS            : integer := 5;            -- Number of bits needed to 
                                                 -- represent DEVICE_TAPS
  MEMORY_WIDTH        : integer := 36;           -- Width of each memory
  PHASE_DETECT        : string := "OFF";         -- Enable Phase detector
  IODELAY_GRP         : string := "IODELAY_MIG"; -- May be assigned unique name 
                                                 -- when mult IP cores in design
  SIM_CAL_OPTION      : string := "NONE";        -- Skip various calibration steps 
                                                 -- - "NONE, "FAST_CAL", "SKIP_CAL"
  SIM_INIT_OPTION     : string := "NONE";        -- Simulation only. "NONE", "SIM_MODE"
  MEM_TYPE            : string := "QDR2PLUS";    -- Memory Type (QDR2PLUS, QDR2)
  CQ_BITS             : integer := 1;            -- clog2(NUM_DEVICES - 1)   
  Q_BITS              : integer := 7;            -- clog2(DATA_WIDTH - 1)  
  DEBUG_PORT          : string := "ON";          -- Debug using Chipscope controls 
  TCQ                 : integer:= 100            -- Register delay
  );
port(
  -- System Signals
  clk         : in std_logic;                                -- main system half 
                                                             -- freq clk
  clk_rd      : in std_logic_vector(NUM_DEVICES-1 downto 0); -- half freq CQ clock
  rst_clk     : in std_logic;                                -- main read path 
                                                             -- reset sync to clk
  rst_clk_rd  : in std_logic_vector(NUM_DEVICES-1 downto 0); -- reset syncrhonized 
                                                             -- to clk_rd

  -- I/O Interface
  -- CQ IDELAY clock enable
  cq_dly_ce     : out std_logic_vector(NUM_DEVICES-1 downto 0);
  -- CQ IDELAY increment
  cq_dly_inc    : out std_logic_vector(NUM_DEVICES-1 downto 0);
  -- CQ IDELAY reset
  cq_dly_rst    : out std_logic_vector(NUM_DEVICES-1 downto 0);
  -- CQ IDELAY cntvaluein load value
  cq_dly_load   : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  -- CQ# IDELAY clock enable
  cqn_dly_ce    : out std_logic_vector(NUM_DEVICES-1 downto 0);
  -- CQ# IDELAY increment
  cqn_dly_inc   : out std_logic_vector(NUM_DEVICES-1 downto 0);
  -- CQ# IDELAY reset
  cqn_dly_rst   : out std_logic_vector(NUM_DEVICES-1 downto 0);
  -- CQ# IDELAY cntvaluein load value
  cqn_dly_load  : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  -- Q IDELAY clock enable
  q_dly_ce      : out std_logic_vector(DATA_WIDTH-1 downto 0);
  -- Q IDELAY increment
  q_dly_inc     : out std_logic_vector(NUM_DEVICES-1 downto 0);
  -- Q IDELAY reset
  q_dly_rst     : out std_logic_vector(DATA_WIDTH-1 downto 0);
  -- Q IDELAY cntvaluein load value
  q_dly_load    : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  -- Q IDELAY CLK inversion
  q_dly_clkinv  : out std_logic_vector(NUM_DEVICES-1 downto 0);
  -- ISERDES RST
  iserdes_rst   : out std_logic_vector(NUM_DEVICES-1 downto 0);
  -- ISERDES Q4 output - rise data 0
  iserdes_rd0   : in std_logic_vector(DATA_WIDTH-1 downto 0);
  -- ISERDES Q3 output - fall data 0
  iserdes_fd0   : in std_logic_vector(DATA_WIDTH-1 downto 0);
  -- ISERDES Q2 output - rise data 1
  iserdes_rd1   : in std_logic_vector(DATA_WIDTH-1 downto 0);
  -- ISERDES Q1 output - fall data 1
  iserdes_fd1   : in std_logic_vector(DATA_WIDTH-1 downto 0);

  -- User Interface
  cal_done  : out std_logic;                                 -- calibration done
  rd_data0  : out std_logic_vector(DATA_WIDTH*2-1 downto 0); -- user read data 0
  rd_data1  : out std_logic_vector(DATA_WIDTH*2-1 downto 0); -- user read data 1
  rd_valid0 : out std_logic;                          -- user read data 0 valid
  rd_valid1 : out std_logic;                          -- user read data 1 valid

  -- Write Path Interface
  init_done         : in std_logic;                    -- initialization complete
  cal_stage1_start  : out std_logic;                   -- stage 1 calibration start
  cal_stage2_start  : out std_logic;                   -- stage 2 calibration start
  int_rd_cmd_n      : in std_logic_vector(1 downto 0); -- internal rd cmd

  -- Phase Detector Interface
  clk_cq      : in std_logic_vector(NUM_DEVICES-1 downto 0); -- CQ BUFIO clock
  clk_cqn     : in std_logic_vector(NUM_DEVICES-1 downto 0); -- CQ# BUFIO clock
  pd_source   : in std_logic_vector(NUM_DEVICES-1 downto 0); 
  clk_mem     : in std_logic;                          -- Full frequency clock
  clk_wr      : in std_logic;
  rst_wr_clk  : in std_logic;                          -- Reset write path reset

  --ChipScope Debug Signals
  dbg_inc_cq_all    : in std_logic;                    -- increment all CQs
  dbg_inc_cqn_all   : in std_logic;                    -- increment all CQ#s
  dbg_inc_q_all     : in std_logic;                    -- increment all Qs
  dbg_dec_cq_all    : in std_logic;                    -- decrement all CQs   
  dbg_dec_cqn_all   : in std_logic;                    -- decrement all CQ#s 
  dbg_dec_q_all     : in std_logic;                    -- decrement all Qs   
  dbg_inc_cq        : in std_logic;                    -- increment selected CQ  
  dbg_inc_cqn       : in std_logic;                    -- increment selected CQ#
  dbg_inc_q         : in std_logic;                    -- increment selected Q  
  dbg_dec_cq        : in std_logic;                    -- decrement selected CQ  
  dbg_dec_cqn       : in std_logic;                    -- decrement selected CQ# 
  dbg_dec_q         : in std_logic;                    -- decrement selected Q   
  dbg_sel_cq        : in std_logic_vector(CQ_BITS-1 downto 0); -- selected CQ bit
  dbg_sel_cqn       : in std_logic_vector(CQ_BITS-1 downto 0); -- selected CQ# bit
  dbg_sel_q         : in std_logic_vector(Q_BITS-1 downto 0);  -- selected Q bit
  dbg_pd_off        : in std_logic;
  dbg_rd_stage1_cal : out std_logic_vector(255 downto 0);
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
  -- indicates phase detector is complete
  dbg_pd_calib_done    : out std_logic_vector(NUM_DEVICES-1 downto 0); 
  dbg_pd_calib_error   : out std_logic_vector(NUM_DEVICES-1 downto 0); 
  dbg_align_rd0        : out std_logic_vector(DATA_WIDTH-1 downto 0);
  dbg_align_fd0        : out std_logic_vector(DATA_WIDTH-1 downto 0);
  dbg_align_rd1        : out std_logic_vector(DATA_WIDTH-1 downto 0);
  dbg_align_fd1        : out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end entity phy_read_top;

architecture arch of phy_read_top is
  -- External memory frequence is 2x internal
  constant MEM_PERIOD       : integer := CLK_PERIOD/2; 
  
  -- Constants
  -- IDELAY tap resolution in ps
  constant IODELAY_TAP_RES  : integer := 1000000 / (integer(REFCLK_FREQ) * 64);
  
  -- Functions for use in constant declaration
  function center_tap_func return integer is
  begin
    if (((MEM_PERIOD / 4) / IODELAY_TAP_RES) > 31) then
      return 31;
    else
      return ((MEM_PERIOD / 4) / IODELAY_TAP_RES);
    end if;
  end function center_tap_func;
  
  -- Functions for use in constant declaration
  function taps_reserved_func return integer is
  begin
    if (PHASE_DETECT = "ON") then
      return 3;
    else
      return 0;
    end if;
  end function taps_reserved_func;
  
  -- Constants that use functions
  -- Number of taps to "ideal" center; limit to 31
  constant CENTER_TAP       : integer := center_tap_func;
  
  -- Number of taps to reserve for RTC
  constant TAPS_RESERVED    : integer := taps_reserved_func;  
  
  -- minimum usuable clock tap setting
  constant MIN_TAPS         : integer := TAPS_RESERVED;
  -- maximum usable clock tap setting
  constant MAX_TAPS         : integer := DEVICE_TAPS - TAPS_RESERVED - 1;
  
  
  -- Signals
  signal dcb_rd0              : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dcb_fd0              : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dcb_rd1              : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dcb_fd1              : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal phase_clk            : std_logic_vector(NUM_DEVICES-1 downto 0); 
  signal cq_num_active_clk    : std_logic_vector(CQ_BITS-1 downto 0);
  signal q_bit_active_clk     : std_logic_vector(Q_BITS-1 downto 0);
  signal cq_num_load_clk      : std_logic_vector(TAP_BITS-1 downto 0);
  signal cqn_num_load_clk     : std_logic_vector(TAP_BITS-1 downto 0);
  signal q_bit_load_clk       : std_logic_vector(TAP_BITS-1 downto 0);
  signal cq_num_rst_clk       : std_logic;
  signal cq_num_ce_clk        : std_logic;
  signal cq_num_inc_clk       : std_logic;
  signal cqn_num_rst_clk      : std_logic;
  signal cqn_num_ce_clk       : std_logic;
  signal cqn_num_inc_clk      : std_logic;
  signal q_bit_rst_clk        : std_logic;
  signal q_bit_ce_clk         : std_logic;
  signal q_bit_inc_clk        : std_logic;
  signal q_bit_clkinv_clk     : std_logic;
  signal error_align          : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal read_data            : std_logic_vector(4*DATA_WIDTH-1 downto 0);
  signal inc_latency          : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal valid_latency        : std_logic_vector(4 downto 0);
  signal error_max_latency    : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal error_adj_latency    : std_logic;
  signal align_rd0            : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal align_fd0            : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal align_rd1            : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal align_fd1            : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal phase                : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal cq_num_active        : std_logic_vector(CQ_BITS*NUM_DEVICES-1 downto 0);
  signal q_bit_active         : std_logic_vector(Q_BITS*NUM_DEVICES-1 downto 0);
  signal cq_num_load          : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal cqn_num_load         : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal q_bit_load           : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal cq_num_rst           : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal cq_num_ce            : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal cq_num_inc           : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal cqn_num_rst          : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal cqn_num_ce           : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal cqn_num_inc          : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal q_bit_rst            : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal q_bit_ce             : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal q_bit_inc            : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal q_bit_clkinv         : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal pd_calib_done_clk    : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal cal_stage2_done_clk  : std_logic;
  signal cal_stage2_done      : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal pd_en_maintain       : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal pd_calib_done        : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal pd_incdec_maintain   : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal pd_calib_error       : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal rd_data0_int         : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal rd_data1_int         : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal cal_done_int         : std_logic;
  signal cal_stage2_start_int : std_logic;
  signal cal_stage1_done      : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal cq_dly_rst_sig       : std_logic_vector(NUM_DEVICES-1 downto 0);

  signal dbg_sel_q_clkrd        : std_logic_vector(Q_BITS*NUM_DEVICES-1 downto 0);
  signal dbg_sel_cq_clkrd       : std_logic_vector(CQ_BITS*NUM_DEVICES-1 downto 0);
  signal dbg_sel_cqn_clkrd      : std_logic_vector(CQ_BITS*NUM_DEVICES-1 downto 0); 
  signal dbg_inc_q_clkrd        : std_logic_vector(NUM_DEVICES-1 downto 0);   
  signal dbg_dec_q_clkrd        : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_inc_cq_clkrd       : std_logic_vector(NUM_DEVICES-1 downto 0);    
  signal dbg_dec_cq_clkrd       : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_inc_cqn_clkrd      : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_dec_cqn_clkrd      : std_logic_vector(NUM_DEVICES-1 downto 0);  
  signal dbg_inc_q_all_clkrd    : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_dec_q_all_clkrd    : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_inc_cq_all_clkrd   : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_dec_cq_all_clkrd   : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_inc_cqn_all_clkrd  : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal dbg_dec_cqn_all_clkrd  : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal rst_delayed          : std_logic_vector(3 downto 0) := (others => '0');
  signal wc                   : std_logic;
  
  -- Component declarations
  component phy_read_stage1_cal is
   generic (
      DATA_WIDTH             : integer := 72;		-- Total data width across all memories
      NUM_DEVICES            : integer := 2;		   -- Number of memory devices
      MEMORY_WIDTH           : integer := 36;		-- Width of each memory
      DEVICE_TAPS            : integer := 32;		-- Number of taps in target IDELAY
      TAP_BITS               : integer := 5;		   -- Number of bits needed to represent DEVICE_TAPS
      IODELAY_TAP_RES        : integer := 52;		-- IODELAY tap resolution in ps
      CENTER_TAP             : integer := 9;		   -- Number of taps to "ideal" center
      MIN_TAPS               : integer := 5;		   -- minimum usuable clock tap setting
      MAX_TAPS               : integer := 5;		   -- maximum usuable clock tap setting
      CQ_BITS                : integer := 1;		   -- Number of bits needed to represent number of cq/cq#'s
      Q_BITS                 : integer := 7;		   -- Number of bits needed to represent number of q's
      MEM_TYPE               : string  := "QDR2PLUS";	-- Memory Type (QDR2PLUS, QDR2)
      SIM_CAL_OPTION         : string  := "NONE";	-- Skip various calibration steps - "NONE, "FAST_CAL", "SKIP_CAL"
      TCQ                    : integer := 100 	   -- Register delay
   );
   port (
      -- System Signals
      clk                    : in std_logic;       -- main system half freq clk
      rst_clk                : in std_logic;       -- reset syncrhonized to clk
      
      -- Write Interface
      init_done              : in std_logic;       -- indicates initialization is done
      cal_stage1_start       : out std_logic;      -- indicates cal stage 1 to begin
      cal_stage2_start       : out std_logic;      -- indicates cal stage 2 to begin
      
      -- DCB Interface
      rise_data0             : in std_logic_vector(DATA_WIDTH - 1 downto 0);
      fall_data0             : in std_logic_vector(DATA_WIDTH - 1 downto 0);
      rise_data1             : in std_logic_vector(DATA_WIDTH - 1 downto 0);
      fall_data1             : in std_logic_vector(DATA_WIDTH - 1 downto 0);
      
      -- IODELAY Control Interface
      phase                  : out std_logic_vector(NUM_DEVICES - 1 downto 0);-- indicates which CQ/CQ# the control is for
      cq_num                 : out std_logic_vector(CQ_BITS-1 downto 0);    -- indictes which Q the control is for
      q_bit                  : out std_logic_vector(Q_BITS - 1 downto 0);     -- indictes which Q the control is for
      cq_num_load            : out std_logic_vector(TAP_BITS - 1 downto 0);   -- iodelay load value for CQ#
      cqn_num_load           : out std_logic_vector(TAP_BITS - 1 downto 0);   -- iodelay load value for Q
      q_bit_load             : out std_logic_vector(TAP_BITS - 1 downto 0);   -- iodelay load value for Q
      cq_num_rst             : out std_logic;                                 -- iodelay rst control for CQ
      cq_num_ce              : out std_logic;                                 -- iodelay ce control for CQ
      cq_num_inc             : out std_logic;                                    -- iodelay inc control for CQ
      cqn_num_rst            : out std_logic;                                 -- iodelay rst control for CQ#
      cqn_num_ce             : out std_logic;                                 -- iodelay ce control for CQ#
      cqn_num_inc            : out std_logic;                                 -- iodelay inc control for CQ#
      q_bit_rst              : out std_logic;                                 -- iodelay rst for each Q
      q_bit_ce               : out std_logic;                                 -- iodelay ce for each Q
      q_bit_inc              : out std_logic;                                 -- iodelay inc for all Q
      
      -- Chipscope/Debug and Error
      q_bit_clkinv           : out std_logic;                                 -- invert clk/clkb inputs of iserdes
      error_align            : out std_logic_vector(NUM_DEVICES - 1 downto 0);
      dbg_rd_stage1_cal      : out std_logic_vector(255 downto 0)
   );
end component;
  
  component phy_read_stage2_cal is
   generic (
      BURST_LEN           : integer := 4;		  -- Burst Length
      DATA_WIDTH          : integer := 72;		-- Total data width across all memories
      NUM_DEVICES         : integer := 2;		  -- Number of memory devices
      MEMORY_WIDTH        : integer := 36;		-- Width of each memory
      FIXED_LATENCY_MODE  : integer := 0;		  -- 0 = minimum latency mode, 1 = fixed latency mode
      PHY_LATENCY         : integer := 16;		-- Indicates the desired latency for fixed latency mode
      TCQ                 : integer := 100		-- Register delay
   );
   port (
      -- System Signals
      clk                 : in std_logic;		-- main system half freq clk
      rst_clk             : in std_logic;		-- reset syncrhonized to clk
      
      -- Stage 1 Calibration Interface
      cal_stage2_start    : in std_logic;		-- indicates latency calibration can begin
      
      -- Write Interface
      int_rd_cmd_n        : in std_logic_vector(1 downto 0);		-- read command(s) - only bit 0 is used for BL4
      
      -- DCB Interface
      read_data           : in std_logic_vector(DATA_WIDTH * 4 - 1 downto 0);		-- read data from DCB
      inc_latency         : out std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates latency through a DCB to be increased
      
      -- Valid Generator Interface
      valid_latency       : out std_logic_vector(4 downto 0);		-- amount to delay read command
      
      -- User Interface
      cal_done            : out std_logic;		-- indicates overall calibration is complete
      
      -- Phase Detector
      pd_calib_done       : in std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates phase detector calibration is complete
      cal_stage2_done     : out std_logic;		-- indicates stage 2 calibration is complete
      
      -- Chipscope/Debug and Error
      error_max_latency   : out std_logic_vector(NUM_DEVICES - 1 downto 0);		-- mem_latency counter has maxed out
      error_adj_latency   : out std_logic;		-- target PHY_LATENCY is invalid
      -- general debug port
      dbg_stage2_cal      : out std_logic_vector(127 downto 0)
   );
end component;
  
  component phy_read_vld_gen
  generic(
    BURST_LEN       : integer  := 4;    
    TCQ             : integer  := 100
  );
  port(
    clk           : in std_logic;
    rst_clk       : in std_logic;
    int_rd_cmd_n  : in std_logic_vector(1 downto 0);
    valid_latency : in std_logic_vector(4 downto 0);
    cal_done      : in std_logic;
    data_valid0   : out std_logic;
    data_valid1   : out std_logic;
    dbg_valid_lat : out std_logic_vector(4 downto 0)
    );
  end component;
  
  component phy_read_data_align
  generic(
    MEMORY_WIDTH    : integer   := 36;
    TCQ             : integer   := 100
  );
  port(
    clk_rd      : in std_logic;
    rst_clk_rd  : in std_logic;
    iserdes_rd0 : in std_logic_vector(MEMORY_WIDTH-1 downto 0);
    iserdes_fd0 : in std_logic_vector(MEMORY_WIDTH-1 downto 0);
    iserdes_rd1 : in std_logic_vector(MEMORY_WIDTH-1 downto 0);
    iserdes_fd1 : in std_logic_vector(MEMORY_WIDTH-1 downto 0);
    phase       : in std_logic;
    rise_data0  : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
    fall_data0  : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
    rise_data1  : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
    fall_data1  : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
    dbg_phase   : out std_logic
    );
  end component;
  
  component phy_read_dcb is
  generic(
    MEMORY_WIDTH  : integer := 36;    -- Width of each memory
    TCQ           : integer := 100    -- Register delay
  );
  port(
    -- System Signal
    clk_rd      : in std_logic;   -- half freq CQ clock - write side
    rst_clk_rd  : in std_logic;   -- reset syncrhonized to clk_rd - write side
    clk         : in std_logic;   -- main system half freq clk - read side
    rst_clk     : in std_logic;   -- main read path reset sync to clk - read side
    cq_dly_rst  : in std_logic;   -- CQ IODELAY rest indication    
    -- Data ALign Interface
    din_rd0 : in std_logic_vector(MEMORY_WIDTH-1 downto 0); -- rise data 0 from 
                                                            -- data align
    din_fd0 : in std_logic_vector(MEMORY_WIDTH-1 downto 0); -- fall data 0 from 
                                                            -- data align
    din_rd1 : in std_logic_vector(MEMORY_WIDTH-1 downto 0); -- rise data 1 from 
                                                            -- data align
    din_fd1 : in std_logic_vector(MEMORY_WIDTH-1 downto 0); -- fall data 1 from 
                                                            -- data align    
    -- User Interface
    dout_rd0 : out std_logic_vector(MEMORY_WIDTH-1 downto 0); -- rise data 0 from DCB
    dout_fd0 : out std_logic_vector(MEMORY_WIDTH-1 downto 0); -- fall data 0 from DCB
    dout_rd1 : out std_logic_vector(MEMORY_WIDTH-1 downto 0); -- rise data 1 from DCB
    dout_fd1 : out std_logic_vector(MEMORY_WIDTH-1 downto 0); -- fall data 1 from DCB    
    -- Latency Calibration Interface
    inc_latency : in std_logic; -- increase latency when asserted    
    -- ChipScope Debug Signals
    dbg_dcb_wr_ptr  : out std_logic_vector(4 downto 0);
    dbg_dcb_rd_ptr  : out std_logic_vector(4 downto 0);
    dbg_dcb_din     : out std_logic_vector(MEMORY_WIDTH*4-1 downto 0);
    dbg_dcb_dout    : out std_logic_vector(MEMORY_WIDTH*4-1 downto 0)
  );
  end component;
  
  component phy_read_sync is
 generic(
   TAP_BITS : integer     := 5;     -- Number of bits needed to represent DEVICE_TAPS
   CQ_BITS : integer      := 1;     -- Number of bits needed to represent number 
                                    -- of cq/cq#'s
   Q_BITS : integer       := 7;     -- Number of bits needed to represent number 
                                    --of q's
   DEVICE_ID : integer    := 0;     -- Indicates memory device instance
   DEBUG_PORT : string    := "ON";  -- Debug using Chipscope controls
   TCQ        : integer   := 100    -- Register delay
  );
 port(
  -- clk Interface
  clk                 : in std_logic;         -- main system half freq clk
  rst_clk             : in std_logic;         -- reset syncrhonized to clk
  -- indicates which CQ/CQ# the control is for
  cq_num_active_clk   : in std_logic_vector(CQ_BITS-1 downto 0);
  -- indictes which Q the control is for
  q_bit_active_clk    : in std_logic_vector(Q_BITS-1 downto 0);
  -- iodelay load value for CQ
  cq_num_load_clk     : in std_logic_vector(TAP_BITS-1 downto 0);
  -- iodelay load value for CQ#
  cqn_num_load_clk    : in std_logic_vector(TAP_BITS-1 downto 0);
  -- iodelay load value for Q
  q_bit_load_clk      : in std_logic_vector(TAP_BITS-1 downto 0);
  cq_num_rst_clk      : in std_logic;         -- iodelay rst control for CQ
  cq_num_ce_clk       : in std_logic;         -- iodelay ce control for CQ
  cq_num_inc_clk      : in std_logic;         -- iodelay inc control for CQ
  cqn_num_rst_clk     : in std_logic;         -- iodelay rst control for CQ#
  cqn_num_ce_clk      : in std_logic;         -- iodelay ce control for CQ#
  cqn_num_inc_clk     : in std_logic;         -- iodelay inc control for CQ#
  q_bit_rst_clk       : in std_logic;         -- iodelay rst for Q
  q_bit_ce_clk        : in std_logic;         -- iodelay ce for Q
  q_bit_inc_clk       : in std_logic;         -- iodelay inc for Q
  q_bit_clkinv_clk    : in std_logic;         -- invert clk/clkb inputs of iserdes
  phase_clk           : in std_logic;         -- phase indicator
  cal_stage1_done_clk : in std_logic;         -- stage 1 calibration complete
  cal_stage2_done_clk : in std_logic;         -- stage 2 calibration complete
  pd_calib_done_clk_r : out std_logic;        -- phase detector calibration done
  
  clk_rd          : in std_logic;             -- half freq CQ clock
  rst_clk_rd      : in std_logic;             -- reset syncrhonized to clk_rd
  -- indicates which CQ/CQ# the control is for
  cq_num_active   : out std_logic_vector(CQ_BITS-1 downto 0);
  -- indictes which Q the control is for
  q_bit_active    : out std_logic_vector(Q_BITS-1 downto 0);
  -- iodelay load value for CQ
  cq_num_load     : out std_logic_vector(TAP_BITS-1 downto 0);
  -- iodelay load value for CQ#
  cqn_num_load    : out std_logic_vector(TAP_BITS-1 downto 0);
  -- iodelay load value for Q
  q_bit_load      : out std_logic_vector(TAP_BITS-1 downto 0);
  cq_num_rst      : out std_logic;            -- iodelay rst control for CQ
  cq_num_ce       : out std_logic;            -- iodelay ce control for CQ
  cq_num_inc      : out std_logic;            -- iodelay inc control for CQ
  cqn_num_rst     : out std_logic;            -- iodelay rst control for CQ#
  cqn_num_ce      : out std_logic;            -- iodelay ce control for CQ#
  cqn_num_inc     : out std_logic;            -- iodelay inc control for CQ#
  q_bit_rst       : out std_logic;            -- iodelay rst for Q
  q_bit_ce        : out std_logic;            -- iodelay ce for Q
  q_bit_inc       : out std_logic;            -- iodelay inc for Q
  q_bit_clkinv    : out std_logic;            -- invert clk/clkb inputs of iserdes
  phase           : out std_logic;            -- phase indicator
  cal_stage1_done : out std_logic;            -- stage 1 calibration complete
  cal_stage2_done : out std_logic;            -- stage 2 calibration complete
  pd_calib_done   : in std_logic;             -- phase detector calibration complete
  
  -- debug signals  
  dbg_inc_cq_all        : in std_logic;                     -- increment all CQs
  dbg_inc_cqn_all       : in std_logic;                     -- increment all CQ#s
  dbg_inc_q_all         : in std_logic;                     -- increment all Qs
  dbg_dec_cq_all        : in std_logic;                     -- decrement all CQs   
  dbg_dec_cqn_all       : in std_logic;                     -- decrement all CQ#s 
  dbg_dec_q_all         : in std_logic;                     -- decrement all Qs   
  dbg_inc_cq            : in std_logic;                     -- increment selected CQ  
  dbg_inc_cqn           : in std_logic;                     -- increment selected CQ#
  dbg_inc_q             : in std_logic;                     -- increment selected Q  
  dbg_dec_cq            : in std_logic;                     -- decrement selected CQ  
  dbg_dec_cqn           : in std_logic;                     -- decrement selected CQ# 
  dbg_dec_q             : in std_logic;                     -- decrement selected Q   
  dbg_sel_cq            : in std_logic_vector(CQ_BITS-1 downto 0);  -- selected CQ bit
  dbg_sel_cqn           : in std_logic_vector(CQ_BITS-1 downto 0);  -- selected CQ# bit
  dbg_sel_q             : in std_logic_vector(Q_BITS-1 downto 0);   -- selected Q bit
  dbg_sel_q_clkrd       : out std_logic_vector(Q_BITS-1 downto 0);
  dbg_sel_cq_clkrd      : out std_logic_vector(CQ_BITS-1 downto 0);
  dbg_sel_cqn_clkrd     : out std_logic_vector(CQ_BITS-1 downto 0);
  dbg_inc_q_clkrd       : out std_logic;
  dbg_dec_q_clkrd       : out std_logic;
  dbg_inc_cq_clkrd      : out std_logic;
  dbg_dec_cq_clkrd      : out std_logic;
  dbg_inc_cqn_clkrd     : out std_logic;
  dbg_dec_cqn_clkrd     : out std_logic;
  dbg_inc_q_all_clkrd   : out std_logic;
  dbg_dec_q_all_clkrd   : out std_logic;
  dbg_inc_cq_all_clkrd  : out std_logic;
  dbg_dec_cq_all_clkrd  : out std_logic;
  dbg_inc_cqn_all_clkrd : out std_logic;
  dbg_dec_cqn_all_clkrd : out std_logic
);
 end component;
  
component phy_read_dly_ctrl is 
  generic(
    MEMORY_WIDTH    : integer := 36;          -- Width of each memory
    NUM_DEVICES     : integer := 2;           --Number of memory devices
    DEVICE_ID       : integer := 0;           --Indicates memory device instance
    MIN_TAPS        : integer := 5;           -- Minimum usuable clock tap setting
    MAX_TAPS        : integer := 5;           -- Maximum usuable clock tap setting
    TAP_BITS        : integer := 5;           -- Number of bits needed to represent 
                                              -- DEVICE_TAPS
    CQ_BITS         : integer := 1;           -- Number of bits needed to represent 
                                              -- number of cq/cq#'s
    Q_BITS          : integer := 7;           -- Number of bits needed to represent 
                                              -- number of q's
    SIM_CAL_OPTION  : string  := "NONE";      -- Skips various calibration steps 
                                              -- "NONE", "FAST_CAL", "SKIP_CAL"
    MEM_TYPE        : string  := "QDR2PLUS";  -- Memory Type (QDR2PLUS, QDR2)
    DEBUG_PORT      : string  := "ON";        -- Debug using Chipscope controls
    TCQ             : integer := 100          -- Register delay
  );
  port(
    -- System Signals
    clk_rd      : in std_logic;     -- Half freq CQ clock
    rst_clk_rd  : in std_logic;     -- reset syncrhonized to clk_rd
    
    --Stage 1 Calibration Signals Synchronized to clk_rd
    -- indicates which CQ/CQ# the control is for
    cq_num_active   : in std_logic_vector(CQ_BITS-1 downto 0);
    -- indicates which Q the control is for
    q_bit_active    : in std_logic_vector(Q_BITS-1 downto 0);
    -- iodelay load value for CQ
    cq_num_load     : in std_logic_vector(TAP_BITS-1 downto 0);
    -- iodelay load for CQ#
    cqn_num_load    : in std_logic_vector(TAP_BITS-1 downto 0);
    -- iodelay load for Q
    q_bit_load      : in std_logic_vector(TAP_BITS-1 downto 0);
    cq_num_rst      : in std_logic;               -- iodelay rst control for CQ
    cq_num_ce       : in std_logic;               -- iodelay ce control for CQ
    cq_num_inc      : in std_logic;               -- iodelay inc control for CQ
    cqn_num_rst     : in std_logic;               -- iodelay rst control for CQ#
    cqn_num_ce      : in std_logic;               -- iodelay ce control for CQ#
    cqn_num_inc     : in std_logic;               -- iodelay inc control for CQ#
    q_bit_rst       : in std_logic;               -- iodelay rst for Q;
    q_bit_ce        : in std_logic;               -- iodelay ce for Q;
    q_bit_inc       : in std_logic;               -- iodelay inc for Q;
    q_bit_clkinv    : in std_logic;               -- invert clk/clkb inputs of iserdes
    cal_stage1_done : in std_logic;               -- stage 1 calibration is done
    
    --Phase Detector Signals
    cal_stage2_done     : in std_logic;   -- indicates stage 2 calibration is complete
    pd_en_maintain      : in std_logic;   -- iodelay ce from phase detector
    pd_incdec_maintain  : in std_logic;   -- iodelay inc/dec from phase detector
    
    -- IDELAY/ISERDES Signals
    cq_dly_ce     : out std_logic;              -- CQ IDELAY clock enable
    cq_dly_inc    : out std_logic;              -- CQ IDELAY increment
    cq_dly_rst    : out std_logic;              -- CQ IDELAY clock reset
    --  CQ IDELAY cntvaluein load value
    cq_dly_load   : out std_logic_vector(TAP_BITS-1 downto 0);    
    cqn_dly_ce    : out std_logic;              -- CQ# IDELAY clock enable
    cqn_dly_inc   : out std_logic;              -- CQ# IDELAY increment
    cqn_dly_rst   : out std_logic;              -- CQ# IDELAY clock reset
    -- CQ# IDELAY cntvaluein load value
    cqn_dly_load  : out std_logic_vector(TAP_BITS-1 downto 0);   
    -- Q IDELAY clock enable
    q_dly_ce      : out std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    q_dly_inc     : out std_logic;              -- Q IDELAY increment
    -- Q IDELAY clock reset
    q_dly_rst     : out std_logic_vector(MEMORY_WIDTH-1 downto 0);  
    -- Q IDELAY cntvaluein load value
    q_dly_load    : out std_logic_vector(TAP_BITS-1 downto 0);     
    q_dly_clkinv  : out std_logic;              -- ISERDES clk inversion
    iserdes_rst   : out std_logic;              -- ISERDES reset

    -- chipscope debug signals
    dbg_sel_q_clkrd       : in std_logic_vector(Q_BITS-1 downto 0);
    dbg_sel_cq_clkrd      : in std_logic_vector(CQ_BITS-1 downto 0);
    dbg_sel_cqn_clkrd     : in std_logic_vector(CQ_BITS-1 downto 0);
    dbg_inc_q_clkrd       : in std_logic;
    dbg_dec_q_clkrd       : in std_logic;
    dbg_inc_cq_clkrd      : in std_logic;
    dbg_dec_cq_clkrd      : in std_logic;
    dbg_inc_cqn_clkrd     : in std_logic;
    dbg_dec_cqn_clkrd     : in std_logic;
    dbg_inc_q_all_clkrd   : in std_logic;
    dbg_dec_q_all_clkrd   : in std_logic;
    dbg_inc_cq_all_clkrd  : in std_logic;
    dbg_dec_cq_all_clkrd  : in std_logic;
    dbg_inc_cqn_all_clkrd : in std_logic;
    dbg_dec_cqn_all_clkrd : in std_logic 
  );
end component;
  
  component qdr_rld_phy_pd 
  generic(
    CLK_PERIOD      : integer := 1876;
    REFCLK_FREQ     : real    := 300.0;         -- Ref Clk Freq. for IODELAYs
    MEM_TYPE        : string  := "QDR2PLUS";
    IODELAY_GRP     : string  := "IODELAY_MIG"; -- May be assigned unique name 
                                                -- when mult IP cores in design
    MIN_TAPS        : integer := 5;             -- minimum usuable clock tap setting                                    
    TCQ             : integer := 100;           -- Register Delay
    SIM_CAL_OPTION  : string  := "NONE";        -- "NONE", "FAST_CAL", or "SKIP_CAL"
    SIM_INIT_OPTION : string  := "NONE"         -- Simulation only. "NONE", "SIM_MODE"
  );
  port(
    pd_calib_start      : in std_logic;
    clk_cq              : in std_logic;
    clk_cqn             : in std_logic;
    clk_rd              : in std_logic;
    pd_source           : in std_logic;
    clk                 : in std_logic;
    clk_mem             : in std_logic;
    clk_wr              : in std_logic;
    dbg_pd_off          : in std_logic;
    rst_clk_rd          : in std_logic;
    rst_wr_clk          : in std_logic;
    wc                  : in std_logic;
    pd_en_maintain      : out std_logic;
    pd_calib_done       : out std_logic;
    pd_calib_error      : out std_logic;
    pd_incdec_maintain  : out std_logic
    );
  end component;
  
  begin
    
  -- Debug Signals
  dbg_align_rd0     <= align_rd0;
  dbg_align_fd0     <= align_fd0;
  dbg_align_rd1     <= align_rd1;
  dbg_align_fd1     <= align_fd1;
  dbg_pd_calib_done <= pd_calib_done_clk;
  dbg_pd_calib_error <= pd_calib_error;
  
  dbg_inc_latency    <= inc_latency;
  dbg_error_max_latency <= error_max_latency;
  dbg_error_adj_latency <= error_adj_latency;
  dbg_cq_num            <= cq_num_active_clk;
  dbg_q_bit             <= q_bit_active_clk;

  -- Assign outputs that have feedback into design.
  cal_done          <= cal_done_int;
  cal_stage2_start  <= cal_stage2_start_int;
  rd_data0_int      <= (dcb_rd0 & dcb_fd0);
  rd_data1_int      <= (dcb_rd1 & dcb_fd1);
  rd_data0          <= rd_data0_int;
  rd_data1          <= rd_data1_int;
  read_data         <= (rd_data0_int & rd_data1_int);
  cq_dly_rst        <= cq_dly_rst_sig;

  process (clk)
  begin
     if (clk'event and clk='1') then  
        rst_delayed(0) <= rst_wr_clk     after TCQ*1 ps;
        rst_delayed(1) <= rst_delayed(0) after TCQ*1 ps;
        rst_delayed(2) <= rst_delayed(1) after TCQ*1 ps;
        rst_delayed(3) <= rst_delayed(2) after TCQ*1 ps;
     end if;  
  end process;

  process(clk)
  begin 
   if (clk'event and clk='1') then  
        wc <=  rst_delayed(3) and not(rst_delayed(2))   after TCQ*1 ps;           
   end if;  
  end process;

  -- instantiate valid generator logic that retimes the valids for the out
  -- going data.
  u_phy_read_vld_gen : phy_read_vld_gen 
  generic map(   
    BURST_LEN    => BURST_LEN,
    TCQ          => TCQ    
  )  
  port map(
    clk            => clk,
    rst_clk        => rst_clk,
    int_rd_cmd_n   => int_rd_cmd_n,
    valid_latency  => valid_latency,
    cal_done       => cal_done_int,
    data_valid0    => rd_valid0,
    data_valid1    => rd_valid1,
    dbg_valid_lat  => dbg_valid_lat
  );
  
  -- Instantiate the stage 1 calibration which performs delay calibration in
  -- order to center align the clock and data. It also performs realignment
  -- calibration.
  u_phy_read_stage1_cal : phy_read_stage1_cal 
  generic map(
    DATA_WIDTH       => DATA_WIDTH,
    NUM_DEVICES      => NUM_DEVICES,
    MEMORY_WIDTH     => MEMORY_WIDTH,
    DEVICE_TAPS      => DEVICE_TAPS,
    TAP_BITS         => TAP_BITS,
    IODELAY_TAP_RES  => IODELAY_TAP_RES,
    CENTER_TAP       => CENTER_TAP,
    MIN_TAPS         => MIN_TAPS,
    MAX_TAPS         => MAX_TAPS,
    CQ_BITS          => CQ_BITS,
    Q_BITS           => Q_BITS,
    MEM_TYPE         => MEM_TYPE,
    SIM_CAL_OPTION   => SIM_CAL_OPTION,
    TCQ              => TCQ    
  )
  port map(  
    clk              => clk,
    rst_clk          => rst_clk,
    init_done        => init_done,
    cal_stage1_start => cal_stage1_start,
    cal_stage2_start => cal_stage2_start_int,
    rise_data0       => dcb_rd0,
    fall_data0       => dcb_fd0,
    rise_data1       => dcb_rd1,
    fall_data1       => dcb_fd1,
    phase            => phase_clk,
    cq_num           => cq_num_active_clk,
    q_bit            => q_bit_active_clk,
    cq_num_load      => cq_num_load_clk,
    cqn_num_load     => cqn_num_load_clk,
    q_bit_load       => q_bit_load_clk,
    cq_num_rst       => cq_num_rst_clk,
    cq_num_ce        => cq_num_ce_clk,
    cq_num_inc       => cq_num_inc_clk,
    cqn_num_rst      => cqn_num_rst_clk,
    cqn_num_ce       => cqn_num_ce_clk,
    cqn_num_inc      => cqn_num_inc_clk,
    q_bit_rst        => q_bit_rst_clk,
    q_bit_ce         => q_bit_ce_clk,
    q_bit_inc        => q_bit_inc_clk,
    q_bit_clkinv     => q_bit_clkinv_clk,
    error_align      => error_align,
    dbg_rd_stage1_cal => dbg_rd_stage1_cal
  );
  
  -- Instantiate the stage 2 calibration logic which resolves latencies in the
  -- system and calibrates the valids.
  u_phy_read_stage2_cal : phy_read_stage2_cal 
  generic map( 
    BURST_LEN          => BURST_LEN,
    DATA_WIDTH         => DATA_WIDTH,
    NUM_DEVICES        => NUM_DEVICES,
    MEMORY_WIDTH       => MEMORY_WIDTH,
    FIXED_LATENCY_MODE => FIXED_LATENCY_MODE,
    PHY_LATENCY        => PHY_LATENCY
   -- TCQ                => TCQ    
  )
  port map(
    clk                => clk,
    rst_clk            => rst_clk,
    cal_stage2_start   => cal_stage2_start_int,
    int_rd_cmd_n       => int_rd_cmd_n,
    read_data          => read_data,
    inc_latency        => inc_latency,
    valid_latency      => valid_latency,
    cal_done           => cal_done_int,
    pd_calib_done      => pd_calib_done_clk,
    cal_stage2_done    => cal_stage2_done_clk,
    error_max_latency  => error_max_latency,
    error_adj_latency  => error_adj_latency,
    dbg_stage2_cal     => dbg_stage2_cal
  );
  
  nd_io_inst : for nd_i in 0 to NUM_DEVICES-1 generate
  begin
    -- Instantiate the data align logic which realigns the data from the
    -- ISERDES as needed.
    u_phy_read_data_align : phy_read_data_align 
    generic map(
      MEMORY_WIDTH => MEMORY_WIDTH,
      TCQ          => TCQ    
    )  
    port map(
      clk_rd       => clk_rd(nd_i),
      rst_clk_rd   => rst_clk_rd(nd_i),
      iserdes_rd0  => iserdes_rd0(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      iserdes_fd0  => iserdes_fd0(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      iserdes_rd1  => iserdes_rd1(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      iserdes_fd1  => iserdes_fd1(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      rise_data0   => align_rd0(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      fall_data0   => align_fd0(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      rise_data1   => align_rd1(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      fall_data1   => align_fd1(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      phase        => phase(nd_i),
      dbg_phase    => dbg_phase(nd_i)
    );
    
    -- Instantiate the data circular buffer which is used to cross incoming
    -- read data from the clk_rd domains into the main clk domain. It is also
    -- used to adjust latencies.
    u_phy_read_dcb : phy_read_dcb 
    generic map(
      MEMORY_WIDTH   => MEMORY_WIDTH,
      TCQ            => TCQ    
    )  
    port map(
      clk_rd         => clk_rd(nd_i),
      rst_clk_rd     => rst_clk_rd(nd_i),
      clk            => clk,
      rst_clk        => rst_clk,
      cq_dly_rst     => cq_dly_rst_sig(nd_i),
      din_rd0        => align_rd0(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      din_fd0        => align_fd0(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      din_rd1        => align_rd1(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      din_fd1        => align_fd1(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      dout_rd0       => dcb_rd0(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      dout_fd0       => dcb_fd0(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      dout_rd1       => dcb_rd1(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      dout_fd1       => dcb_fd1(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
      inc_latency    => inc_latency(nd_i),
      dbg_dcb_wr_ptr => dbg_dcb_wr_ptr((nd_i*5+5-1) downto (nd_i*5)),
      dbg_dcb_rd_ptr => dbg_dcb_rd_ptr((nd_i*5+5-1) downto (nd_i*5)),
      dbg_dcb_din    => dbg_dcb_din((nd_i*4*MEMORY_WIDTH)+(4*MEMORY_WIDTH)-1 downto (nd_i*4*MEMORY_WIDTH)),
      dbg_dcb_dout   => dbg_dcb_dout((nd_i*4*MEMORY_WIDTH)+(4*MEMORY_WIDTH)-1 downto (nd_i*4*MEMORY_WIDTH))
    );
    
    -- control from the clk domain into the rd_clk domain.
    u_phy_read_sync : phy_read_sync 
    generic map(
      TAP_BITS    => TAP_BITS,
      CQ_BITS     => CQ_BITS,
      Q_BITS      => Q_BITS,
      DEVICE_ID   => nd_i,
      DEBUG_PORT  => DEBUG_PORT,
      TCQ         => TCQ
    ) 
    port map(
      clk                  => clk,
      rst_clk              => rst_clk,
      cq_num_active_clk    => cq_num_active_clk,
      q_bit_active_clk     => q_bit_active_clk,
      cq_num_load_clk      => cq_num_load_clk,
      cqn_num_load_clk     => cqn_num_load_clk,
      q_bit_load_clk       => q_bit_load_clk,
      cq_num_rst_clk       => cq_num_rst_clk,
      cq_num_ce_clk        => cq_num_ce_clk,
      cq_num_inc_clk       => cq_num_inc_clk,
      cqn_num_rst_clk      => cqn_num_rst_clk,
      cqn_num_ce_clk       => cqn_num_ce_clk,
      cqn_num_inc_clk      => cqn_num_inc_clk,
      q_bit_rst_clk        => q_bit_rst_clk,
      q_bit_ce_clk         => q_bit_ce_clk,
      q_bit_inc_clk        => q_bit_inc_clk,
      q_bit_clkinv_clk     => q_bit_clkinv_clk,
      phase_clk            => phase_clk(nd_i),
      cal_stage1_done_clk  => cal_stage2_start_int,
      cal_stage2_done_clk  => cal_stage2_done_clk,
      pd_calib_done_clk_r  => pd_calib_done_clk(nd_i),
      clk_rd               => clk_rd(nd_i),
      rst_clk_rd           => rst_clk_rd(nd_i),
      cq_num_active        => cq_num_active(CQ_BITS*(nd_i+1)-1 downto CQ_BITS*nd_i),
      q_bit_active         => q_bit_active(Q_BITS*(nd_i+1)-1 downto Q_BITS*nd_i),
      cq_num_load          => cq_num_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      cqn_num_load         => cqn_num_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      q_bit_load           => q_bit_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      cq_num_rst           => cq_num_rst(nd_i),
      cq_num_ce            => cq_num_ce(nd_i),
      cq_num_inc           => cq_num_inc(nd_i),
      cqn_num_rst          => cqn_num_rst(nd_i),
      cqn_num_ce           => cqn_num_ce(nd_i),
      cqn_num_inc          => cqn_num_inc(nd_i),
      q_bit_rst            => q_bit_rst(nd_i),
      q_bit_ce             => q_bit_ce(nd_i),
      q_bit_inc            => q_bit_inc(nd_i),
      q_bit_clkinv         => q_bit_clkinv(nd_i),
      phase                => phase(nd_i),
      cal_stage1_done      => cal_stage1_done(nd_i),
      cal_stage2_done      => cal_stage2_done(nd_i),
      pd_calib_done        => pd_calib_done(nd_i),          
      dbg_inc_cq_all       => dbg_inc_cq_all,    
      dbg_inc_cqn_all      => dbg_inc_cqn_all,   
      dbg_inc_q_all        => dbg_inc_q_all,     
      dbg_dec_cq_all       => dbg_dec_cq_all,    
      dbg_dec_cqn_all      => dbg_dec_cqn_all,   
      dbg_dec_q_all        => dbg_dec_q_all,     
      dbg_inc_cq           => dbg_inc_cq,        
      dbg_inc_cqn          => dbg_inc_cqn,       
      dbg_inc_q            => dbg_inc_q,         
      dbg_dec_cq           => dbg_dec_cq,        
      dbg_dec_cqn          => dbg_dec_cqn,       
      dbg_dec_q            => dbg_dec_q,         
      dbg_sel_cq           => dbg_sel_cq,        
      dbg_sel_cqn          => dbg_sel_cqn,       
      dbg_sel_q            => dbg_sel_q,
      --Debug signals in clk_rd domain
      dbg_sel_q_clkrd      => dbg_sel_q_clkrd(Q_BITS*(nd_i+1)-1 downto Q_BITS*nd_i),
      dbg_sel_cq_clkrd     => dbg_sel_cq_clkrd(CQ_BITS*(nd_i+1)-1 downto CQ_BITS*nd_i),
      dbg_sel_cqn_clkrd    => dbg_sel_cqn_clkrd(CQ_BITS*(nd_i+1)-1 downto CQ_BITS*nd_i),
      dbg_inc_q_clkrd      => dbg_inc_q_clkrd(nd_i),   
      dbg_dec_q_clkrd      => dbg_dec_q_clkrd(nd_i),
      dbg_inc_cq_clkrd     => dbg_inc_cq_clkrd(nd_i),   
      dbg_dec_cq_clkrd     => dbg_dec_cq_clkrd(nd_i),
      dbg_inc_cqn_clkrd    => dbg_inc_cqn_clkrd(nd_i),   
      dbg_dec_cqn_clkrd    => dbg_dec_cqn_clkrd(nd_i),   
      dbg_inc_q_all_clkrd  => dbg_inc_q_all_clkrd(nd_i),
      dbg_dec_q_all_clkrd  => dbg_dec_q_all_clkrd(nd_i),
      dbg_inc_cq_all_clkrd => dbg_inc_cq_all_clkrd(nd_i),  
      dbg_dec_cq_all_clkrd => dbg_dec_cq_all_clkrd(nd_i),
      dbg_inc_cqn_all_clkrd=> dbg_inc_cqn_all_clkrd(nd_i),  
      dbg_dec_cqn_all_clkrd=> dbg_dec_cqn_all_clkrd(nd_i)
    );
    
    -- Instantiate the IODELAY control logic which replicates the control 
    -- for the target I/O.
    u_phy_read_dly_ctrl : phy_read_dly_ctrl 
    generic map(
      MEMORY_WIDTH     => MEMORY_WIDTH,
      NUM_DEVICES      => NUM_DEVICES,
      DEVICE_ID        => nd_i,
      MIN_TAPS         => MIN_TAPS,
      MAX_TAPS         => MAX_TAPS,
      TAP_BITS         => TAP_BITS,
      CQ_BITS          => CQ_BITS,
      Q_BITS           => Q_BITS,
      DEBUG_PORT       => DEBUG_PORT,
      SIM_CAL_OPTION   => SIM_CAL_OPTION,
      MEM_TYPE         => MEM_TYPE,
      TCQ              => TCQ
    )  
    port map(
      clk_rd             => clk_rd(nd_i),
      rst_clk_rd         => rst_clk_rd(nd_i),
      cq_num_active      => cq_num_active(CQ_BITS*(nd_i+1)-1 downto CQ_BITS*nd_i),
      q_bit_active       => q_bit_active(Q_BITS*(nd_i+1)-1 downto Q_BITS*nd_i),
      cq_num_load        => cq_num_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      cqn_num_load       => cqn_num_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      q_bit_load         => q_bit_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      cq_num_rst         => cq_num_rst(nd_i),
      cq_num_ce          => cq_num_ce(nd_i),
      cq_num_inc         => cq_num_inc(nd_i),
      cqn_num_rst        => cqn_num_rst(nd_i),
      cqn_num_ce         => cqn_num_ce(nd_i),
      cqn_num_inc        => cqn_num_inc(nd_i),
      q_bit_rst          => q_bit_rst(nd_i),
      q_bit_ce           => q_bit_ce(nd_i),
      q_bit_inc          => q_bit_inc(nd_i),
      q_bit_clkinv       => q_bit_clkinv(nd_i),
      cal_stage1_done    => cal_stage1_done(nd_i),
      cal_stage2_done    => cal_stage2_done(nd_i),
      pd_en_maintain     => pd_en_maintain(nd_i),
      pd_incdec_maintain => pd_incdec_maintain(nd_i),
      cq_dly_ce          => cq_dly_ce(nd_i),
      cq_dly_inc         => cq_dly_inc(nd_i),
      cq_dly_rst         => cq_dly_rst_sig(nd_i),
      cq_dly_load        => cq_dly_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      cqn_dly_ce         => cqn_dly_ce(nd_i),
      cqn_dly_inc        => cqn_dly_inc(nd_i),
      cqn_dly_rst        => cqn_dly_rst(nd_i),
      cqn_dly_load       => cqn_dly_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      q_dly_ce           => q_dly_ce(MEMORY_WIDTH*(nd_i+1)-1 downto 
                                     MEMORY_WIDTH*nd_i),
      q_dly_inc          => q_dly_inc(nd_i),
      q_dly_rst          => q_dly_rst(MEMORY_WIDTH*(nd_i+1)-1 downto 
                                      MEMORY_WIDTH*nd_i),
      q_dly_load         => q_dly_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      q_dly_clkinv       => q_dly_clkinv(nd_i),
      iserdes_rst        => iserdes_rst(nd_i),
      dbg_sel_q_clkrd      => dbg_sel_q_clkrd(Q_BITS*(nd_i+1)-1 downto Q_BITS*nd_i),
      dbg_sel_cq_clkrd     => dbg_sel_cq_clkrd(CQ_BITS*(nd_i+1)-1 downto CQ_BITS*nd_i),
      dbg_sel_cqn_clkrd    => dbg_sel_cqn_clkrd(CQ_BITS*(nd_i+1)-1 downto CQ_BITS*nd_i),    
      dbg_inc_q_clkrd      => dbg_inc_q_clkrd(nd_i),
      dbg_dec_q_clkrd      => dbg_dec_q_clkrd(nd_i),
      dbg_inc_cq_clkrd     => dbg_inc_cq_clkrd(nd_i),
      dbg_dec_cq_clkrd     => dbg_dec_cq_clkrd(nd_i),
      dbg_inc_cqn_clkrd    => dbg_inc_cqn_clkrd(nd_i),
      dbg_dec_cqn_clkrd    => dbg_dec_cqn_clkrd(nd_i),
      dbg_inc_q_all_clkrd  => dbg_inc_q_all_clkrd(nd_i),
      dbg_dec_q_all_clkrd  => dbg_dec_q_all_clkrd(nd_i),
      dbg_inc_cq_all_clkrd => dbg_inc_cq_all_clkrd(nd_i),  
      dbg_dec_cq_all_clkrd => dbg_dec_cq_all_clkrd(nd_i),
      dbg_inc_cqn_all_clkrd=> dbg_inc_cqn_all_clkrd(nd_i),  
      dbg_dec_cqn_all_clkrd=> dbg_dec_cqn_all_clkrd(nd_i)
    );
    
     -- Instantiate the Phase Detector which corrects changes in BUFIO/BUFR delays
     -- as a result of V/T. Do not generate when SIM_CAL_OPTION == "SKIP_CAL".
    gen_enable_pd : if (PHASE_DETECT = "ON" and SIM_CAL_OPTION /= "SKIP_CAL") generate 
    begin
      u_phy_qdr_pd : qdr_rld_phy_pd
      generic map(
        CLK_PERIOD     => CLK_PERIOD,
        REFCLK_FREQ    => REFCLK_FREQ,
        MEM_TYPE       => MEM_TYPE,
        IODELAY_GRP    => IODELAY_GRP,
        MIN_TAPS       => MIN_TAPS,
        TCQ            => TCQ,
        SIM_CAL_OPTION => SIM_CAL_OPTION,
        SIM_INIT_OPTION=> SIM_INIT_OPTION
      )  
      port map(
        pd_en_maintain     => pd_en_maintain(nd_i),
        pd_calib_done      => pd_calib_done(nd_i),
        pd_incdec_maintain => pd_incdec_maintain(nd_i),
        pd_calib_error     => pd_calib_error(nd_i),
        pd_calib_start     => cal_stage2_done(nd_i),
        clk_cq             => clk_cq(nd_i),
        clk_cqn            => clk_cqn(nd_i),
        pd_source          => pd_source(nd_i),
        clk_rd             => clk_rd(nd_i),
        clk                => clk,
        clk_mem            => clk_mem,
        clk_wr             => clk_wr,
        wc                 => wc,
        dbg_pd_off         => dbg_pd_off,
        rst_clk_rd         => rst_clk_rd(nd_i),
        rst_wr_clk         => rst_wr_clk
      );
    end generate gen_enable_pd;
    
    gen_disable_pd_tie_off : if (not (PHASE_DETECT = "ON" and SIM_CAL_OPTION /= "SKIP_CAL")) generate
    begin
        pd_en_maintain(nd_i)      <= '0';
        pd_calib_done(nd_i)       <= '1';
        pd_incdec_maintain(nd_i)  <= '0';
    end generate gen_disable_pd_tie_off;
    
  end generate nd_io_inst;
  
end architecture arch;
