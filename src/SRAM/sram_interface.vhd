--******************************************************************************
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
--
--******************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 3.9
--  \   \         Application        : MIG
--  /   /         Filename           : sram_interface.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 07:18:32 $
-- \   \  /  \    Date Created       : Wed Sep 09 2009
--  \___\/\___\
--
-- Device           : Virtex-6
-- Design Name      : QDRII+ SRAM
-- Purpose          :
--   Top-level module. Simple model for what the user might use
--   Typically, the user will only instantiate MEM_INTERFACE_TOP in their
--   code, and generate all backend logic (test bench) separately.
--   In addition to the memory controller, the module instantiates:
--     1. Clock generation/distribution, reset logic
--     2. IDELAY control block
--
-- Reference        :
-- Revision History :
--******************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;
use work.qdr_rld_chipscope.all;

entity sram_interface is
  generic(
   REFCLK_FREQ            : real   := 200.0;     --Iodelay Clock Frequency
   IODELAY_GRP            : string := "IODELAY_MIG";
                             -- It is associated to a set of IODELAYs with
                             -- an IDELAYCTRL that have same IODELAY CONTROLLER
                             -- clock frequency.
   MMCM_ADV_BANDWIDTH     : string  := "OPTIMIZED";
                                     -- MMCM programming algorithm
   CLKFBOUT_MULT_F        : real := 11.0;      -- write PLL VCO multiplier
   CLKOUT_DIVIDE          : integer := 11;      -- VCO output divisor for fast (memory) clocks
   DIVCLK_DIVIDE          : integer := 1;      -- write PLL VCO divisor
   CLK_PERIOD             : integer := 16000;   -- Double the Memory Clk Period (in ps)

   DEBUG_PORT             : string  := "OFF";  -- Enable debug port
   CLK_STABLE             : integer := 2048;   -- Cycles till CQ/CQ# is stable
   ADDR_WIDTH             : integer := 19;     -- Address Width
   DATA_WIDTH             : integer := 36;     -- Data Width
   BW_WIDTH               : integer := 4;      -- Byte Write Width
   BURST_LEN              : integer := 4;      -- Burst Length
   NUM_DEVICES            : integer := 1;      -- No. of Connected Memories
   FIXED_LATENCY_MODE     : integer := 1;      -- Enable Fixed Latency
   PHY_LATENCY            : integer := 20;      -- Expected Latency
   SIM_CAL_OPTION         : string := "NONE"; -- Skip various calibration steps
   SIM_INIT_OPTION        : string  := "NONE"; -- Simulation only. "NONE", "SIM_MODE"
   PHASE_DETECT           : string := "OFF";   -- Enable Phase detector
   IBUF_LPWR_MODE         : string := "OFF";  -- Input buffer low power mode
   IODELAY_HP_MODE        : string := "ON";   -- IODELAY High Performance Mode
   TCQ                    : integer := 1;   -- Simulation Register Delay
    INPUT_CLK_TYPE         : string  := "SINGLE_ENDED"; -- of clock type
    RST_ACT_LOW            : integer := 1       -- Active Low Reset
    );
  port(

  sys_clk                  : in std_logic;    --single ended system clocks
  ui_clk_in                  : in std_logic;    --single ended system clocks
  clk_ref                  : in std_logic; --single ended iodelayctrl clk
  qdriip_cq_p              : in std_logic_vector(NUM_DEVICES-1 downto 0); --Memory Interface
  qdriip_cq_n              : in std_logic_vector(NUM_DEVICES-1 downto 0);
  qdriip_q                 : in std_logic_vector(DATA_WIDTH-1 downto 0);
  qdriip_k_p               : out std_logic_vector(NUM_DEVICES-1 downto 0);
  qdriip_k_n               : out std_logic_vector(NUM_DEVICES-1 downto 0);
  qdriip_d                 : out std_logic_vector(DATA_WIDTH-1 downto 0);
  qdriip_sa                : out std_logic_vector(ADDR_WIDTH-1 downto 0);
  qdriip_w_n               : out std_logic;
  qdriip_r_n               : out std_logic;
  qdriip_bw_n              : out std_logic_vector(BW_WIDTH-1 downto 0);

  user_wr_cmd0             : in std_logic;      --User interface
  user_wr_addr0            : in std_logic_vector(ADDR_WIDTH-1 downto 0);
  user_rd_cmd0             : in std_logic;
  user_rd_addr0            : in std_logic_vector(ADDR_WIDTH-1 downto 0);
  user_wr_data0            : in std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
  user_wr_bw_n0            : in std_logic_vector(BW_WIDTH*BURST_LEN-1 downto 0);
  ui_clk                   : out std_logic;
  ui_clk_sync_rst          : out std_logic;
  user_rd_valid0           : out std_logic;
  user_rd_data0            : out std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
  qdriip_dll_off_n         : out std_logic;
  cal_done                 : out std_logic;
    sys_rst     : in std_logic --system reset
    );
end sram_interface;

architecture arch_sram_interface of sram_interface is

  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arch_sram_interface : ARCHITECTURE IS
    "mig_v3_9_qdriip_V6, Coregen 13.3";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arch_sram_interface : ARCHITECTURE IS "qdriip_V6,mig_v3_9,{LANGUAGE=VHDL, SYNTHESIS_TOOL=ISE, AXI_ENABLE=0, LEVEL=CONTROLLER, NO_OF_CONTROLLERS=1, INTERFACE_TYPE=QDR_II+_SRAM, CLK_PERIOD=16000, MEMORY_TYPE=components, MEMORY_PART=cy7c1565v18-400bzxc, DQ_WIDTH=36, NUM_DEVICES=1, FIXED_LATENCY_MODE=1, PHY_LATENCY=20, REFCLK_FREQ=200, MMCM_ADV_BANDWIDTH=OPTIMIZED, CLKFBOUT_MULT_F=11, CLKOUT_DIVIDE=11, DEBUG_PORT=OFF, IODELAY_HP_MODE=ON, INTERNAL_VREF=1, DCI_INOUTS=1, INPUT_CLK_TYPE=SINGLE_ENDED}";
  -- clog2 function - ceiling of log base 2
  function clog2 (
    width : integer
  ) return integer is
    variable ii    : unsigned(31 downto 0);
    variable clog2 : integer;
  begin
    ii := to_unsigned(width, 32);
    if (ii = 0) then
      clog2 := 1;
    else
      clog2 := 0;
      while  (ii > 0) loop
        ii    := ii srl 1;
        clog2 := clog2+1;
      end loop;
    end if;
    return clog2;
  end function;


  -- Number of taps in target IDELAY
  constant DEVICE_TAPS     : integer := 32;

  -- Number of bits needed to represent DEVICE_TAPS
  constant TAP_BITS        : integer := clog2(DEVICE_TAPS - 1);
  -- number of bits to represent number of cq/cq#'s
  constant CQ_BITS         : integer := clog2(NUM_DEVICES - 1);
  -- number of bits needed to represent number of q's
  constant Q_BITS          : integer := clog2(DATA_WIDTH - 1);

  component clk_ibuf
    generic(
      INPUT_CLK_TYPE : string
      );
    port(
      sys_clk_p : in  std_logic;
      sys_clk_n : in  std_logic;
      sys_clk   : in  std_logic;
      mmcm_clk  : out std_logic
      );
  end component clk_ibuf;

  component iodelay_ctrl
    generic (
      IODELAY_GRP     : string;
      INPUT_CLK_TYPE  : string;
      RST_ACT_LOW     : integer;
      TCQ             : integer
      );
    port (
      sys_rst          : in  std_logic;
      clk_ref_p        : in  std_logic;
      clk_ref_n        : in  std_logic;
      clk_ref          : in  std_logic;
      iodelay_ctrl_rdy : out std_logic
      );
  end component;

  component qdr_rld_infrastructure
    generic (
      RST_ACT_LOW        : integer;
      CLK_PERIOD         : integer;
      MMCM_ADV_BANDWIDTH : string;
      CLKFBOUT_MULT_F    : real;
      CLKOUT_DIVIDE      : integer;
      DIVCLK_DIVIDE      : integer
      );
    port (
      mmcm_clk     : in std_logic;
      sys_rst      : in std_logic;
      clk0         : out std_logic;
      clkdiv0      : out std_logic;
      clk_wr       : out std_logic;
      mmcm_locked  : out std_logic
      );
  end component;

  component user_top is
    generic (
      ADDR_WIDTH         : integer;
      DATA_WIDTH         : integer;
      BW_WIDTH           : integer;
      BURST_LEN          : integer;
      CLK_PERIOD         : integer;
      REFCLK_FREQ        : real;
      NUM_DEVICES        : integer;
      FIXED_LATENCY_MODE : integer;
      PHY_LATENCY        : integer;
      CLK_STABLE         : integer;
      IODELAY_GRP        : string;
      MEM_TYPE           : string;
      DEVICE_ARCH        : string;
      RST_ACT_LOW        : integer;
      PHASE_DETECT       : string;
      SIM_CAL_OPTION     : string;
      SIM_INIT_OPTION    : string;
      IBUF_LPWR_MODE     : string;
      IODELAY_HP_MODE    : string;
      CQ_BITS            : integer;
      Q_BITS             : integer;
      DEVICE_TAPS        : integer;
      TAP_BITS           : integer;
      DEBUG_PORT         : string;
      TCQ                : integer
      );
    port (
      --System Signals
      clk               : in std_logic;
      rst_clk           : out std_logic;
      sys_rst           : in std_logic;
      clk_mem           : in std_logic;
      clk_wr            : in std_logic;
      mmcm_locked       : in std_logic;
      iodelay_ctrl_rdy  : in std_logic;

      --User Interface
      user_wr_cmd0      : in std_logic;
      user_wr_cmd1      : in std_logic;
      user_wr_addr0     : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      user_wr_addr1     : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      user_rd_cmd0      : in std_logic;
      user_rd_cmd1      : in std_logic;
      user_rd_addr0     : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      user_rd_addr1     : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      user_wr_data0     : in std_logic_vector(BURST_LEN*DATA_WIDTH-1 downto 0);
      user_wr_data1     : in std_logic_vector(2*DATA_WIDTH-1 downto 0);
      user_wr_bw_n0     : in std_logic_vector(BURST_LEN*BW_WIDTH-1 downto 0);
      user_wr_bw_n1     : in std_logic_vector(2*BW_WIDTH-1 downto 0);

      user_cal_done     : out std_logic;
      user_rd_valid0    : out std_logic;
      user_rd_valid1    : out std_logic;
      user_rd_data0     : out std_logic_vector(BURST_LEN*DATA_WIDTH-1 downto 0);
      user_rd_data1     : out std_logic_vector(2*DATA_WIDTH-1 downto 0);

      --Memory Interface
      qdr_dll_off_n     : out std_logic;
      qdr_k_p           : out std_logic_vector(NUM_DEVICES-1 downto 0);
      qdr_k_n           : out std_logic_vector(NUM_DEVICES-1 downto 0);
      qdr_sa            : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      qdr_w_n           : out std_logic;
      qdr_r_n           : out std_logic;
      qdr_bw_n          : out std_logic_vector(BW_WIDTH-1 downto 0);
      qdr_d             : out std_logic_vector(DATA_WIDTH-1 downto 0);
      qdr_q             : in std_logic_vector(DATA_WIDTH-1 downto 0);
      qdr_cq_p          : in std_logic_vector(NUM_DEVICES-1 downto 0);
      qdr_cq_n          : in std_logic_vector(NUM_DEVICES-1 downto 0);

      --ChipScope Readpath Debug Signals
      dbg_phy_wr_cmd_n  : out std_logic_vector(1 downto 0);
      dbg_phy_addr      : out std_logic_vector(ADDR_WIDTH*4-1 downto 0);
      dbg_phy_rd_cmd_n  : out std_logic_vector(1 downto 0);
      dbg_phy_wr_data   : out std_logic_vector(DATA_WIDTH*4-1 downto 0);
      dbg_inc_cq_all    : in std_logic;
      dbg_inc_cqn_all   : in std_logic;
      dbg_inc_q_all     : in std_logic;
      dbg_dec_cq_all    : in std_logic;
      dbg_dec_cqn_all   : in std_logic;
      dbg_dec_q_all     : in std_logic;
      dbg_inc_cq        : in std_logic;
      dbg_inc_cqn       : in std_logic;
      dbg_inc_q         : in std_logic;
      dbg_dec_cq        : in std_logic;
      dbg_dec_cqn       : in std_logic;
      dbg_dec_q         : in std_logic;
      dbg_sel_cq        : in std_logic_vector(CQ_BITS-1 downto 0);
      dbg_sel_cqn       : in std_logic_vector(CQ_BITS-1 downto 0);
      dbg_sel_q         : in std_logic_vector(Q_BITS-1 downto 0);
      dbg_pd_off        : in std_logic;
      dbg_cq_tapcnt     : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
      dbg_cqn_tapcnt    : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
      dbg_q_tapcnt      : out std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0);
      dbg_clk_rd        : out std_logic_vector(NUM_DEVICES-1 downto 0);
      dbg_rd_stage1_cal : out std_logic_vector(255 downto 0);
      dbg_stage2_cal    : out std_logic_vector(127 downto 0);
      dbg_cq_num        : out std_logic_vector(CQ_BITS-1 downto 0);
      dbg_q_bit         : out std_logic_vector(Q_BITS-1 downto 0);
      dbg_valid_lat     : out std_logic_vector(4 downto 0);
      dbg_phase         : out std_logic_vector(NUM_DEVICES-1 downto 0);
      dbg_inc_latency   : out std_logic_vector(NUM_DEVICES-1 downto 0);
      dbg_dcb_wr_ptr    : out std_logic_vector(5*NUM_DEVICES-1 downto 0);
      dbg_dcb_rd_ptr    : out std_logic_vector(5*NUM_DEVICES-1 downto 0);
      dbg_dcb_din       : out std_logic_vector(4*DATA_WIDTH-1 downto 0);
      dbg_dcb_dout      : out std_logic_vector(4*DATA_WIDTH-1 downto 0);
      dbg_error_max_latency : out std_logic_vector(NUM_DEVICES-1 downto 0);
      dbg_error_adj_latency : out std_logic;
      dbg_pd_calib_start : out std_logic_vector(NUM_DEVICES-1 downto 0);
      dbg_pd_calib_done : out std_logic_vector(NUM_DEVICES-1 downto 0);
      dbg_phy_status    : out std_logic_vector(7 downto 0);
      dbg_align_rd0     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      dbg_align_rd1     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      dbg_align_fd0     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      dbg_align_fd1     : out std_logic_vector(DATA_WIDTH-1 downto 0)
      );
  end component;



  signal clk_ref_p         : std_logic;
  signal clk_ref_n         : std_logic;
  signal sys_clk_p         : std_logic;
  signal sys_clk_n         : std_logic;
  signal mmcm_clk          : std_logic;
  signal iodelay_ctrl_rdy  : std_logic;

  signal clk               : std_logic;
  signal rst_clk           : std_logic;
  signal clk_wr            : std_logic;
  signal clk_mem           : std_logic;
  signal mmcm_locked       : std_logic;
  signal cal_done_i        : std_logic;
  signal user_rd_valid0_i  : std_logic;
  signal user_rd_data0_i   : std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
  signal user_wr_cmd1      : std_logic;
  signal user_wr_addr1      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal user_rd_cmd1      : std_logic;
  signal user_rd_addr1     : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal user_wr_data1     : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal user_wr_bw_n1     : std_logic_vector(BW_WIDTH*2-1 downto 0);
  signal user_rd_valid1    : std_logic;
  signal user_rd_data1     : std_logic_vector(DATA_WIDTH*2-1 downto 0);

  signal dbg_phy_wr_cmd_n  : std_logic_vector(1 downto 0);
  signal dbg_phy_addr      : std_logic_vector(ADDR_WIDTH*BURST_LEN-1 downto 0);
  signal dbg_phy_rd_cmd_n  : std_logic_vector(1 downto 0);
  signal dbg_phy_wr_data   : std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
  signal dbg_inc_cq_all    : std_logic;    -- increment all CQs
  signal dbg_inc_cqn_all   : std_logic;    -- increment all CQ#s
  signal dbg_inc_q_all     : std_logic;    -- increment all Qs
  signal dbg_dec_cq_all    : std_logic;    -- decrement all CQs
  signal dbg_dec_cqn_all   : std_logic;    -- decrement all CQ#s
  signal dbg_dec_q_all     : std_logic;    -- decrement all Qs
  signal dbg_inc_cq        : std_logic;    -- increment selected CQ
  signal dbg_inc_cqn       : std_logic;    -- increment selected CQ#
  signal dbg_inc_q         : std_logic;    -- increment selected Q
  signal dbg_dec_cq        : std_logic;    -- decrement selected CQ
  signal dbg_dec_cqn       : std_logic;    -- decrement selected CQ#
  signal dbg_dec_q         : std_logic;    -- decrement selected Q
  signal dbg_sel_cq        : std_logic_vector(CQ_BITS-1 downto 0) := (others => '0'); -- selected CQ bit
  signal dbg_sel_cqn       : std_logic_vector(CQ_BITS-1 downto 0) := (others => '0'); -- selected CQ# bit
  signal dbg_sel_q         : std_logic_vector(Q_BITS-1 downto 0);  -- selected Q bit
  signal dbg_cq_tapcnt    : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0); -- tap count for each cq
  signal dbg_cqn_tapcnt    : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0); -- tap count for each cq#
  signal dbg_q_tapcnt      : std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0);  -- tap count for each q
  signal dbg_clk_rd        : std_logic_vector(NUM_DEVICES-1 downto 0); -- clk_rd in each domain
  signal dbg_rd_stage1_cal  : std_logic_vector(255 downto 0);  -- stage 1 cal debug
  signal dbg_stage2_cal    : std_logic_vector(127 downto 0);  -- stage 2 cal debug
  signal dbg_cq_num        : std_logic_vector(CQ_BITS-1 downto 0);  -- current cq/cq# being calibrated
  signal dbg_q_bit         : std_logic_vector(Q_BITS-1 downto 0);   -- current q being calibrated
  signal dbg_valid_lat     : std_logic_vector(4 downto 0);          -- latency of the system
  signal dbg_phase         : std_logic_vector(NUM_DEVICES-1 downto 0);  -- data align phase indication
  signal dbg_inc_latency   : std_logic_vector(NUM_DEVICES-1 downto 0);  -- increase latency for dcb
  signal dbg_dcb_wr_ptr    : std_logic_vector(5*NUM_DEVICES-1 downto 0);-- dcb write pointers
  signal dbg_dcb_rd_ptr    : std_logic_vector(5*NUM_DEVICES-1 downto 0);-- dcb read pointers
  signal dbg_dcb_din       : std_logic_vector(4*DATA_WIDTH-1 downto 0); -- dcb data in
  signal dbg_dcb_dout      : std_logic_vector(4*DATA_WIDTH-1 downto 0); -- dcb data out
  signal dbg_error_max_latency  : std_logic_vector(NUM_DEVICES-1 downto 0);  -- stage 2 cal max latency error
  signal dbg_error_adj_latency  : std_logic;  -- stage 2 cal latency adjustment error
  signal dbg_pd_calib_start  : std_logic_vector(NUM_DEVICES-1 downto 0);-- indicates phase detector to start
  signal dbg_pd_calib_done  : std_logic_vector(NUM_DEVICES-1 downto 0); -- indicates phase detector is complete
  signal dbg_phy_status    : std_logic_vector(7 downto 0);              -- phy status
  signal cmp_err           : std_logic;
  signal dbg_clear_error   : std_logic;
  signal dbg_align_rd0     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dbg_align_rd1     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dbg_align_fd0     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dbg_align_fd1     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dbg_pd_off        : std_logic;
  signal qdriip_cs0_clk      : std_logic;
  signal qdriip_cs1_clk      : std_logic;
  signal qdriip_cs2_clk      : std_logic;
  signal qdriip_trigger      : std_logic_vector(15 downto 0);
  signal qdriip_cs0_trig     : std_logic_vector(15 downto 0);
  signal qdriip_cs1_trig     : std_logic_vector(15 downto 0);
  signal qdriip_cs0_data     : std_logic_vector(255 downto 0);
  signal qdriip_cs1_data     : std_logic_vector(255 downto 0);
  signal qdriip_cs2_sync_out : std_logic_vector(35 downto 0);
  signal qdriip_cs2_async_in : std_logic_vector(255 downto 0);
  signal qdriip_cs0_control  : std_logic_vector(35 downto 0);
  signal qdriip_cs1_control  : std_logic_vector(35 downto 0);
  signal qdriip_cs2_control  : std_logic_vector(35 downto 0);

begin

  cal_done                     <= cal_done_i;
  clk_ref_p                    <= '0';
  clk_ref_n                    <= '0';
  sys_clk_p                    <= '0';
  sys_clk_n                    <= '0';
  mmcm_clk                    <= sys_clk;
  mmcm_locked                    <= '1';
  ui_clk                       <= ui_clk_in;
  ui_clk_sync_rst              <= rst_clk;
  user_rd_valid0               <= user_rd_valid0_i;
  user_rd_data0                <= user_rd_data0_i;

--  u_clk_ibuf : clk_ibuf
--    generic map(
--      INPUT_CLK_TYPE => INPUT_CLK_TYPE
--      )
--    port map(
--      sys_clk_p => sys_clk_p,
--      sys_clk_n => sys_clk_n,
--      sys_clk   => sys_clk,
--      mmcm_clk  => mmcm_clk
--      );

  u_iodelay_ctrl : iodelay_ctrl
    generic map(
      IODELAY_GRP    => IODELAY_GRP,
      INPUT_CLK_TYPE => INPUT_CLK_TYPE,
      RST_ACT_LOW    => RST_ACT_LOW,
      TCQ            => TCQ
      )
    port map(
      sys_rst          => sys_rst,
      clk_ref_p        => clk_ref_p,
      clk_ref_n        => clk_ref_n,
      clk_ref          => clk_ref,
      iodelay_ctrl_rdy => iodelay_ctrl_rdy
      );

--  u_infrastructure : qdr_rld_infrastructure
--    generic map (
--      RST_ACT_LOW        => RST_ACT_LOW,
--      CLK_PERIOD         => CLK_PERIOD,
--      MMCM_ADV_BANDWIDTH => MMCM_ADV_BANDWIDTH,
--      CLKFBOUT_MULT_F    => real(CLKFBOUT_MULT_F),
--      CLKOUT_DIVIDE      => CLKOUT_DIVIDE,
--      DIVCLK_DIVIDE      => DIVCLK_DIVIDE
--      )
--    port map (
--      mmcm_clk    => mmcm_clk,
--      sys_rst     => sys_rst,
--      clk0        => clk_mem,
--      clkdiv0     => clk,
--      clk_wr      => clk_wr,
--      mmcm_locked => mmcm_locked
--      );
	clk <= ui_clk_in;
	clk_mem <= sys_clk;
	clk_wr <= sys_clk;
  --Instantiate the User Interface Module (PHY)
  u_user_top : user_top
    generic map (
      ADDR_WIDTH         => ADDR_WIDTH,
      DATA_WIDTH         => DATA_WIDTH,
      BW_WIDTH           => BW_WIDTH,
      BURST_LEN          => BURST_LEN,
      CLK_PERIOD         => CLK_PERIOD,
      REFCLK_FREQ        => REFCLK_FREQ,
      NUM_DEVICES        => NUM_DEVICES,
      IODELAY_GRP        => IODELAY_GRP,
      FIXED_LATENCY_MODE => FIXED_LATENCY_MODE,
      PHY_LATENCY        => PHY_LATENCY,
      CLK_STABLE         => CLK_STABLE,
      MEM_TYPE           => "QDR2PLUS",
      DEVICE_ARCH        => "virtex6",
      RST_ACT_LOW        => RST_ACT_LOW,
      PHASE_DETECT       => PHASE_DETECT,
      SIM_CAL_OPTION     => SIM_CAL_OPTION,
      SIM_INIT_OPTION    => SIM_INIT_OPTION,
      IBUF_LPWR_MODE     => IBUF_LPWR_MODE,
      IODELAY_HP_MODE    => IODELAY_HP_MODE,
      CQ_BITS            => CQ_BITS,
      Q_BITS             => Q_BITS,
      DEVICE_TAPS        => DEVICE_TAPS,
      TAP_BITS           => TAP_BITS,
      DEBUG_PORT         => DEBUG_PORT,
      TCQ                => TCQ
      )
    port map (
      clk                   => clk,
      rst_clk               => rst_clk,
      sys_rst               => sys_rst,
      clk_mem               => clk_mem,
      clk_wr                => clk_wr,
      mmcm_locked           => mmcm_locked,
      iodelay_ctrl_rdy      => iodelay_ctrl_rdy,
      user_wr_cmd0          => user_wr_cmd0,
      user_wr_cmd1          => user_wr_cmd1,
      user_wr_addr0         => user_wr_addr0,
      user_wr_addr1         => user_wr_addr1,
      user_rd_cmd0          => user_rd_cmd0,
      user_rd_cmd1          => user_rd_cmd1,
      user_rd_addr0         => user_rd_addr0,
      user_rd_addr1         => user_rd_addr1,
      user_wr_data0         => user_wr_data0,
      user_wr_data1         => user_wr_data1,
      user_wr_bw_n0         => user_wr_bw_n0,
      user_wr_bw_n1         => user_wr_bw_n1,
      user_cal_done         => cal_done_i,
      user_rd_valid0        => user_rd_valid0_i,
      user_rd_valid1        => user_rd_valid1,
      user_rd_data0         => user_rd_data0_i,
      user_rd_data1         => user_rd_data1,
      qdr_dll_off_n         => qdriip_dll_off_n,
      qdr_k_p               => qdriip_k_p,
      qdr_k_n               => qdriip_k_n,
      qdr_sa                => qdriip_sa,
      qdr_w_n               => qdriip_w_n,
      qdr_r_n               => qdriip_r_n,
      qdr_bw_n              => qdriip_bw_n,
      qdr_d                 => qdriip_d,
      qdr_q                 => qdriip_q,
      qdr_cq_p              => qdriip_cq_p,
      qdr_cq_n              => qdriip_cq_n,
      dbg_phy_wr_cmd_n      => dbg_phy_wr_cmd_n,
      dbg_phy_addr          => dbg_phy_addr,
      dbg_phy_rd_cmd_n      => dbg_phy_rd_cmd_n,
      dbg_phy_wr_data       => dbg_phy_wr_data,
      dbg_inc_cq_all        => dbg_inc_cq_all,
      dbg_inc_cqn_all       => dbg_inc_cqn_all,
      dbg_inc_q_all         => dbg_inc_q_all,
      dbg_dec_cq_all        => dbg_dec_cq_all,
      dbg_dec_cqn_all       => dbg_dec_cqn_all,
      dbg_dec_q_all         => dbg_dec_q_all,
      dbg_inc_cq            => dbg_inc_cq,
      dbg_inc_cqn           => dbg_inc_cqn,
      dbg_inc_q             => dbg_inc_q,
      dbg_dec_cq            => dbg_dec_cq,
      dbg_dec_cqn           => dbg_dec_cqn,
      dbg_dec_q             => dbg_dec_q,
      dbg_sel_cq            => dbg_sel_cq,
      dbg_sel_cqn           => dbg_sel_cqn,
      dbg_sel_q             => dbg_sel_q,
      dbg_pd_off            => dbg_pd_off,
      dbg_cq_tapcnt         => dbg_cq_tapcnt,
      dbg_cqn_tapcnt        => dbg_cqn_tapcnt,
      dbg_q_tapcnt          => dbg_q_tapcnt,
      dbg_clk_rd            => dbg_clk_rd,
      dbg_rd_stage1_cal     => dbg_rd_stage1_cal,
      dbg_stage2_cal        => dbg_stage2_cal,
      dbg_cq_num            => dbg_cq_num,
      dbg_q_bit             => dbg_q_bit,
      dbg_valid_lat         => dbg_valid_lat,
      dbg_phase             => dbg_phase,
      dbg_inc_latency       => dbg_inc_latency,
      dbg_dcb_wr_ptr        => dbg_dcb_wr_ptr,
      dbg_dcb_rd_ptr        => dbg_dcb_rd_ptr,
      dbg_dcb_din           => dbg_dcb_din,
      dbg_dcb_dout          => dbg_dcb_dout,
      dbg_error_max_latency => dbg_error_max_latency,
      dbg_error_adj_latency => dbg_error_adj_latency,
      dbg_pd_calib_start    => dbg_pd_calib_start,
      dbg_pd_calib_done     => dbg_pd_calib_done,
      dbg_phy_status        => dbg_phy_status,
      dbg_align_rd0         => dbg_align_rd0,
      dbg_align_rd1         => dbg_align_rd1,
      dbg_align_fd0         => dbg_align_fd0,
      dbg_align_fd1         => dbg_align_fd1
       );


  gen_dbg_tie_off : if (DEBUG_PORT = "OFF") generate
    dbg_inc_cq_all  <= '0';
    dbg_inc_cqn_all <= '0';
    dbg_inc_q_all   <= '0';
    dbg_dec_cq_all  <= '0';
    dbg_dec_cqn_all <= '0';
    dbg_dec_q_all   <= '0';
    dbg_inc_cq      <= '0';
    dbg_inc_cqn     <= '0';
    dbg_inc_q       <= '0';
    dbg_dec_cq      <= '0';
    dbg_dec_cqn     <= '0';
    dbg_dec_q       <= '0';
    dbg_sel_cq      <= (others => '0');
    dbg_sel_cqn     <= (others => '0');
    dbg_sel_q       <= (others => '0');
    dbg_clear_error <= '0';
    dbg_pd_off      <= '0';
  end generate;
  chipscope_inst : if (DEBUG_PORT = "ON") generate
    dbg_inc_cq_all     <=  qdriip_cs2_sync_out(1);
    dbg_inc_cqn_all    <=  qdriip_cs2_sync_out(2);
    dbg_inc_q_all      <=  qdriip_cs2_sync_out(3);
    dbg_dec_cq_all     <=  qdriip_cs2_sync_out(4);
    dbg_dec_cqn_all    <=  qdriip_cs2_sync_out(5);
    dbg_dec_q_all      <=  qdriip_cs2_sync_out(6);
    dbg_inc_cq         <=  qdriip_cs2_sync_out(7);
    dbg_inc_cqn        <=  qdriip_cs2_sync_out(8);
    dbg_inc_q          <=  qdriip_cs2_sync_out(9);
    dbg_dec_cq         <=  qdriip_cs2_sync_out(10);
    dbg_dec_cqn        <=  qdriip_cs2_sync_out(11);
    dbg_dec_q          <=  qdriip_cs2_sync_out(12);
    dbg_sel_cq         <=  qdriip_cs2_sync_out(13+CQ_BITS-1 downto 13);
    dbg_sel_cqn        <=  qdriip_cs2_sync_out(13+(2*CQ_BITS)-1 downto 13+CQ_BITS);
    dbg_sel_q          <=  qdriip_cs2_sync_out(13+(2*CQ_BITS)+Q_BITS-1  downto 13+(2*CQ_BITS));
    dbg_clear_error    <=  qdriip_cs2_sync_out(13+(2*CQ_BITS)+Q_BITS);
    dbg_pd_off         <=  qdriip_cs2_sync_out(13+(2*CQ_BITS)+Q_BITS+1);

    qdriip_trigger <= (X"00" & dbg_phy_status(7 downto 1) & cmp_err);

    qdriip_cs0_clk                  <=  clk;
    qdriip_cs0_trig                 <=  qdriip_trigger;
    qdriip_cs0_data(255 downto 231) <= (others => '0');
    qdriip_cs0_data(230 downto 229) <= dbg_phy_rd_cmd_n;
    qdriip_cs0_data(228 downto 227) <= dbg_phy_wr_cmd_n;
    qdriip_cs0_data(226 downto 155) <= dbg_phy_wr_data(71 downto 0);
    qdriip_cs0_data(154)            <= user_rd_valid0_i;
    qdriip_cs0_data(153)            <= user_rd_cmd0;
    qdriip_cs0_data(152)            <= user_wr_cmd0;
    qdriip_cs0_data(151 downto 148) <= user_rd_addr0(3 downto 0);
    qdriip_cs0_data(147 downto 144) <= user_wr_addr0(3 downto 0);
    qdriip_cs0_data(143 downto 72)  <= user_wr_data0(71 downto 0);
    qdriip_cs0_data(71 downto 0)    <= user_rd_data0_i(71 downto 0);

    qdriip_cs1_clk  <= dbg_clk_rd(0);
    qdriip_cs1_trig <= qdriip_trigger;  -- add bufr trigger

    qdriip_cs1_data(255 downto 73) <= (others => '0');
    qdriip_cs1_data(72)            <= dbg_phase(0);
    qdriip_cs1_data(71 downto 54)  <= dbg_align_rd0(17 downto 0);
    qdriip_cs1_data(53 downto 36)  <= dbg_align_fd0(17 downto 0);
    qdriip_cs1_data(35 downto 18)  <= dbg_align_rd1(17 downto 0);
    qdriip_cs1_data(17 downto 0)   <= dbg_align_fd1(17 downto 0);

    --vio outputs
    qdriip_cs2_clk                    <= clk;
    qdriip_cs2_async_in(4 downto 0)   <= dbg_cq_tapcnt(TAP_BITS-1 downto 0);
    qdriip_cs2_async_in(9 downto 5)   <= dbg_cqn_tapcnt(TAP_BITS-1 downto 0);
    qdriip_cs2_async_in(99 downto 10) <= dbg_q_tapcnt(89 downto 0);
    qdriip_cs2_async_in(255 downto 100) <= (others => '0');

    u_icon : icon
      port map(
        CONTROL0 => qdriip_cs0_control,
        CONTROL1 => qdriip_cs1_control,
        CONTROL2 => qdriip_cs2_control
        );

    u_cs0 : ila
      port map(
        CLK     => qdriip_cs0_clk,
        DATA    => qdriip_cs0_data,
        TRIG0   => qdriip_cs0_trig,
        CONTROL => qdriip_cs0_control
        );

    u_cs1 : ila
      port map(
        CLK     => qdriip_cs1_clk,
        DATA    => qdriip_cs1_data,
        TRIG0   => qdriip_cs1_trig,
        CONTROL => qdriip_cs1_control
        );

    u_cs2_asyncin256_syncout36 : vio
      port map(
        ASYNC_IN => qdriip_cs2_async_in,
        SYNC_OUT => qdriip_cs2_sync_out,
        CLK      => qdriip_cs2_clk,
        CONTROL  => qdriip_cs2_control
        );
  end generate chipscope_inst;

end architecture arch_sram_interface;
