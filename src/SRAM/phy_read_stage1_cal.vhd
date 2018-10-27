--*****************************************************************************
--// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
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

--//////////////////////////////////////////////////////////////////////////////
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : $Name:  $
--  \   \         Application        : MIG
--  /   /         Filename           : phy_read_stage1_cal.v
-- /___/   /\     Timestamp          : Dec 1, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--  This module
--  1. Center aligns the incoming Q data to the respective CQ and CQ# clocks on
--     a per bit basis.
--  2. Determines if the data from the ISERDES must be realigned.
--
--Revision History:
--
--//////////////////////////////////////////////////////////////////////////////

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_read_stage1_cal is
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
      cq_num                 : out std_logic_vector(CQ_BITS - 1 downto 0);    -- indictes which Q the control is for
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
end entity phy_read_stage1_cal;

architecture trans of phy_read_stage1_cal is
      
    -- {{{ Wire, Reg, param Declarations ----------
    function MEMORY_TYPE_FUNC return string is
    begin
      if (MEM_TYPE = "RLD2_CIO" or MEM_TYPE = "RLD2_SIO") then 
        return "RLD2";
      else
        return "QDR";
      end if;
    end function MEMORY_TYPE_FUNC;
    
    function WINDOW_FUNC return std_logic_vector is
    begin
      if (SIM_CAL_OPTION = "NONE") then 
        return "0000110000";
      else
        return "0000010000";
      end if;
    end function WINDOW_FUNC;
    
    function bool_to_std_logic ( 
      exp : boolean
    ) return std_logic is
    begin
      if (exp) then 
        return '1';
      else
        return '0';
      end if;
    end function bool_to_std_logic;
  
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
      
    function and_br ( 
      var : std_logic_vector
    ) return std_logic is
      variable tmp : std_logic := '1' ;
    begin
      for i in 0 to (var'length-1) loop
        tmp := tmp and var(i);
      end loop;
      return tmp;
    end function and_br;
    
    -- tap centering states
    constant CTR_IDLE               : std_logic_vector := "000000001";
    constant CTR_SEEK_LEFT0         : std_logic_vector := "000000010";
    constant CTR_SEEK_LEFT0_CHK     : std_logic_vector := "000000100";
    constant CTR_SEEK_RIGHT         : std_logic_vector := "000001000";
    constant CTR_SEEK_RIGHT_CHK     : std_logic_vector := "000010000";
    constant CTR_SEEK_LEFT1         : std_logic_vector := "000100000";
    constant CTR_SEEK_LEFT1_CHK     : std_logic_vector := "001000000";
    constant CTR_SEEK_LEFT1_CHK_WT  : std_logic_vector := "010000000";
    constant CTR_DONE               : std_logic_vector := "100000000";
      
    -- main calibration states
    constant CAL_IDLE               : std_logic_vector := "00000000000001";
    constant CAL_Q_RISE             : std_logic_vector := "00000000000010"; 
    constant CAL_Q_RISE_INV         : std_logic_vector := "00000000000100";
    constant CAL_DET_OPT            : std_logic_vector := "00000000001000";
    constant CAL_Q_FALL             : std_logic_vector := "00000000010000";
    constant CAL_DET_OVR            : std_logic_vector := "00000000100000";
    constant CAL_SET_OVR            : std_logic_vector := "00000001000000";
    constant CAL_QBIT_DET           : std_logic_vector := "00000010000000";
    constant CAL_QBIT_SET           : std_logic_vector := "00000100000000";
    constant CAL_ADJ_REQ            : std_logic_vector := "00001000000000";
    constant CAL_ADJ                : std_logic_vector := "00010000000000";
    constant CAL_SET_PHASE          : std_logic_vector := "00100000000000";
    constant CAL_DONE               : std_logic_vector := "01000000000000";
    constant CAL_RST_WAIT           : std_logic_vector := "10000000000000";
      
    -- configurable delays
    constant TAP_ADJ_DLY            : integer := 4;
    constant CAL_START_DLY          : integer := 60;
    constant C_NUM_RDY_DLY          : integer := 8;
    constant Q_BIT_RDY_DLY          : integer := 8;
    constant TAP_DLY                : integer := 36;
    constant LOAD_DLY               : integer := 12;
    constant RST_DLY                : integer := 36;
    constant POL_DLY                : integer := 36;
    constant MIN_WINDOW_SIZE        : integer := 3;
      
    -- Number of cycles to make sure the data window is valid. This is an
    -- averaging scheme used to make sure that the instable regions at the
    -- edges of windows do not cause false positives. This can be adjusted
    -- higher to sample over a larger window.
    --constant WINDOW_VLD_STABLE_CNT  : std_logic_vector := "0000010000";
    constant WINDOW_VLD_STABLE_CNT  : std_logic_vector := WINDOW_FUNC;
      
    -- Parameter that is used to force subsequent data bits to look for the same
    -- window that the first bit in the memory used.
    constant LEFT0_SAME_WINDOW      : integer := 7;
      
    --constant MEMORY_TYPE            : string    := MEMORY_TYPE_FUNC;
    constant MEMORY_TYPE            : string    := "RLD2"; 
    constant MEM_TYPE_RLD           : std_logic := bool_to_std_logic(MEMORY_TYPE = "RLD2");
    
    type type_cnum_d is array (NUM_DEVICES - 1 downto 0) of std_logic_vector(MEMORY_WIDTH - 1 downto 0);
  
   -- capture calibration data
   signal rise_data0_r            : std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal fall_data0_r            : std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal rise_data1_r            : std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal fall_data1_r            : std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal rd0                     : std_logic;
   signal fd0                     : std_logic;
   signal rd1                     : std_logic;
   signal fd1                     : std_logic;
   signal rd0_r                   : std_logic;
   signal fd0_r                   : std_logic;
   signal rd1_r                   : std_logic;
   signal fd1_r                   : std_logic;
   signal sample                  : std_logic;
   signal rd_window               : std_logic_vector(3 downto 0);
   signal d_window                : std_logic_vector(7 downto 0);
   signal rd_valid_d              : std_logic;
   signal rd_valid                : std_logic;
   signal fd_window               : std_logic_vector(3 downto 0);
   signal fd_valid_d              : std_logic;
   signal fd_valid                : std_logic;
   signal window_vld              : std_logic;
   signal opp_window_vld          : std_logic;
   
   -- tap centering
   signal data_rdy                : std_logic;
   signal data_rdy_r              : std_logic;
   signal start_stable_cnt        : std_logic;
   signal stable_cnt              : std_logic_vector(9 downto 0);
   signal window_vld_stable       : std_logic;
   signal en_vld_check            : std_logic;
   signal stable_cnt_0            : std_logic;
   signal stable_cnt_0_r          : std_logic;
   signal data_stable             : std_logic;
   signal data_stable_r           : std_logic;
   signal init_done_r1            : std_logic;
   signal init_done_r2            : std_logic;
   signal en_data_cap             : std_logic;
   signal en_tap_adj_tmp          : std_logic_vector(TAP_ADJ_DLY downto 0);
   signal en_tap_adj              : std_logic;
   signal en_rise_tap             : std_logic;
   signal en_fall_tap             : std_logic;
   signal cq_dly_tap              : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cqn_dly_tap             : std_logic_vector(TAP_BITS - 1 downto 0);
   signal q_dly_tap               : std_logic_vector(TAP_BITS - 1 downto 0);
   signal c_tap_max               : std_logic;
   signal c_tap_max_int           : std_logic;
   signal q_tap_max               : std_logic;
   signal q_tap_max_int           : std_logic;
   signal tap_ctr_ns              : std_logic_vector(8 downto 0);
   signal tap_ctr_cs              : std_logic_vector(8 downto 0);
   signal save_left0_tap          : std_logic;
   signal save_right_tap          : std_logic;
   signal save_left1_tap          : std_logic;
   signal save_found_left0        : std_logic;
   signal save_found_right        : std_logic;
   signal save_found_left1        : std_logic;
   signal save_cdt_max            : std_logic;
   signal save_qdt_max            : std_logic;
   signal save_opp_first          : std_logic;
   signal save_done               : std_logic;
   signal issue_cdt_rst_d         : std_logic;
   signal issue_cdt_rst           : std_logic;
   signal save_start_left0_d      : std_logic;
   signal save_start_left0        : std_logic;
   signal ignore_first_right      : std_logic;
   signal qmem0_start_left0       : std_logic;
   signal qmem0_left0_tap         : std_logic_vector(TAP_BITS - 1 downto 0);
   signal ctr_seek_st             : std_logic;
   signal ctr_c_dly_st            : std_logic;
   signal ctr_q_dly_st            : std_logic;
   signal left0_tap               : std_logic_vector(TAP_BITS - 1 downto 0);
   signal right_tap               : std_logic_vector(TAP_BITS - 1 downto 0);
   signal left1_tap               : std_logic_vector(TAP_BITS - 1 downto 0);
   signal found_left0             : std_logic;
   signal found_right             : std_logic;
   signal found_left1             : std_logic;
   signal cdt_max                 : std_logic;
   signal qdt_max                 : std_logic;
   signal opp_first               : std_logic;
   signal ctr_done_pre            : std_logic;
   signal ctr_done_sig            : std_logic;
   signal q0mem_left0_tap         : std_logic_vector(4 downto 0);
   signal q0mem_right_tap         : std_logic_vector(4 downto 0);
   signal q0mem_left1_tap         : std_logic_vector(4 downto 0);
   signal q0mem_found_left0       : std_logic;
   signal q0mem_found_right       : std_logic;
   signal q0mem_found_left1       : std_logic;
   signal q0mem_cdt_max           : std_logic;
   signal q0mem_qdt_max           : std_logic;
   signal q0mem_opp_first         : std_logic;
   signal q0mem_start_left0       : std_logic;
   signal start_left0             : std_logic;
   signal clpct_lte_dt            : std_logic;   
   signal left0_gr_ctr            : std_logic;
   signal cr_gt_ql                : std_logic;
   signal ct_lte_dtpcr            : std_logic;
   signal left0_plus_right        : std_logic_vector(TAP_BITS downto 0);
   signal left0_plus_center       : std_logic_vector(TAP_BITS downto 0);
   signal right_plus_maxt         : std_logic_vector(TAP_BITS downto 0);
   signal right_minus_left1       : std_logic_vector(TAP_BITS - 1 downto 0);
   signal left1_minus_right       : std_logic_vector(TAP_BITS - 1 downto 0);
   signal ct_minus_left1          : std_logic_vector(TAP_BITS downto 0);
   signal cdt_selected_d          : std_logic;
   signal optimal_tap_d           : std_logic_vector(TAP_BITS - 1 downto 0);
   signal tap_offset_d            : std_logic_vector(TAP_BITS - 1 downto 0);
   signal true_center_d           : std_logic;
   signal try_clk_inv_d           : std_logic;
   signal window_size_d           : std_logic_vector(TAP_BITS downto 0);
   signal cdt_selected            : std_logic;
   signal optimal_tap             : std_logic_vector(TAP_BITS - 1 downto 0);
   signal tap_offset              : std_logic_vector(TAP_BITS - 1 downto 0);
   signal true_center             : std_logic;
   signal try_clk_inv             : std_logic;
   signal window_size             : std_logic_vector(TAP_BITS downto 0);
   
   -- overall calibration control
   signal cal_sm_start_tmp        : std_logic_vector(CAL_START_DLY downto 0) := (others => '0');
   signal cal_sm_start            : std_logic;
   signal q_mem_0                 : std_logic;
   signal q_bit_max               : std_logic;
   signal q_mem_max               : std_logic;
   signal cal_cs                  : std_logic_vector(13 downto 0);
   signal cal_ns                  : std_logic_vector(13 downto 0);
   signal start_ctr_cal_int       : std_logic;
   signal start_in_progress       : std_logic;
   signal cal_rise                : std_logic;
   signal save_rise_edge          : std_logic;
   signal save_rise_edge_inv      : std_logic;
   signal save_fall_edge          : std_logic;
   signal save_current            : std_logic;
   signal force_clk_invert        : std_logic;
   signal clear_clk_invert        : std_logic;
   signal issue_dly_rst_d         : std_logic;
   signal issue_dly_rst           : std_logic;
   signal issue_load_c            : std_logic;
   signal issue_load_q            : std_logic;
   signal inc_q                   : std_logic;
   signal inc_cq                  : std_logic;
   signal next_q_grp              : std_logic;
   signal start_ctr_cal_d         : std_logic;
   signal cal_rise_d              : std_logic;
   signal save_rise_edge_d        : std_logic;
   signal save_rise_edge_inv_d    : std_logic;
   signal save_fall_edge_d        : std_logic;
   signal save_current_d          : std_logic;
   signal force_clk_invert_d      : std_logic;
   signal set_clk_polarity        : std_logic;
   signal issue_load_c_d          : std_logic;
   signal issue_load_q_d          : std_logic;
   signal inc_q_d                 : std_logic;
   signal inc_cq_d                : std_logic;
   signal next_q_grp_d            : std_logic;
   signal save_target_q           : std_logic;
   signal clr_q                   : std_logic;
   signal load_init               : std_logic;
   signal capture_adj             : std_logic;
   signal start_adj               : std_logic;
   signal start_ctr_cal_int_r     : std_logic;
   signal start_ctr_cal_int_2r    : std_logic;
   signal start_ctr_cal           : std_logic;
   signal start_ctr_cal_hold      : std_logic;
   signal start_ctr_cal_rdy       : std_logic;
   signal re_cdt_selected         : std_logic;
   signal re_optimal_tap          : std_logic_vector(TAP_BITS - 1 downto 0);
   signal re_tap_offset           : std_logic_vector(TAP_BITS - 1 downto 0);
   signal re_true_center          : std_logic;
   signal re_captured             : std_logic;
   signal re_start_left0          : std_logic;
   signal re_left0_tap            : std_logic_vector(TAP_BITS - 1 downto 0);
   signal re_window_size0         : std_logic;
   signal re_qmem0_left0_tap      : std_logic_vector(4 downto 0);
   signal re_qmem0_right_tap      : std_logic_vector(4 downto 0);
   signal re_qmem0_left1_tap      : std_logic_vector(4 downto 0);
   signal re_qmem0_found_left0    : std_logic;
   signal re_qmem0_found_right    : std_logic;
   signal re_qmem0_found_left1    : std_logic;
   signal re_qmem0_cdt_max        : std_logic;
   signal re_qmem0_qdt_max        : std_logic;
   signal re_qmem0_opp_first      : std_logic;
   signal re_qmem0_start_left0    : std_logic;
   signal rei_cdt_selected        : std_logic;
   signal rei_optimal_tap         : std_logic_vector(TAP_BITS - 1 downto 0);
   signal rei_true_center         : std_logic;
   signal rei_captured            : std_logic;
   signal rei_start_left0         : std_logic;
   signal rei_left0_tap           : std_logic_vector(TAP_BITS - 1 downto 0);
   signal rei_window_size0        : std_logic;
   signal rei_qmem0_left0_tap     : std_logic_vector(4 downto 0);
   signal rei_qmem0_right_tap     : std_logic_vector(4 downto 0);
   signal rei_qmem0_left1_tap     : std_logic_vector(4 downto 0);
   signal rei_qmem0_found_left0   : std_logic;
   signal rei_qmem0_found_right   : std_logic;
   signal rei_qmem0_found_left1   : std_logic;
   signal rei_qmem0_cdt_max       : std_logic;
   signal rei_qmem0_qdt_max       : std_logic;
   signal rei_qmem0_opp_first     : std_logic;
   signal rei_qmem0_start_left0   : std_logic;
   signal fe_cdt_selected         : std_logic;
   signal fe_optimal_tap          : std_logic_vector(TAP_BITS - 1 downto 0);
   signal fe_captured             : std_logic;
   signal curr_cdt_selected       : std_logic;
   signal curr_optimal_tap        : std_logic_vector(TAP_BITS - 1 downto 0);
   signal curr_captured           : std_logic;
   
   -- determine optimal q0 tap setting
   signal tap_offset0             : std_logic;
   signal re_tap_off0             : std_logic;
   signal rei_tap_off0            : std_logic;
   signal re_better_tap_off       : std_logic;
   signal invert_clk_d            : std_logic;
   signal rise_cdt_delayed_d      : std_logic;
   signal det_opt_done_d          : std_logic;
   signal det_opt_setting_d       : std_logic_vector(3 downto 0);
   signal invert_clk              : std_logic;
   signal rise_cdt_delayed        : std_logic;
   signal det_opt_done            : std_logic;
   signal det_opt_setting         : std_logic_vector(3 downto 0);
   
   -- set overall q0 tap setting
   signal rise_optimal_tap        : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cq_qdly_larger          : std_logic;
   signal fe_captured_r           : std_logic;
   signal cq_num_load_val_d       : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cqn_num_load_val_d      : std_logic_vector(TAP_BITS - 1 downto 0);
   signal q_bit_load_val_d        : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cq_num_load_val         : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cqn_num_load_val        : std_logic_vector(TAP_BITS - 1 downto 0);
   signal q_bit_load_val          : std_logic_vector(TAP_BITS - 1 downto 0);
   signal det_ovr_done            : std_logic;
   signal set_ovr_st              : std_logic;
   signal set_ovr_done            : std_logic;
   
   -- determine q_bit tap settings
   signal new_cdt_larger          : std_logic;
   signal curr_minus_cq           : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cqn_plus_curr_minus_cq  : std_logic_vector(TAP_BITS downto 0);
   signal cqn_tap_overflow        : std_logic;
   signal q_tap_overflow          : std_logic;
   signal cq_plus_curr            : std_logic_vector(TAP_BITS downto 0);
   signal prev_q_adj_d            : std_logic_vector(TAP_BITS - 1 downto 0);
   signal q_tap_d                 : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cq_tap_d                : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cqn_tap_d               : std_logic_vector(TAP_BITS - 1 downto 0);
   signal prev_adj_req_d          : std_logic;
   signal prev_q_adj              : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cap_prev_adj_req        : std_logic;
   signal prev_adj_req            : std_logic;
   signal cq_tap                  : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cqn_tap                 : std_logic_vector(TAP_BITS - 1 downto 0);
   signal q_tap                   : std_logic_vector(TAP_BITS - 1 downto 0);
   signal qbit_det_done           : std_logic;
   
   -- set q_bit tap settings
   signal qbit_set_st             : std_logic;
   signal qbit_set_done           : std_logic;
   signal target_q                : std_logic_vector(Q_BITS - 1 downto 0);
   signal q_adj_val               : std_logic_vector(TAP_BITS - 1 downto 0);
   signal q_bit_adj_done          : std_logic;
   signal adjust_q                : std_logic;
   signal all_q_adj               : std_logic;
   
   -- phase alignment
   signal cnum_rise_data0         : type_cnum_d;
   signal cnum_fall_data0         : type_cnum_d;
   signal cnum_rise_data1         : type_cnum_d;
   signal cnum_fall_data1         : type_cnum_d;
   signal cnum_rd0                : std_logic_vector(MEMORY_WIDTH - 1 downto 0);
   signal cnum_fd0                : std_logic_vector(MEMORY_WIDTH - 1 downto 0);
   signal cnum_rd1                : std_logic_vector(MEMORY_WIDTH - 1 downto 0);
   signal cnum_fd1                : std_logic_vector(MEMORY_WIDTH - 1 downto 0);
   signal phase0_mw_vld           : std_logic_vector(MEMORY_WIDTH - 1 downto 0);
   signal phase1_mw_vld           : std_logic_vector(MEMORY_WIDTH - 1 downto 0);
   signal phase0_data_vld0        : std_logic;
   signal phase1_data_vld0        : std_logic;
   signal phase0_data_vld1        : std_logic;
   signal phase1_data_vld1        : std_logic;
   signal phase0_data_vld         : std_logic;
   signal phase1_data_vld         : std_logic;
   signal phase1_vld              : std_logic;
   signal phase0_vld              : std_logic;
   signal phase_error             : std_logic;
   
   -- idelay/iserdes control
   signal q_mem                   : std_logic_vector(Q_BITS - 1 downto 0);
   signal c_num_done_tmp          : std_logic_vector(C_NUM_RDY_DLY downto 0);
   signal c_num_done_int          : std_logic;
   signal c_num_done              : std_logic;
   signal c_num_rdy               : std_logic;
   signal q_bit_changed           : std_logic;
   signal q_bit_done_tmp          : std_logic_vector(Q_BIT_RDY_DLY downto 0);
   signal q_bit_done_int          : std_logic;
   signal q_bit_done              : std_logic;
   signal q_bit_rdy               : std_logic;
   signal cq_tap_done_tmp         : std_logic_vector(TAP_DLY downto 0) := (others => '0');
   signal cq_tap_done_int         : std_logic;
   signal cq_tap_done             : std_logic;
   signal cqn_tap_done_tmp        : std_logic_vector(TAP_DLY downto 0) := (others => '0');
   signal cqn_tap_done_int        : std_logic;
   signal cqn_tap_done            : std_logic;
   signal q_tap_done_tmp          : std_logic_vector(TAP_DLY downto 0);
   signal q_tap_done_int          : std_logic;
   signal q_tap_done              : std_logic;
   signal tap_done                : std_logic;
   signal load_c_changed          : std_logic;
   signal load_c_tmp              : std_logic_vector(LOAD_DLY downto 0);
   signal load_c                  : std_logic;
   signal load_c_fall             : std_logic;
   signal load_c_done             : std_logic;
   signal load_q_changed          : std_logic;
   signal load_q_tmp              : std_logic_vector(LOAD_DLY downto 0) := (others => '0');
   signal load_q                  : std_logic;
   signal load_q_fall             : std_logic;
   signal load_q_done             : std_logic;
   signal load_done               : std_logic;
   signal cq_rst_changed          : std_logic;
   signal cq_rst_done_tmp         : std_logic_vector(RST_DLY downto 0) := (others => '0');
   signal cq_rst_done_int         : std_logic;
   signal outstanding_cq_rst      : std_logic_vector(3 downto 0);
   signal cq_rst_done             : std_logic;
   signal q_rst_changed           : std_logic;
   signal q_rst_done_tmp          : std_logic_vector(RST_DLY downto 0) := (others => '0');
   signal q_rst_done_int          : std_logic;
   signal outstanding_q_rst       : std_logic_vector(3 downto 0);
   signal q_rst_done              : std_logic;
   signal rst_done                : std_logic;
   signal clear_clk_invert_r      : std_logic;
   signal clear_clk_invert_2r     : std_logic;
   signal clear_clk_invert_3r     : std_logic;
   signal polarity_changed        : std_logic;
   signal polarity_done_tmp       : std_logic_vector(POL_DLY downto 0);
   signal polarity_done_int       : std_logic;
   signal polarity_done           : std_logic;
   
   
   -- Internal signals
   signal wv_rld              : std_logic;
   signal opp_wv_rld          : std_logic;
   signal wv_cal_rise         : std_logic;
   signal opp_wv_cal_rise     : std_logic;
   signal wv_other            : std_logic;
   signal opp_wv_other        : std_logic;
   signal cq_dly_tap_inc      : std_logic_vector(4 downto 0);
   signal cqn_dly_tap_inc     : std_logic_vector(4 downto 0);
   signal q_dly_tap_inc       : std_logic_vector(4 downto 0);
   signal ctr_done_next       : std_logic_vector(8 downto 0);
   signal left0_tap_d         : std_logic_vector(4 downto 0);
   signal right_tap_d         : std_logic_vector(4 downto 0);
   signal left1_tap_d         : std_logic_vector(4 downto 0);
   signal q0mem_left0_tap_d   : std_logic_vector(4 downto 0);
   signal q0mem_right_tap_d   : std_logic_vector(4 downto 0);
   signal q0mem_left1_tap_d   : std_logic_vector(4 downto 0);
   signal set_phase_next_none : std_logic_vector(13 downto 0);
   signal set_phase_next_fast : std_logic_vector(13 downto 0);
   signal qmem0_start_left0_d : std_logic;
   signal qmem0_left0_tap_d   : std_logic_vector(4 downto 0);
   signal cqn_tap_d_sel       : std_logic_vector(4 downto 0);
   signal q_tap_d_sel         : std_logic_vector(4 downto 0);
   signal q_mem_sel           : std_logic_vector(Q_BITS-1 downto 0);
   signal ctr_idle_rdy        : std_logic;

   -- Declare intermediate signals for referenced outputs
   signal cal_stage1_start_sig  : std_logic;
   signal cq_num_sig            : std_logic_vector(CQ_BITS - 1 downto 0);
   signal q_bit_sig             : std_logic_vector(Q_BITS - 1 downto 0);
   signal cq_num_load_sig       : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cqn_num_load_sig      : std_logic_vector(TAP_BITS - 1 downto 0);
   signal q_bit_load_sig        : std_logic_vector(TAP_BITS - 1 downto 0);
   signal cq_num_rst_sig        : std_logic;
   signal cq_num_ce_sig         : std_logic;
   signal cqn_num_rst_sig       : std_logic;
   signal cqn_num_ce_sig        : std_logic;
   signal q_bit_rst_sig         : std_logic;
   signal q_bit_ce_sig          : std_logic;
   signal q_bit_clkinv_sig      : std_logic;


   -- concatination for case statements
   signal data_cap_wv_stable : std_logic_vector(1 downto 0);
   signal data_cap_wv_stable_max : std_logic_vector(2 downto 0);
   signal tap_settings_case : std_logic_vector(9 downto 0);
   signal ctr_idle_case       : std_logic_vector(1 downto 0); 
   signal ctr_seek_left0_case : std_logic_vector(2 downto 0);
   signal ctr_seek_right_case : std_logic_vector(4 downto 0);
   signal ctr_seek_left1_case : std_logic_vector(2 downto 0);
   signal cal_q_rise_case : std_logic_vector(3 downto 0);
   signal cal_qbit_det_case : std_logic_vector(1 downto 0);
   signal cal_qbit_set_case : std_logic_vector(4 downto 0);
   signal cal_adj_req_case : std_logic_vector(5 downto 0);
   signal sel_best_taps_case : std_logic_vector(8 downto 0);
   signal adj_case : std_logic_vector(3 downto 0);
   signal new_cdt_case : std_logic_vector(1 downto 0);
   signal min_window_cnt : unsigned(4 downto 0);
   signal phase_sig      : std_logic_vector(NUM_DEVICES - 1 downto 0);

 begin
   -- Drive referenced outputs
   cal_stage1_start  <= cal_stage1_start_sig;
   cq_num            <= cq_num_sig;
   q_bit             <= q_bit_sig;
   cq_num_load       <= cq_num_load_sig;
   cqn_num_load      <= cqn_num_load_sig;
   q_bit_load        <= q_bit_load_sig;
   cq_num_rst        <= cq_num_rst_sig;
   cq_num_ce         <= cq_num_ce_sig;
   cqn_num_rst       <= cqn_num_rst_sig;
   cqn_num_ce        <= cqn_num_ce_sig;
   q_bit_rst         <= q_bit_rst_sig;
   q_bit_ce          <= q_bit_ce_sig;
   q_bit_clkinv      <= q_bit_clkinv_sig;  
  
   -- Chipscope debug signals  
   dbg_rd_stage1_cal(255 downto 217)   <= (others => '0');
   dbg_rd_stage1_cal(216)              <= rst_done;
   dbg_rd_stage1_cal(215)              <= init_done;
   dbg_rd_stage1_cal(214)              <= cal_sm_start;
   dbg_rd_stage1_cal(213 downto 209)   <= curr_optimal_tap;
   dbg_rd_stage1_cal(208)              <= new_cdt_larger;
   dbg_rd_stage1_cal(207)              <= curr_cdt_selected;
   dbg_rd_stage1_cal(206 downto 202)   <= rei_qmem0_left0_tap;
   dbg_rd_stage1_cal(201 downto 197)   <= rei_qmem0_right_tap;
   dbg_rd_stage1_cal(196 downto 192)   <= rei_qmem0_left1_tap;
   dbg_rd_stage1_cal(191)              <= rei_qmem0_found_left0;
   dbg_rd_stage1_cal(190)              <= rei_qmem0_found_right;
   dbg_rd_stage1_cal(189)              <= rei_qmem0_found_left1;
   dbg_rd_stage1_cal(188)              <= rei_qmem0_cdt_max;
   dbg_rd_stage1_cal(187)              <= rei_qmem0_qdt_max;
   dbg_rd_stage1_cal(186)              <= rei_qmem0_opp_first;
   dbg_rd_stage1_cal(185)              <= rei_qmem0_start_left0;
   dbg_rd_stage1_cal(184 downto 180)   <= re_qmem0_left0_tap;
   dbg_rd_stage1_cal(179 downto 175)   <= re_qmem0_right_tap;
   dbg_rd_stage1_cal(174 downto 170)   <= re_qmem0_left1_tap;
   dbg_rd_stage1_cal(169)              <= re_qmem0_found_left0;
   dbg_rd_stage1_cal(168)              <= re_qmem0_found_right;
   dbg_rd_stage1_cal(167)              <= re_qmem0_found_left1;
   dbg_rd_stage1_cal(166)              <= re_qmem0_cdt_max;
   dbg_rd_stage1_cal(165)              <= re_qmem0_qdt_max;
   dbg_rd_stage1_cal(164)              <= re_qmem0_opp_first;
   dbg_rd_stage1_cal(163)              <= re_qmem0_start_left0;
   dbg_rd_stage1_cal(162 downto 158)   <= optimal_tap;
   dbg_rd_stage1_cal(157 downto 154)   <= det_opt_setting;
   dbg_rd_stage1_cal(153 downto 148)   <= window_size;
   dbg_rd_stage1_cal(147)              <= q_bit_rst_sig;
   dbg_rd_stage1_cal(146 downto 142)   <= q_bit_load_sig;
   dbg_rd_stage1_cal(141)              <= cqn_num_rst_sig;
   dbg_rd_stage1_cal(140 downto 136)   <= cqn_num_load_sig;
   dbg_rd_stage1_cal(135)              <= cq_num_rst_sig;
   dbg_rd_stage1_cal(134 downto 130)   <= cq_num_load_sig;
   dbg_rd_stage1_cal(129)              <= load_done;
   dbg_rd_stage1_cal(128)              <= tap_done;
   dbg_rd_stage1_cal(127)              <= q_bit_ce_sig;
   dbg_rd_stage1_cal(126)              <= cqn_num_ce_sig;
   dbg_rd_stage1_cal(125)              <= cq_num_ce_sig;
   dbg_rd_stage1_cal(124)              <= q_bit_rdy;
   dbg_rd_stage1_cal(123)              <= c_num_rdy;
   dbg_rd_stage1_cal(122)              <= phase_error;
   dbg_rd_stage1_cal(121)              <= phase1_data_vld;
   dbg_rd_stage1_cal(120)              <= phase0_data_vld;
   dbg_rd_stage1_cal(119)              <= q_bit_adj_done;
   dbg_rd_stage1_cal(118 downto 114)   <= q_adj_val;
   dbg_rd_stage1_cal(113 downto 109)   <= prev_q_adj;
   dbg_rd_stage1_cal(108)              <= prev_adj_req;
   dbg_rd_stage1_cal(107)              <= load_init;
   dbg_rd_stage1_cal(106)              <= capture_adj;
   dbg_rd_stage1_cal(105 downto 101)   <= q_tap;
   dbg_rd_stage1_cal(100 downto 96)    <= cqn_tap;
   dbg_rd_stage1_cal(95 downto 91)     <= cq_tap;
   dbg_rd_stage1_cal(90)               <= rise_cdt_delayed;
   dbg_rd_stage1_cal(89)               <= invert_clk;
   dbg_rd_stage1_cal(88)               <= re_cdt_selected;
   dbg_rd_stage1_cal(87 downto 83)     <= re_optimal_tap;
   dbg_rd_stage1_cal(82 downto 78)     <= right_tap;
   dbg_rd_stage1_cal(77 downto 73)     <= left1_tap;
   dbg_rd_stage1_cal(72 downto 68)     <= left0_tap;
   dbg_rd_stage1_cal(67)               <= cal_rise;
   dbg_rd_stage1_cal(66)               <= polarity_done;
   dbg_rd_stage1_cal(65)               <= q_bit_clkinv_sig;
   dbg_rd_stage1_cal(64)               <= fe_cdt_selected;
   dbg_rd_stage1_cal(63)               <= rei_cdt_selected;
   dbg_rd_stage1_cal(62 downto 58)     <= fe_optimal_tap;
   dbg_rd_stage1_cal(57 downto 53)     <= rei_optimal_tap;
   dbg_rd_stage1_cal(52)               <= qbit_set_done;
   dbg_rd_stage1_cal(51)               <= qbit_det_done;
   dbg_rd_stage1_cal(50)               <= det_ovr_done;
   dbg_rd_stage1_cal(49)               <= det_opt_done;
   dbg_rd_stage1_cal(48)               <= fe_captured;
   dbg_rd_stage1_cal(47)               <= re_captured;
   dbg_rd_stage1_cal(46)               <= q_mem_0;
   dbg_rd_stage1_cal(45)               <= ctr_done_sig;
   dbg_rd_stage1_cal(44)               <= cdt_selected;
   dbg_rd_stage1_cal(43)               <= rei_captured;
   dbg_rd_stage1_cal(42)               <= tap_offset(0);
   dbg_rd_stage1_cal(41)               <= try_clk_inv;
   dbg_rd_stage1_cal(40)               <= found_right;
   dbg_rd_stage1_cal(39)               <= found_left1;
   dbg_rd_stage1_cal(38)               <= found_left0;
   dbg_rd_stage1_cal(37)               <= en_tap_adj;
   dbg_rd_stage1_cal(36)               <= data_rdy;
   dbg_rd_stage1_cal(35)               <= opp_window_vld;
   dbg_rd_stage1_cal(34)               <= window_vld;
   dbg_rd_stage1_cal(33 downto 29)     <= q_dly_tap;
   dbg_rd_stage1_cal(28 downto 24)     <= cqn_dly_tap;
   dbg_rd_stage1_cal(23 downto 19)     <= cq_dly_tap;
   dbg_rd_stage1_cal(18 downto 5)      <= cal_cs;
   dbg_rd_stage1_cal(4 downto 0)       <= tap_ctr_cs(4 downto 0);
   
   -- {{{ Capture Calibration Data ---------------
   
   -- Infer a mux that such that the calibration logic only operates on the data
   -- from one bit at a time. Register the inputs since timing will be tight for
   -- wider interfaces.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            rise_data0_r <= (others =>'0') after TCQ*1 ps;
            fall_data0_r <= (others =>'0') after TCQ*1 ps;
            rise_data1_r <= (others =>'0') after TCQ*1 ps;
            fall_data1_r <= (others =>'0') after TCQ*1 ps;
         else
            rise_data0_r <= rise_data0 after TCQ*1 ps;
            fall_data0_r <= fall_data0 after TCQ*1 ps;
            rise_data1_r <= rise_data1 after TCQ*1 ps;
            fall_data1_r <= fall_data1 after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            rd0 <= '0' after TCQ*1 ps;
            fd0 <= '0' after TCQ*1 ps;
            rd1 <= '0' after TCQ*1 ps;
            fd1 <= '0' after TCQ*1 ps;
         else
            rd0 <= rise_data0_r(to_integer(unsigned(q_bit_sig))) after TCQ*1 ps;
            fd0 <= fall_data0_r(to_integer(unsigned(q_bit_sig))) after TCQ*1 ps;
            rd1 <= rise_data1_r(to_integer(unsigned(q_bit_sig))) after TCQ*1 ps;
            fd1 <= fall_data1_r(to_integer(unsigned(q_bit_sig))) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Register data again to allow data to be looked at across two cycles which
   -- is necessary since the training sequence is 8 words (4 rising and 4
   -- falling).
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            rd0_r <= '0' after TCQ*1 ps;
            fd0_r <= '0' after TCQ*1 ps;
            rd1_r <= '0' after TCQ*1 ps;
            fd1_r <= '0' after TCQ*1 ps;
         else
            rd0_r <= rd0 after TCQ*1 ps;
            fd0_r <= fd0 after TCQ*1 ps;
            rd1_r <= rd1 after TCQ*1 ps;
            fd1_r <= fd1 after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Create a signal that toggles which will be used as an indicator to sample
   -- the data on every other cycle. This is necessary since the training
   -- sequence must be evaluated over two cycles.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            sample <= '0' after TCQ*1 ps;
         else
            sample <= not(sample) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Rising edge valid data will ideally be 0100 over two cycles. However, 
   -- depending on how the sample signal aligns with the incoming data in
   -- addition to the phase alignment in the ISERDES, it coult be 1000, 0100,
   -- 0010, or 0001.
   rd_window <= (rd0 & rd1 & rd0_r & rd1_r);
   
   d_window <= (rd_window & fd_window);
   
   -- Note this was done in an always to avoid X propagation from the IDELAY
   -- data that occurs when the clock is moved outside of the data window.
   -- For RLDRAM, the entire data window is looked at since there are no 
   --separate rise and fall clocks
   process (d_window, rd_window)
   begin
      if ((MEMORY_TYPE = "RLD2") and ((d_window = "10000111")
          or (d_window = "01001011") or (d_window = "00101101") or 
          (d_window = "00011110"))) then
         rd_valid_d <= '1';
      elsif ((MEMORY_TYPE = "QDR") and ((rd_window = "1000") or
             (rd_window = "0100") or (rd_window = "0010") or 
             (rd_window = "0001"))) then
         rd_valid_d <= '1';
      else
         rd_valid_d <= '0';
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            rd_valid <= '0' after TCQ*1 ps;
         elsif (sample = '1') then
            rd_valid <= rd_valid_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Falling edge valid data will ideally be 1011 over two cycles. However, 
   -- depending on how the sample signal aligns with the incoming data in
   -- addition to the phase alignment in the ISERDES, it coult be 0111, 1011,
   -- 1101, or 1110.
   fd_window <= (fd0 & fd1 & fd0_r & fd1_r);
   
   -- Note this was done in an always to avoid X propagation from the IDELAY
   -- data that occurs when the clock is moved outside of the data window.
   -- For RLDRAM, the entire data window is looked at since there are no 
   -- separate rise and fall clocks
   process (d_window, fd_window)
   begin
      if ((MEMORY_TYPE = "RLD2") and ((d_window = "01111000") or 
          (d_window = "10110100") or (d_window = "11010010") or 
          (d_window = "11100001"))) then
         fd_valid_d <= '1';
      elsif ((MEMORY_TYPE = "QDR") and ((fd_window = "0111") or
             (fd_window = "1011") or (fd_window = "1101") or 
             (fd_window = "1110"))) then
         fd_valid_d <= '1';
      else
         fd_valid_d <= '0';
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            fd_valid <= '0' after TCQ*1 ps;
         elsif (sample = '1') then
            fd_valid <= fd_valid_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate if data being capture is valid for the target window and/or for
   -- the other window. Note that when the ISERDES clock inversion is used, 
   -- calibrating CQ actually causes it to clock the falling edge data and
   -- CQ# to clock the rising edge data.
   wv_rld            <= rd_valid when (cal_rise = '1') else
                        fd_valid;
   opp_wv_rld        <= fd_valid when (cal_rise = '1') else
                        rd_valid;
   wv_cal_rise       <= fd_valid when (q_bit_clkinv_sig = '1') else
                        rd_valid;
   opp_wv_cal_rise   <= rd_valid when (q_bit_clkinv_sig = '1') else
                        fd_valid;
   wv_other          <= rd_valid when (q_bit_clkinv_sig = '1') else
                        fd_valid;
   opp_wv_other      <= fd_valid when (q_bit_clkinv_sig = '1') else
                        rd_valid;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            window_vld     <= '0' after TCQ*1 ps;
            opp_window_vld <= '0' after TCQ*1 ps;
         elsif (MEMORY_TYPE = "RLD2") then
            window_vld     <= (wv_rld) after TCQ*1 ps;
            opp_window_vld <= (opp_wv_rld) after TCQ*1 ps;
         elsif (cal_rise = '1') then
            window_vld     <= (wv_cal_rise) after TCQ*1 ps;
            opp_window_vld <= (opp_wv_cal_rise) after TCQ*1 ps;
         else
            window_vld     <= (wv_other) after TCQ*1 ps;
            opp_window_vld <= (opp_wv_other) after TCQ*1 ps;
         end if;
      end if;
   end process;
   -- }}} end Capture Calibration Data -----------
   
   -- {{{ Tap Centering --------------------------
  
   -- Indicate when the tap center should begin.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            ctr_idle_rdy <= '0' after TCQ*1 ps;
          elsif ((tap_ctr_cs = CTR_IDLE) and (start_ctr_cal_rdy = '1')) then
            ctr_idle_rdy <= '1' after TCQ*1 ps;
          elsif (tap_ctr_cs = CTR_DONE) then
            ctr_idle_rdy <= '0' after TCQ*1 ps;
         end if;
      end if;
   end process;

   -- Data is captured following a tap adjustment, a reset, or a change in
   -- iserdes clk polarity. It is enabled once all have been adjusted (i.e.
   -- looks for rising edge). The rising edge is necessary since the done
   -- signals will not immediately deassert following an adjustment at this
   -- stage.
   data_rdy <= cq_tap_done and cqn_tap_done and q_tap_done and rst_done 
               and polarity_done and ctr_idle_rdy and 
               not(issue_cdt_rst_d) and not(issue_cdt_rst) and 
               not(issue_dly_rst_d) and not(issue_dly_rst) and data_stable;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            data_rdy_r <= '0' after TCQ*1 ps;
         else
            data_rdy_r <= data_rdy after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate that the window can begin being checked after changes have
   -- stabilized.
   start_stable_cnt <= data_rdy and not(data_rdy_r);
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            en_vld_check <= '0' after TCQ*1 ps;
         elsif (start_stable_cnt = '1') then
             en_vld_check <= '1' after TCQ*1 ps;
         elsif ( (stable_cnt = "0000000001") or (data_stable = '0')) then
            en_vld_check <= '0' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- To avoid regions of instability around window edges, look at window_vld
   -- over multiple cycles. Only consider the window valid if it is stable
   -- and valid over WINDOW_VLD_STABLE_CNT number of cycles.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            stable_cnt        <= WINDOW_VLD_STABLE_CNT after TCQ*1 ps;
            window_vld_stable <= '0' after TCQ*1 ps;
         elsif (start_stable_cnt = '1') then
            stable_cnt        <= WINDOW_VLD_STABLE_CNT after TCQ*1 ps;
            window_vld_stable <= window_vld after TCQ*1 ps;
         elsif (stable_cnt = "0000000000") then
            stable_cnt        <= (others =>'0') after TCQ*1 ps;
            window_vld_stable <= window_vld_stable after TCQ*1 ps;
         elsif ((not(window_vld)) = '1' and en_vld_check = '1') then
            stable_cnt        <= (others =>'0') after TCQ*1 ps;
            window_vld_stable <= '0' after TCQ*1 ps;
         elsif (en_vld_check = '1') then
            stable_cnt        <= stable_cnt - "0000000001" after TCQ*1 ps;
            window_vld_stable <= window_vld after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Enable data capture after a stable window has been found or determined
   -- that the window is not valid.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            stable_cnt_0   <= '0' after TCQ*1 ps;
            stable_cnt_0_r <= '0' after TCQ*1 ps;
         else
            stable_cnt_0   <= bool_to_std_logic((stable_cnt = 0)) after TCQ*1 ps;
            stable_cnt_0_r <= stable_cnt_0 after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            en_data_cap <= '0' after TCQ*1 ps;
         else
            en_data_cap <= stable_cnt_0 and not(stable_cnt_0_r) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
  -- Initialization state machine drops the init_done signal when a refresh
  -- is going to occur. This assumes the init state machine keeps the init_done
  -- low until read data is valid
  -- Only used for RLDRAM II, for QDR2+ init_done should stay active high
  process (clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        init_done_r1 <= '0' after TCQ*1 ps;
        init_done_r2 <= '0' after TCQ*1 ps;
        data_stable  <= '0' after TCQ*1 ps;
        data_stable_r<= '0' after TCQ*1 ps;
      else
        init_done_r1 <= init_done after TCQ*1 ps;
        init_done_r2 <= init_done_r1 after TCQ*1 ps;
        data_stable  <= init_done and init_done_r2 after TCQ*1 ps;
        data_stable_r<= data_stable after TCQ*1 ps;
      end if;
    end if;
  end process;
   
   
   -- CQ inc and ce generation for rising edge data. CQ taps are incremented
   -- when looking for the right edge from within the rising edge window or when
   -- looking for the left edge of the rising edge window from within the
   -- falling edge data.
   -- CQ# inc and ce generation for falling edge data. CQ# taps are incremented
   -- when looking for the right edge from within the falling edge window or
   -- when looking for the left edge of the falling edge window from within the
   -- rising edge data.
   -- Tap adjustments are made following TAP_ADJ_DLY cycles after the data has
   -- been captured.
   process (clk)
   begin
      if (clk'event and clk = '1') then
        --if (rst_clk = '1') then
        --  en_tap_adj_tmp <= (others => '0') after TCQ*1 ps;
        --else
          en_tap_adj_tmp <= (en_tap_adj_tmp(TAP_ADJ_DLY - 1 downto 0) & en_data_cap) after TCQ*1 ps;
        --end if;
      end if;
   end process;
   
   
   -- Tap adjustments are only allowed if there are no updates to the IDELAY
   -- or ISERDES in progress.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            en_tap_adj <= '0' after TCQ*1 ps;
         else
            en_tap_adj <= en_tap_adj_tmp(TAP_ADJ_DLY) and data_rdy after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            en_rise_tap <= '0' after TCQ*1 ps;
            en_fall_tap <= '0' after TCQ*1 ps;
         else
            en_rise_tap <= cal_rise and en_tap_adj after TCQ*1 ps;
            en_fall_tap <= not(cal_rise) and en_tap_adj after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   cq_dly_tap_inc <= cq_dly_tap + "00001" when (en_rise_tap = '1') else
                     cq_dly_tap;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_dly_tap <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
         elsif (ctr_c_dly_st = '1') then
            cq_dly_tap <= cq_dly_tap_inc after TCQ*1 ps;
         else
            cq_dly_tap <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   cqn_dly_tap_inc <= cqn_dly_tap + "00001" when (en_fall_tap = '1') else
                      cqn_dly_tap;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cqn_dly_tap <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
         elsif (ctr_c_dly_st = '1' and issue_cdt_rst = '0' and issue_dly_rst = '0') then
            cqn_dly_tap <= cqn_dly_tap_inc after TCQ*1 ps;
         else
            cqn_dly_tap <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   q_dly_tap_inc <= q_dly_tap + "00001" when (en_tap_adj = '1') else
                    q_dly_tap;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_dly_tap <= (others =>'0') after TCQ*1 ps;
         elsif (ctr_q_dly_st = '1' and issue_dly_rst = '0') then
            q_dly_tap <= q_dly_tap_inc after TCQ*1 ps;
         else
            q_dly_tap <= (others =>'0') after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   c_tap_max_int <= '1' when (cal_rise = '1' and (to_integer(unsigned(cq_dly_tap)) = DEVICE_TAPS - 1)) else
                    '1' when (cal_rise = '0' and (to_integer(unsigned(cqn_dly_tap)) = DEVICE_TAPS - 1)) else
                    '0';
                    
    
   -- Monitor logic for tap settings that check if enough taps are reserved for
   -- the phase detector. Clock must factor in the taps reserved for the phase
   -- detect5or logic where as the data taps use the entire range.
  
  process (clk)
   begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        c_tap_max <= '0' after TCQ*1 ps;
      else
        c_tap_max <=  c_tap_max_int after TCQ*1 ps;
      end if;
    end if;
   end process;
   
   q_tap_max_int <= '1' when (to_integer(unsigned(q_dly_tap)) = (DEVICE_TAPS -1)) else
                    '0';
   
  
  
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_tap_max <= '0' after TCQ*1 ps;
         else
              q_tap_max <= q_tap_max_int after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   --Tap Centering State Machine
   
   -- Register Tap Centering state maching outputs
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            tap_ctr_cs     <= CTR_IDLE after TCQ*1 ps;
            issue_cdt_rst  <= '0' after TCQ*1 ps;
         else
            tap_ctr_cs     <= tap_ctr_ns after TCQ*1 ps;
            issue_cdt_rst  <= issue_cdt_rst_d or issue_dly_rst_d after TCQ*1 ps;
         end if;
      end if;
   end process;
 
 
   ctr_done_next        <= CTR_IDLE when (start_ctr_cal = '1') else
                           CTR_DONE;
   ctr_idle_case        <= en_data_cap & window_vld_stable;
   ctr_seek_left0_case  <= (en_data_cap & window_vld_stable & c_tap_max);
   ctr_seek_right_case  <= (en_data_cap & found_left0 & window_vld_stable & c_tap_max & ignore_first_right);
   ctr_seek_left1_case  <= (en_data_cap & window_vld_stable & q_tap_max);

   process (tap_ctr_cs, start_ctr_cal_rdy, en_data_cap, 
            window_vld_stable, c_tap_max, found_left0, ignore_first_right,
            q_tap_max, start_ctr_cal, ctr_done_next, ctr_idle_case, 
            ctr_seek_left0_case, ctr_seek_right_case, ctr_seek_left1_case,
            min_window_cnt, right_tap)
   begin
      save_left0_tap       <= '0';
      save_right_tap       <= '0';
      save_left1_tap       <= '0';
      save_found_left0     <= '0';
      save_found_right     <= '0';
      save_found_left1     <= '0';
      save_cdt_max         <= '0';
      save_qdt_max         <= '0';
      save_opp_first       <= '0';
      save_done            <= '0';
      issue_cdt_rst_d      <= '0';
      save_start_left0_d   <= '0';
      
      case tap_ctr_cs is
      
         -- When ready to sample the data, determine if valid data was captured
         -- from the target window (rising edge data if calibrating against CQ or
         -- falling edge data if calibrating against CQ#).
         when CTR_IDLE =>
            case ctr_idle_case is

               -- Initial data captured was target data so look for right edge by
               -- delaying the clock from within target edge data.
               when "11" =>
                  save_start_left0_d <= '0';
                  tap_ctr_ns         <= CTR_SEEK_RIGHT;

               -- Initial data captured was not target data so look for left edge
               -- by shifting delaying the clock starting from the opp edge data.
               when "10" =>
                  save_start_left0_d <= '1';
                  tap_ctr_ns         <= CTR_SEEK_LEFT0;

               -- Wait until data is to be captured
               when others =>
                  save_start_left0_d <= '0';
                  tap_ctr_ns         <= CTR_IDLE;
            end case;

         -- Initial window was not the target window. Search for the left edge of
         -- the target window by delaying the clock.
         when CTR_SEEK_LEFT0 =>
            case ctr_seek_left0_case is

               -- Data transitioned to valid data indicating the left edge of
               -- the target data was found within a valid tap range. Look for
               -- right edge next.
               when "110" =>
                  save_left0_tap    <= '1';
                  save_found_left0  <= '1';
                  save_opp_first    <= '1';
                  tap_ctr_ns        <= CTR_SEEK_LEFT0_CHK;

               -- Tap setting maxed out before the edge could be found. Since
               -- there is no valid clock shift setting that would put it in the
               -- target window, clock inversion is required.
               when "101" | "111" =>
                  save_left0_tap <= '1';
                  save_cdt_max   <= '1';
                  save_opp_first <= '1';
                  tap_ctr_ns     <= CTR_DONE;
                  
               when others =>
                  tap_ctr_ns <= CTR_SEEK_LEFT0;
            end case;
            
      -- Check to ensure stable transition to valid window
      when CTR_SEEK_LEFT0_CHK =>
       
           if (c_tap_max = '1') then
                 save_opp_first    <= '1';
                 save_cdt_max      <= '1';
                 tap_ctr_ns        <= CTR_DONE;              
              
              
           -- if start of window detection is right, data has to be stable for the minimum window size.
           -- Then proceed to CTR_SEEK_RIGHT state.
           elsif (en_data_cap = '1' and window_vld_stable = '1') then
              if (to_integer(min_window_cnt) = MIN_WINDOW_SIZE) then
                tap_ctr_ns <= CTR_SEEK_RIGHT;
              else 
                tap_ctr_ns <= CTR_SEEK_LEFT0_CHK;
              end if;  
           -- if data is not stable, then the start of window detection happened at the edge of the window.
           -- Move to CTR_SEEK_LEFT0 until data is stable to proceed further.
           -- left0_tap needs to be modified.
           elsif (en_data_cap = '1' and not(window_vld_stable) = '1') then
               save_left0_tap    <= '0';
               save_found_left0  <= '0';
               save_opp_first    <= '0';
               tap_ctr_ns        <= CTR_SEEK_LEFT0; 
           else 
              tap_ctr_ns <= CTR_SEEK_LEFT0_CHK;
           end if;             
         

         -- Search for the right edge of the target window by delaying the clock.
         when CTR_SEEK_RIGHT =>
         
            case ctr_seek_right_case is
               -- Data changed from valid to invalid indicating the right edge of
               -- the target data was found within valid tap range. Left edge was
               -- also found previously.
               --when "11000" | "11010" | "11001" | "11011" =>
               --   save_right_tap    <= '1';
               --   save_found_right  <= '1';
               --   tap_ctr_ns        <= CTR_DONE;
               --
               

               -- Found the right edge within valid tap range but left edge was
               -- not previously found. Look for left edge next by shifting data.
               --5'b1?0??  to 5'b1?0?0
               
               when "10000" | "10001" | "10010" | "10011" | "11000" | "11001" | "11010" | "11011"  =>
               --when "10000" |  "10010" |  "11000" | "11001" | "11010" | "11011"  => 
                
                  save_right_tap    <= '1';                 
                  save_found_right  <= '1';                 
                  tap_ctr_ns        <= CTR_SEEK_RIGHT_CHK;
                  
               
               -- This is a special case that forces later bits to follow the same
               -- calibration scheme used for the first bit in the memory.
               -- Specifically, if a large amount of clock delay was required before
               -- the left0 edge was found, then the same scheme is forced to later
               -- bits by ignoring any initial valid windows and looking for the
               -- same first edge found by bit 0.
               --when "10001" | "10011" =>
               --   save_right_tap    <= '0';
               --   save_found_right  <= '0';
               --   issue_cdt_rst_d   <= '0';
               --   tap_ctr_ns        <= CTR_SEEK_LEFT0;
                 
              
               -- Tap setting maxed out before the edge could be found.
               when "11110" | "11111" =>
                  save_right_tap <= '1';
                  save_cdt_max   <= '1';
                  tap_ctr_ns     <= CTR_DONE;

               -- Right edge could not be found before clock taps ran out. Try delaying
               -- data next to see if the left1 edge can be found.
               when "10110"  | "10111"  =>
                  save_right_tap    <= '1';
                  save_cdt_max      <= '1';
                  issue_cdt_rst_d   <= '1';
                  tap_ctr_ns        <= CTR_SEEK_LEFT1_CHK_WT;
                  
               when others =>
                  tap_ctr_ns <= CTR_SEEK_RIGHT;
            end case;
            
        -- check to ensure end of valid window has reached.
        when CTR_SEEK_RIGHT_CHK =>
            -- if end of taps condition is reached
            if (c_tap_max = '1' ) then
              -- Tap setting maxed out before the edge could be found.
              if (found_left0 = '1') then
                 --save_right_tap    <= '1';
                 save_cdt_max      <= '1';
                 tap_ctr_ns        <= CTR_DONE;              
              else
              -- Right edge could not be found before clock taps ran out. Try delaying
              -- data next to see if the left1 edge can be found.
                 --save_right_tap    <= '1';
                 save_cdt_max      <= '1';
                 issue_cdt_rst_d   <= '1';
                 tap_ctr_ns        <= CTR_SEEK_LEFT1_CHK_WT;
              end if;
              
            elsif (not(window_vld_stable) = '1') then
               -- if window is not stable after checking for MIN_WINDOW_SIZE number of taps
               if (to_integer(min_window_cnt) = MIN_WINDOW_SIZE) then
                  -- if left0 edge was previously detected and now the right edge has been detected
                  -- the calibration for the current clock is done.
                  if (found_left0 = '1') then
                     tap_ctr_ns <= CTR_DONE;
                  -- if left0_edge was not previously detected, issue clock delay reset and 
                  -- look for the left edge by shifting data.
                  else 
                     issue_cdt_rst_d   <= '1'; 
                     tap_ctr_ns <= CTR_SEEK_LEFT1_CHK_WT;
                  end if;
               else 
                  tap_ctr_ns <= CTR_SEEK_RIGHT_CHK;
               end if; 
          -- if valid data becomes available which is possible when the original alignment
          -- put the clock at the end of valid window, in which case the clock is actually
          -- at the beginning and not the end of the window.
          elsif (window_vld_stable = '1' ) then
             if (to_integer(min_window_cnt) = MIN_WINDOW_SIZE) then 
                 if (not(found_left0) = '1') then
                    -- if left edge was not previously detected and this instability                       
                    -- happened during the initial CQ/CQ# and Q alignment, treat this as the left0 edge.  
                    if (to_integer(unsigned(right_tap)) <= MIN_WINDOW_SIZE + 2+ MIN_TAPS) then
                      save_right_tap    <= '0';
                      save_found_right  <= '0';
                      save_left0_tap    <= '1';
                      save_found_left0  <= '1';
                      save_opp_first    <= '1';
                      tap_ctr_ns        <= CTR_SEEK_LEFT0_CHK; 
                    -- if the right edge detected is indeed valid and the window_vld_stable is due
                    -- to high jitter still persisting, proceed to look for left edge by
                    -- shifting data.
                    else 
                      issue_cdt_rst_d   <= '1';      
                      tap_ctr_ns        <= CTR_SEEK_LEFT1_CHK_WT; 
                    end if;
                 -- if valid left0 and right edges have been detected and yet window_vld_stable is high
                 --   MIN_WINDOW_SIZE taps after the first right edge was seen..   
                 else 
                     tap_ctr_ns <= CTR_DONE;  
                 end if;  
              else
                 tap_ctr_ns <= CTR_SEEK_RIGHT_CHK;
              end if;  
                
          else 
              tap_ctr_ns <= CTR_SEEK_RIGHT_CHK;
          end if;    
          
       -- wait state to reset the min window counter.              
       when CTR_SEEK_LEFT1_CHK_WT =>
               
                    tap_ctr_ns     <= CTR_SEEK_LEFT1_CHK;
             
      -- Search for the left edge of the target window by delaying the data.  
      -- ensure data is stable for atleast MIN_WINDOW_SIZE of taps before proceeding to 
      -- finding the left1 edge.
                                                                
      when CTR_SEEK_LEFT1_CHK  =>   
      
          if ((en_data_cap = '1') and  (not(window_vld_stable) = '1')) then
               if (not(found_left1) = '1') then
               save_left1_tap    <= '1';  
               save_found_left1  <= '1';
               end if;
               if (to_integer(min_window_cnt) = MIN_WINDOW_SIZE) then
                    tap_ctr_ns <= CTR_DONE;
               else 
                   tap_ctr_ns <= CTR_SEEK_LEFT1_CHK;
               end if;
               
          elsif (en_data_cap = '1' and window_vld_stable = '1') then
               if (to_integer(min_window_cnt) = MIN_WINDOW_SIZE) then
                    tap_ctr_ns <= CTR_SEEK_LEFT1;
               else 
                   tap_ctr_ns <= CTR_SEEK_LEFT1_CHK;
               end if;
          else 
               tap_ctr_ns <= CTR_SEEK_LEFT1_CHK;
          end if;
          
             
         -- Search for the left edge of the target window by delaying the data.
       when CTR_SEEK_LEFT1 =>
         
            -- Data changed from valid to invalid indicating the left edge of
            -- the target data was found with a valid range by delaying the
            -- the data.
            case ctr_seek_left1_case is
               when "100" | "101" =>
                  save_left1_tap    <= '1';
                  save_found_left1  <= '1';
                  tap_ctr_ns        <= CTR_DONE;

               -- Tap setting maxed out before edge could be found.
               when "111" =>
                  save_left1_tap <= '1';
                  save_qdt_max   <= '1';
                  tap_ctr_ns     <= CTR_DONE;
                  
               when others =>
                  tap_ctr_ns <= CTR_SEEK_LEFT1;
            end case;
         
         -- Edges have been found or taps have maxed out. Save the results and
         -- for the tap centering to start again if necessary.
         when CTR_DONE =>
            save_done   <= '1';
            tap_ctr_ns <= ctr_done_next;
         
         when others =>
            save_left0_tap     <= 'X';
            save_right_tap     <= 'X';
            save_left1_tap     <= 'X';
            save_found_left0   <= 'X';
            save_found_right   <= 'X';
            save_found_left1   <= 'X';
            save_cdt_max       <= 'X';
            save_qdt_max       <= 'X';
            save_opp_first     <= 'X';
            save_done          <= 'X';
            issue_cdt_rst_d    <= 'X';
            save_start_left0_d <= 'X';
            tap_ctr_ns         <= CTR_IDLE;
      end case;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            save_start_left0 <= '0' after TCQ*1 ps;
         else
            save_start_left0 <= save_start_left0_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate to ignore the first right edge of a data valid window if the
   -- first bit in the memory initially found the left0 edge and if the tap
   -- setting of that edge was greater than LEFT0_SAME_WINDOW number of taps.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            ignore_first_right <= '0' after TCQ*1 ps;
         elsif (q_mem_0 = '1') then
            ignore_first_right <= '0' after TCQ*1 ps;
         elsif (qmem0_start_left0 = '1') then
            ignore_first_right <= bool_to_std_logic((qmem0_left0_tap >= LEFT0_SAME_WINDOW)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
             min_window_cnt <= (others => '0') after TCQ*1 ps;
         elsif ((tap_ctr_cs = CTR_SEEK_LEFT0_CHK) or (tap_ctr_cs = CTR_SEEK_RIGHT_CHK) 
                         or (tap_ctr_cs = CTR_SEEK_LEFT1_CHK))  then
            if ((ctr_c_dly_st = '1' and (en_rise_tap = '1' or en_fall_tap = '1')) or
                                 (ctr_q_dly_st = '1' and en_tap_adj = '1')) then 
                 min_window_cnt <=  min_window_cnt + 1 after TCQ*1 ps;
            else 
                 min_window_cnt <=  min_window_cnt after TCQ*1 ps;
            end if;
         else  
           min_window_cnt <= (others => '0') after TCQ*1 ps;
         end if; 
      end if;
  end process;
   
   
   -- States in which CQ, CQ#, or Q taps are moved
   ctr_seek_st <= bool_to_std_logic((tap_ctr_cs = CTR_SEEK_LEFT0) or 
                            (tap_ctr_cs = CTR_SEEK_RIGHT) or 
                            (tap_ctr_cs = CTR_SEEK_LEFT1));
                  
   -- States in which CQ or CQ# taps are moved
   ctr_c_dly_st <= bool_to_std_logic((tap_ctr_cs = CTR_SEEK_LEFT0) or (tap_ctr_cs = CTR_SEEK_LEFT0_CHK) or
                             (tap_ctr_cs = CTR_SEEK_RIGHT) or (tap_ctr_cs = CTR_SEEK_RIGHT_CHK));
                  
   -- State in which Q taps are moved
   ctr_q_dly_st <= bool_to_std_logic((tap_ctr_cs = CTR_SEEK_LEFT1) or (tap_ctr_cs = CTR_SEEK_LEFT1_CHK));
   
   -- Save status of SM including information on current tap values and whether
   -- clock inversion is required. These are all cleared upon entering idle. The
   -- right_tap is set to the current cq*_dly_tap - 1 since that was the last
   -- valid tap setting. Likewise for left1_tap, it is set to cq_dly_tap + 1.
   left0_tap_d <= cq_dly_tap when (cal_rise = '1') else
                  cqn_dly_tap;
   right_tap_d <= cq_dly_tap - "00001" when (cal_rise = '1') else
                  cqn_dly_tap - "00001";
   left1_tap_d <= (others =>'0') when (q_dly_tap = "00000") else
                  q_dly_tap - "00001";
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            left0_tap    <= (others => '0') after TCQ*1 ps;
            right_tap    <= (others => '0') after TCQ*1 ps;
            left1_tap    <= (others => '0') after TCQ*1 ps;
            found_left0  <= '0' after TCQ*1 ps;
            found_right  <= '0' after TCQ*1 ps;
            found_left1  <= '0' after TCQ*1 ps;
            cdt_max      <= '0' after TCQ*1 ps;
            qdt_max      <= '0' after TCQ*1 ps;
            opp_first    <= '0' after TCQ*1 ps;
            ctr_done_pre <= '0' after TCQ*1 ps;
            start_left0  <= '0' after TCQ*1 ps;
         elsif (tap_ctr_cs = CTR_IDLE) then
            left0_tap   <= (others => '0') after TCQ*1 ps;
            right_tap   <= (others => '0') after TCQ*1 ps;
            left1_tap   <= (others => '0') after TCQ*1 ps;
            found_left0 <= '0' after TCQ*1 ps;
            found_right <= '0' after TCQ*1 ps;
            found_left1 <= '0' after TCQ*1 ps;
            cdt_max     <= '0' after TCQ*1 ps;
            qdt_max     <= '0' after TCQ*1 ps;
            opp_first   <= '0' after TCQ*1 ps;
            ctr_done_pre<= '0' after TCQ*1 ps;
            start_left0 <= '0' after TCQ*1 ps;
         else
            if (save_left0_tap = '1') then
               left0_tap <= left0_tap_d after TCQ*1 ps;
            end if;
            if (save_right_tap = '1') then
               right_tap <= right_tap_d after TCQ*1 ps;
            end if;
            if (save_left1_tap = '1') then
               left1_tap <= left1_tap_d after TCQ*1 ps;
            end if;
            if (save_found_left0 = '1') then
               found_left0 <= '1' after TCQ*1 ps;
            end if;
            if (save_found_right = '1') then
               found_right <= '1' after TCQ*1 ps;
            end if;
            if (save_found_left1 = '1') then
               found_left1 <= '1' after TCQ*1 ps;
            end if;
            if (save_cdt_max = '1') then
               cdt_max <= '1' after TCQ*1 ps;
            end if;
            if (save_qdt_max = '1') then
               qdt_max <= '1' after TCQ*1 ps;
            end if;
            if (save_opp_first = '1') then
               opp_first <= '1' after TCQ*1 ps;
            end if;
            if (save_done = '1') then
               ctr_done_pre <= '1' after TCQ*1 ps;
            end if;
            if (save_start_left0 = '1') then
               start_left0 <= '1' after TCQ*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   
   -- Delay tap centering done indication by a cycle to allow time for all
   -- logic to complete updating
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            ctr_done_sig <= '0' after TCQ*1 ps;
         else
            ctr_done_sig <= ctr_done_pre after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Save information for the first bit in each device
   q0mem_left0_tap_d <= cq_dly_tap when (cal_rise = '1') else
                        cqn_dly_tap;
   q0mem_right_tap_d <= cq_dly_tap - "00001" when (cal_rise = '1') else
                        cqn_dly_tap - "00001";
   q0mem_left1_tap_d <= (others =>'0') when (q_dly_tap = "00000") else
                        q_dly_tap - "00001";
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q0mem_left0_tap   <= (others =>'0') after TCQ*1 ps;
            q0mem_right_tap   <= (others =>'0') after TCQ*1 ps;
            q0mem_left1_tap   <= (others =>'0') after TCQ*1 ps;
            q0mem_found_left0 <= '0' after TCQ*1 ps;
            q0mem_found_right <= '0' after TCQ*1 ps;
            q0mem_found_left1 <= '0' after TCQ*1 ps;
            q0mem_cdt_max     <= '0' after TCQ*1 ps;
            q0mem_qdt_max     <= '0' after TCQ*1 ps;
            q0mem_opp_first   <= '0' after TCQ*1 ps;
            q0mem_start_left0 <= '0' after TCQ*1 ps;
         elsif (q_mem_0 = '1') then
            if (save_left0_tap = '1') then
               q0mem_left0_tap <= q0mem_left0_tap_d after TCQ*1 ps;
            end if;
            if (save_right_tap = '1') then
               q0mem_right_tap <= q0mem_right_tap_d after TCQ*1 ps;
            end if;
            if (save_left1_tap = '1') then
               q0mem_left1_tap <= q0mem_left1_tap_d after TCQ*1 ps;
            end if;
            if (save_found_left0 = '1') then
               q0mem_found_left0 <= '1' after TCQ*1 ps;
            end if;
            if (save_found_right = '1') then
               q0mem_found_right <= '1' after TCQ*1 ps;
            end if;
            if (save_found_left1 = '1') then
               q0mem_found_left1 <= '1' after TCQ*1 ps;
            end if;
            if (save_cdt_max = '1') then
               q0mem_cdt_max <= '1' after TCQ*1 ps;
            end if;
            if (save_qdt_max = '1') then
               q0mem_qdt_max <= '1' after TCQ*1 ps;
            end if;
            if (save_opp_first = '1') then
               q0mem_opp_first <= '1' after TCQ*1 ps;
            end if;
            if (save_start_left0 = '1') then
               q0mem_start_left0 <= '1' after TCQ*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   
   -- CDT left0 edge setting + taps to center <= maximum usable clock taps
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            clpct_lte_dt <= '0' after TCQ*1 ps;
         else
            clpct_lte_dt <= bool_to_std_logic(left0_plus_center <= MAX_TAPS) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
  -- CDT left0 edge setting >= center taps
  process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
           left0_gr_ctr <= '0' after TCQ*1 ps;
         else
           left0_gr_ctr <= bool_to_std_logic(left0_tap >= CENTER_TAP) after TCQ*1 ps;
         end if;
      end if;
      
  end process;
   
   
   -- CDT right edge setting > QDT left1 edge setting
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cr_gt_ql <= '0' after TCQ*1 ps;
         else
             cr_gt_ql <= bool_to_std_logic(right_tap - MIN_TAPS > left1_tap) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- taps to center <= maximum data taps + CDT right edge setting
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            ct_lte_dtpcr <= '0' after TCQ*1 ps;
         else
            ct_lte_dtpcr <= bool_to_std_logic(CENTER_TAP <= right_plus_maxt) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- left0_tap + right_tap
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            left0_plus_right <= (others =>'0') after TCQ*1 ps;
         else
            left0_plus_right <= ('0' & left0_tap + right_tap) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
    -- left0_tap + center tap
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            left0_plus_center <= (others =>'0') after TCQ*1 ps;
         else
            left0_plus_center <= ( '0' & left0_tap + CENTER_TAP) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
    -- right_tap + max_taps
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            right_plus_maxt <= (others =>'0') after TCQ*1 ps;
         else
            right_plus_maxt <= ( '0' & right_tap + MAX_TAPS) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- right_tap - left1_tap
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            right_minus_left1 <= (others =>'0') after TCQ*1 ps;
         else
            right_minus_left1 <= (right_tap - MIN_TAPS)- left1_tap after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- left1_tap - right_tap
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            left1_minus_right <= (others =>'0') after TCQ*1 ps;
         else
            left1_minus_right <= left1_tap - (right_tap - MIN_TAPS) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- cetner tap - left1 tap
   process (clk)
   begin
      if (clk'event and clk = '1') then
          if (rst_clk = '1') then
            ct_minus_left1 <= (others =>'0') after TCQ*1 ps;
          elsif (CENTER_TAP < left1_tap) then
            ct_minus_left1 <= (others =>'0') after TCQ*1 ps;
          else
            ct_minus_left1 <= '0' & (CENTER_TAP - left1_tap) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
                        
   
   tap_settings_case <= (found_left0 & found_right & found_left1 & cdt_max & qdt_max & 
                         opp_first & clpct_lte_dt & cr_gt_ql & ct_lte_dtpcr & left0_gr_ctr);


    -- Determine tap setting to find center of window (or closest to center).
   -- cdt_selected_d indicates if delaying the clock was best. Otherwise, it
   -- indicates that data delay was necessary. Depending on the cdt_selected_d
   -- setting, either the clock or data tap setting is placed on optimal_tap_d.
   -- The tap_offset_d value indicates the distance from the true middle for
   -- the selected setting. A value of 0 for the offset indicates that the
   -- could be achieved with the optimal_tap_d setting.
   process (found_left0, found_right, found_left1, cdt_max, qdt_max, opp_first,
            clpct_lte_dt, cr_gt_ql, ct_lte_dtpcr, ct_minus_left1, left0_gr_ctr, 
            left1_tap, left0_tap, left0_plus_right, right_tap, 
            right_minus_left1, left1_minus_right, tap_settings_case)
   begin
      
      case tap_settings_case is
         -- Initial alignment put the clock within the opposite edge data window.
         -- Delaying the clock did not find the left of the target data window
         -- before the taps ran out. Therefore, there is no valid setting and
         -- clock inversion is required.
         when "0001010000" | "0101010000" | "0011010000" | "0111010000" | 
              "0001110000" | "0101110000" | "0011110000" | "0111110000" | 
              "0001011000" | "0101011000" | "0011011000" | "0111011000" | 
              "0001111000" | "0101111000" | "0011111000" | "0111111000" | 
              "0001010100" | "0101010100" | "0011010100" | "0111010100" | 
              "0001110100" | "0101110100" | "0011110100" | "0111110100" | 
              "0001011100" | "0101011100" | "0011011100" | "0111011100" | 
              "0001111100" | "0101111100" | "0011111100" | "0111111100" | 
              "0001010010" | "0101010010" | "0011010010" | "0111010010" | 
              "0001110010" | "0101110010" | "0011110010" | "0111110010" | 
              "0001011010" | "0101011010" | "0011011010" | "0111011010" | 
              "0001111010" | "0101111010" | "0011111010" | "0111111010" | 
              "0001010110" | "0101010110" | "0011010110" | "0111010110" | 
              "0001110110" | "0101110110" | "0011110110" | "0111110110" | 
              "0001011110" | "0101011110" | "0011011110" | "0111011110" | 
              "0001111110" | "0101111110" | "0011111110" | "0111111110" |
              
              "0001010001" | "0101010001" | "0011010001" | "0111010001" | 
              "0001110001" | "0101110001" | "0011110001" | "0111110001" | 
              "0001011001" | "0101011001" | "0011011001" | "0111011001" | 
              "0001111001" | "0101111001" | "0011111001" | "0111111001" | 
              "0001010101" | "0101010101" | "0011010101" | "0111010101" | 
              "0001110101" | "0101110101" | "0011110101" | "0111110101" | 
              "0001011101" | "0101011101" | "0011011101" | "0111011101" | 
              "0001111101" | "0101111101" | "0011111101" | "0111111101" | 
              "0001010011" | "0101010011" | "0011010011" | "0111010011" | 
              "0001110011" | "0101110011" | "0011110011" | "0111110011" | 
              "0001011011" | "0101011011" | "0011011011" | "0111011011" | 
              "0001111011" | "0101111011" | "0011111011" | "0111111011" | 
              "0001010111" | "0101010111" | "0011010111" | "0111010111" | 
              "0001110111" | "0101110111" | "0011110111" | "0111110111" | 
              "0001011111" | "0101011111" | "0011011111" | "0111011111" | 
              "0001111111" | "0101111111" | "0011111111" | "0111111111" =>
            cdt_selected_d <= '0';
            optimal_tap_d  <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS));
            tap_offset_d   <= (others => '1');
            true_center_d  <= '0';
            try_clk_inv_d  <= '1';
            window_size_d  <= (others => '0');
         -- Initial alignment put the clock within the correct data window.
         -- Delaying the clock could not find the right edge before the
         -- clock taps maxed out. Reseting the clock delay to zero and
         -- delaying the data was able to find the left edge before the
         -- data taps maxed out. Optimal setting is no clock taps and no
         -- data taps.
         when "0001100000" | "0001100100" | "0001101000" | "0001101100" | 
              "0001100001" | "0001100101" | "0001101001" | "0001101101" | 
              "0001100010" | "0001100110" | "0001101010" | "0001101110" | 
              "0001100011" | "0001100111" | "0001101011" | "0001101111" => 
            cdt_selected_d <= '1';
            optimal_tap_d  <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS));
            tap_offset_d   <= (others =>'0');
            true_center_d  <= '0';
            try_clk_inv_d  <= '0';
            window_size_d  <= std_logic_vector(to_unsigned((DEVICE_TAPS + MAX_TAPS - MIN_TAPS), TAP_BITS+1));
         -- Initial alignment put the clock within the correct data window.
         -- Delaying the clock could not find the right edge before the
         -- clock taps maxed out. Reseting the clock delay to zero and
         -- delaying the data was able to find the left edge before the
         -- data taps maxed out. Delaying the clock is able to hit the
         -- ideal center.
         -- Optimal setting is CENTER_TAPS - data taps.
         when "0011000000" | "0011000100" | "0011001000" | "0011001100" | 
              "0011000001" | "0011000101" | "0011001001" | "0011001101" |
              "0011000010" | "0011000110" | "0011001010" | "0011001110" | 
              "0011000011" | "0011000111" | "0011001011" | "0011001111" =>
            cdt_selected_d <= '1';
            optimal_tap_d  <= ct_minus_left1(4 downto 0) + MIN_TAPS;
            tap_offset_d   <= (others =>'0');
            true_center_d  <= '0';
            try_clk_inv_d  <= '1';
            window_size_d  <= MAX_TAPS + ('0' & left1_tap);
         -- Initial alignment put the clock within the opposite edge data window.
         -- Delaying the clock found the left edge but right edge could not be
         -- found before the taps ran out.
         -- Maximum clock delay taps gets closest to center but not all the way.   
         when "1001010000" | "1001010100" | "1001110000" | "1001110100" | 
              "1001010001" | "1001010101" | "1001110001" | "1001110101" | 
              "1001010010" | "1001010110" | "1001110010" | "1001110110" | 
              "1001010011" | "1001010111" | "1001110011" | "1001110111" |  
                                                                
              "1011010000" | "1011010100" | "1011110000" | "1011110100" | 
              "1011010001" | "1011010101" | "1011110001" | "1011110101" | 
              "1011010010" | "1011010110" | "1011110010" | "1011110110" | 
              "1011010011" | "1011010111" | "1011110011" | "1011110111" =>
                     
            cdt_selected_d <= '1';
            optimal_tap_d  <= std_logic_vector(to_unsigned(MAX_TAPS, TAP_BITS));
            tap_offset_d   <= CENTER_TAP - (MAX_TAPS - left0_tap);
            true_center_d  <= '0';
            try_clk_inv_d  <= '1';
            window_size_d  <= MAX_TAPS - ('0' & left0_tap);
         -- Initial alignment put the clock within the opposite edge data window.
         -- Delaying the clock found the left edge but right edge could not be  
         -- found before the taps ran out.                                      
         -- Maximum clock delay taps does hit ideal center.                     
         when "1001011000" | "1001011100" | "1001111000" | "1001111100" | 
              "1001011001" | "1001011101" | "1001111001" | "1001111101" | 
              "1001011010" | "1001011110" | "1001111010" | "1001111110" | 
              "1001011011" | "1001011111" | "1001111011" | "1001111111" |  
              
              "1011011000" | "1011011100" | "1011111000" | "1011111100" | 
              "1011011001" | "1011011101" | "1011111001" | "1011111101" | 
              "1011011010" | "1011011110" | "1011111010" | "1011111110" | 
              "1011011011" | "1011011111" | "1011111011" | "1011111111" =>
            cdt_selected_d <= '1';
            optimal_tap_d  <= CENTER_TAP + left0_tap;
            tap_offset_d   <= (others =>'0');
            true_center_d  <= '0';
            try_clk_inv_d  <= '1';
            window_size_d  <= MAX_TAPS - ('0' & left0_tap);
         -- Initial alignment put the clock within the opposite edge data window.
         -- Delaying the clock found both the left and right edges of the target
         -- data window.
         -- Optimal setting is the midway between the left and right edges.
         when "1100010000" | "1110010000" | "1101010000" | "1111010000" | 
              "1100110000" | "1110110000" | "1101110000" | "1111110000" | 
              "1100011000" | "1110011000" | "1101011000" | "1111011000" | 
              "1100111000" | "1110111000" | "1101111000" | "1111111000" | 
              "1100010100" | "1110010100" | "1101010100" | "1111010100" | 
              "1100110100" | "1110110100" | "1101110100" | "1111110100" | 
              "1100011100" | "1110011100" | "1101011100" | "1111011100" | 
              "1100111100" | "1110111100" | "1101111100" | "1111111100" | 
              "1100010010" | "1110010010" | "1101010010" | "1111010010" | 
              "1100110010" | "1110110010" | "1101110010" | "1111110010" | 
              "1100011010" | "1110011010" | "1101011010" | "1111011010" | 
              "1100111010" | "1110111010" | "1101111010" | "1111111010" | 
              "1100010110" | "1110010110" | "1101010110" | "1111010110" | 
              "1100110110" | "1110110110" | "1101110110" | "1111110110" | 
              "1100011110" | "1110011110" | "1101011110" | "1111011110" | 
              "1100111110" | "1110111110" | "1101111110" | "1111111110" =>
            cdt_selected_d <= '1';
            optimal_tap_d  <= left0_plus_right(TAP_BITS downto 1);
            tap_offset_d   <= (others =>'0');
            true_center_d  <= '1';
            try_clk_inv_d  <= '0';
            window_size_d  <= ('0' & right_tap) - ('0' & left0_tap);
          -- Initial alignment put the clock within the opposite edge data window.
          -- Delaying the clock found both the left and right edges of the target
          -- data window. Optimal setting is close to the end of the delay chain
          -- Inversion can provide a smaller delay on the clock.
         when "1100010001" | "1110010001" | "1101010001" | "1111010001" | 
              "1100110001" | "1110110001" | "1101110001" | "1111110001" | 
              "1100011001" | "1110011001" | "1101011001" | "1111011001" | 
              "1100111001" | "1110111001" | "1101111001" | "1111111001" | 
              "1100010101" | "1110010101" | "1101010101" | "1111010101" | 
              "1100110101" | "1110110101" | "1101110101" | "1111110101" | 
              "1100011101" | "1110011101" | "1101011101" | "1111011101" | 
              "1100111101" | "1110111101" | "1101111101" | "1111111101" | 
              "1100010011" | "1110010011" | "1101010011" | "1111010011" | 
              "1100110011" | "1110110011" | "1101110011" | "1111110011" | 
              "1100011011" | "1110011011" | "1101011011" | "1111011011" | 
              "1100111011" | "1110111011" | "1101111011" | "1111111011" | 
              "1100010111" | "1110010111" | "1101010111" | "1111010111" | 
              "1100110111" | "1110110111" | "1101110111" | "1111110111" | 
              "1100011111" | "1110011111" | "1101011111" | "1111011111" | 
              "1100111111" | "1110111111" | "1101111111" | "1111111111" =>
            cdt_selected_d <= '1';
            optimal_tap_d  <= left0_plus_right(TAP_BITS downto 1);
            tap_offset_d   <= (others =>'0');
            true_center_d  <= '0';
            try_clk_inv_d  <= '1';
            window_size_d  <= ('0' & right_tap) - ('0' & left0_tap);
         
         
            
         -- Initial alignment put the clock within the correct data window.
         -- Delaying the clock found the right edge. Reseting the clock delay to
         -- zero and then delaying the data found the left edge. Clock delay was
         -- larger than data delay.
         -- Optimal setting is (clock taps - data taps) / 2
         when "0110000100" | "1110000100" | "0111000100" | "1111000100" | 
              "0110100100" | "1110100100" | "0111100100" | "1111100100" | 
              "0110001100" | "1110001100" | "0111001100" | "1111001100" | 
              "0110101100" | "1110101100" | "0111101100" | "1111101100" | 
              "0110000110" | "1110000110" | "0111000110" | "1111000110" | 
              "0110100110" | "1110100110" | "0111100110" | "1111100110" | 
              "0110001110" | "1110001110" | "0111001110" | "1111001110" | 
              "0110101110" | "1110101110" | "0111101110" | "1111101110" |  
              
              "0110000101" | "1110000101" | "0111000101" | "1111000101" | 
              "0110100101" | "1110100101" | "0111100101" | "1111100101" | 
              "0110001101" | "1110001101" | "0111001101" | "1111001101" | 
              "0110101101" | "1110101101" | "0111101101" | "1111101101" | 
              "0110000111" | "1110000111" | "0111000111" | "1111000111" | 
              "0110100111" | "1110100111" | "0111100111" | "1111100111" | 
              "0110001111" | "1110001111" | "0111001111" | "1111001111" | 
              "0110101111" | "1110101111" | "0111101111" | "1111101111" =>
            cdt_selected_d <= '1';
            optimal_tap_d  <= ('0' & right_minus_left1(TAP_BITS - 1 downto 1)) + MIN_TAPS;
            tap_offset_d   <= (others =>'0');
            true_center_d  <= '1';
            try_clk_inv_d  <= '0';
            window_size_d  <= ('0' & right_tap) + ('0' & left1_tap);
        -- Initial alignment put the clock within the correct data window.
        -- Delaying the clock found the right edge. Reseting the clock delay to
        -- zero and then delaying the data found the left edge. Clock delay was
        -- smaller than data delay.
        -- Optimal setting is (data taps - clock taps) / 2
         when "0110000000" | "1110000000" | "0111000000" | "1111000000" | 
              "0110100000" | "1110100000" | "0111100000" | "1111100000" | 
              "0110001000" | "1110001000" | "0111001000" | "1111001000" | 
              "0110101000" | "1110101000" | "0111101000" | "1111101000" | 
              "0110000010" | "1110000010" | "0111000010" | "1111000010" | 
              "0110100010" | "1110100010" | "0111100010" | "1111100010" | 
              "0110001010" | "1110001010" | "0111001010" | "1111001010" | 
              "0110101010" | "1110101010" | "0111101010" | "1111101010" |
              
              "0110000001" | "1110000001" | "0111000001" | "1111000001" | 
              "0110100001" | "1110100001" | "0111100001" | "1111100001" | 
              "0110001001" | "1110001001" | "0111001001" | "1111001001" | 
              "0110101001" | "1110101001" | "0111101001" | "1111101001" | 
              "0110000011" | "1110000011" | "0111000011" | "1111000011" | 
              "0110100011" | "1110100011" | "0111100011" | "1111100011" | 
              "0110001011" | "1110001011" | "0111001011" | "1111001011" | 
              "0110101011" | "1110101011" | "0111101011" | "1111101011" =>
            cdt_selected_d <= '0';                                
            optimal_tap_d  <= ('0' & left1_minus_right(TAP_BITS - 1 downto 1));
            tap_offset_d   <= (others =>'0');                     
            true_center_d  <= '1';
            try_clk_inv_d  <= '1';
            window_size_d  <= ('0' & left1_tap) + ('0' & right_tap) - MIN_TAPS;
         -- Initial alignment put the clock with the correct data window.
         -- Delaying the clock found the right edge. Reseting the clock delay to
         -- zero and then delaying the data could not find the left edge before the
         -- taps ran out. The ideal center tap can be reached by delaying data.
         -- Maximum data delay taps gets closest to center but not all the way..
         when "0100100000" | "1100100000" | "0101100000" | "1101100000" | 
              "0100101000" | "1100101000" | "0101101000" | "1101101000" | 
              "0100100100" | "1100100100" | "0101100100" | "1101100100" | 
              "0100101100" | "1100101100" | "0101101100" | "1101101100" |   
              
              "0100100001" | "1100100001" | "0101100001" | "1101100001" | 
              "0100101001" | "1100101001" | "0101101001" | "1101101001" | 
              "0100100101" | "1100100101" | "0101100101" | "1101100101" | 
              "0100101101" | "1100101101" | "0101101101" | "1101101101" =>
              
              
            cdt_selected_d <= '0';
            optimal_tap_d  <= std_logic_vector(to_unsigned(DEVICE_TAPS -1, TAP_BITS));
            tap_offset_d   <= std_logic_vector(to_signed((CENTER_TAP - DEVICE_TAPS -1), TAP_BITS));
            true_center_d  <= '0';
            try_clk_inv_d  <= '1';
            window_size_d  <= DEVICE_TAPS + ('0' & right_tap) - MIN_TAPS;
         -- Initial alignment put the clock with the correct data window.
         -- Delaying the clock found the right edge. Reseting the clock delay to
         -- zero and then delaying the data could not find the left edge before the
         -- taps ran out. The ideal center tap can be reached by delaying data.
         -- Optimal setting is the difference between center tap and right edge.
         when "0100100010" | "1100100010" | "0101100010" | "1101100010" | 
              "0100101010" | "1100101010" | "0101101010" | "1101101010" | 
              "0100100110" | "1100100110" | "0101100110" | "1101100110" | 
              "0100101110" | "1100101110" | "0101101110" | "1101101110" |              
              "0100100011" | "1100100011" | "0101100011" | "1101100011" | 
              "0100101011" | "1100101011" | "0101101011" | "1101101011" | 
              "0100100111" | "1100100111" | "0101100111" | "1101100111" | 
              "0100101111" | "1100101111" | "0101101111" | "1101101111" =>
            cdt_selected_d <= '0';
            optimal_tap_d  <= std_logic_vector(to_unsigned(CENTER_TAP, TAP_BITS));
            tap_offset_d   <= (others =>'0');
            true_center_d  <= '0';
            try_clk_inv_d  <= '1';
            window_size_d  <= DEVICE_TAPS + ('0' & right_tap) - MIN_TAPS;
         when others =>
            cdt_selected_d <= '0';
            optimal_tap_d  <= (others =>'0');
            tap_offset_d   <= (others =>'0');
            true_center_d  <= '0';
            try_clk_inv_d  <= '0';
            window_size_d  <= (others =>'0');
      end case;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cdt_selected   <= '0' after TCQ*1 ps;
            optimal_tap    <= "00000" after TCQ*1 ps;
            tap_offset     <= "00000" after TCQ*1 ps;
            true_center    <= '0' after TCQ*1 ps;
            try_clk_inv    <= '0' after TCQ*1 ps;
            window_size    <= "000000" after TCQ*1 ps;
         else
            cdt_selected   <= cdt_selected_d after TCQ*1 ps;
            optimal_tap    <= optimal_tap_d after TCQ*1 ps;
            tap_offset     <= tap_offset_d after TCQ*1 ps;
            true_center    <= true_center_d after TCQ*1 ps;
            try_clk_inv    <= try_clk_inv_d after TCQ*1 ps;
            window_size    <= window_size_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- }}} end Tap Centering ----------------------
   
   -- {{{ Overall Calibration Control ------------
   
   -- After the initialization logic has completed, signal to the initilization
   -- logic to begin stage 1 calibration. Wait for the read back data to come
   -- across before starting the calibration state machine.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cal_stage1_start_sig <= '0' after TCQ*1 ps;
         elsif (init_done = '1') then
            cal_stage1_start_sig <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         cal_sm_start_tmp <= (cal_sm_start_tmp(CAL_START_DLY - 1 downto 0) & cal_stage1_start_sig) after TCQ*1 ps;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cal_sm_start <= '0' after TCQ*1 ps;
         else
            cal_sm_start <= cal_sm_start_tmp(CAL_START_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   q_mem_0   <= bool_to_std_logic(q_mem = "0000000");
   q_bit_max <= bool_to_std_logic(q_bit_sig = DATA_WIDTH - 1);
   q_mem_max <= bool_to_std_logic(q_mem = MEMORY_WIDTH - 1);
   
   -- Register State Machine Outputs
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cal_cs               <= CAL_IDLE after TCQ*1 ps;
            start_ctr_cal_int    <= '0' after TCQ*1 ps;
            cal_rise             <= '1' after TCQ*1 ps;
            save_rise_edge       <= '0' after TCQ*1 ps;
            save_rise_edge_inv   <= '0' after TCQ*1 ps;
            save_fall_edge       <= '0' after TCQ*1 ps;
            save_current         <= '0' after TCQ*1 ps;
            force_clk_invert     <= '0' after TCQ*1 ps;
            issue_dly_rst        <= '0' after TCQ*1 ps;
            issue_load_c         <= '0' after TCQ*1 ps;
            issue_load_q         <= '0' after TCQ*1 ps;
            inc_q                <= '0' after TCQ*1 ps;
            inc_cq               <= '0' after TCQ*1 ps;
            next_q_grp           <= '0' after TCQ*1 ps;
         else
            cal_cs               <= cal_ns after TCQ*1 ps;
            start_ctr_cal_int    <= start_ctr_cal_d after TCQ*1 ps;
            cal_rise             <= cal_rise_d after TCQ*1 ps;
            save_rise_edge       <= save_rise_edge_d after TCQ*1 ps;
            save_rise_edge_inv   <= save_rise_edge_inv_d after TCQ*1 ps;
            save_fall_edge       <= save_fall_edge_d after TCQ*1 ps;
            save_current         <= save_current_d after TCQ*1 ps;
            force_clk_invert     <= force_clk_invert_d after TCQ*1 ps;
            issue_dly_rst        <= issue_dly_rst_d after TCQ*1 ps;
            issue_load_c         <= issue_load_c_d after TCQ*1 ps;
            issue_load_q         <= issue_load_q_d after TCQ*1 ps;
            inc_q                <= inc_q_d after TCQ*1 ps;
            inc_cq               <= inc_cq_d after TCQ*1 ps;
            next_q_grp           <= next_q_grp_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   set_phase_next_none <= CAL_DONE when (q_bit_max = '1') else
                          CAL_Q_RISE;
   set_phase_next_fast <= CAL_Q_RISE when (cq_num_sig /= (NUM_DEVICES - 1)) else
                          CAL_DONE;

   cal_qbit_det_case <= (qbit_det_done & prev_adj_req);
   cal_qbit_set_case <= (data_stable & q_mem_max & qbit_set_done & q_bit_max & cap_prev_adj_req);
   cal_adj_req_case  <= (data_stable & q_mem_max & all_q_adj & load_done & q_bit_rdy & tap_done);
   cal_q_rise_case <= (ctr_done_sig & start_in_progress & q_mem_0 & try_clk_inv);


   -- Per-bit delay calibration state machine
   process (cal_rise, cal_cs, cal_sm_start, ctr_done_sig, start_in_progress, 
            q_mem_0, try_clk_inv, det_opt_done, det_ovr_done, cq_rst_done, 
            set_ovr_done, qbit_det_done, prev_adj_req, q_mem_max, 
            qbit_set_done, q_bit_max, cap_prev_adj_req, all_q_adj, load_done,
            q_bit_rdy, tap_done, q_bit_adj_done, set_phase_next_none, 
            set_phase_next_fast, cal_qbit_det_case, cal_qbit_set_case,
            cal_adj_req_case, cal_q_rise_case, data_stable, cq_num_sig)
   begin
      start_ctr_cal_d      <= '0';
      cal_rise_d           <= cal_rise;
      save_rise_edge_d     <= '0';
      save_rise_edge_inv_d <= '0';
      save_fall_edge_d     <= '0';
      save_current_d       <= '0';
      force_clk_invert_d   <= '0';
      clear_clk_invert     <= '0';
      set_clk_polarity     <= '0';
      issue_dly_rst_d      <= '0';
      issue_load_c_d       <= '0';
      issue_load_q_d       <= '0';
      inc_q_d              <= '0';
      inc_cq_d             <= '0';
      save_target_q        <= '0';
      clr_q                <= '0';
      load_init            <= '0';
      capture_adj          <= '0';
      start_adj            <= '0';
      next_q_grp_d         <= '0';
      cal_ns		   <= CAL_IDLE; 
      
      case cal_cs is
      
         -- Wait until initialization logic is complete and then initiate tap
         -- centering on rising edge data for Q0. Completely skip delay
         -- calibration when SIM_CAL_OPTION="SKIP_CAL" and proceed to calibrate
         -- a single phase.
         when CAL_IDLE =>
            if (cal_sm_start = '1') then
               if ((SIM_CAL_OPTION = "NONE") or (SIM_CAL_OPTION = "FAST_CAL")) then
                  start_ctr_cal_d <= '1';
                  cal_rise_d      <= '1';
                  cal_ns          <= CAL_Q_RISE;
               elsif (SIM_CAL_OPTION = "SKIP_CAL" and data_stable = '1') then
                  start_ctr_cal_d <= '0';
                  cal_rise_d      <= '1';
                  cal_ns          <= CAL_SET_PHASE;
               end if;
            else
               start_ctr_cal_d <= '0';
               cal_rise_d      <= '1';
               cal_ns          <= CAL_IDLE;
            end if;


         -- Wait for tap centering state machine to return the best tap settings
         -- for the particual bit being calibrated. Clock inversion is only tried
         -- for the first Q bit in each CQ group.
         when CAL_Q_RISE =>
            
            case cal_q_rise_case is
               -- Center was found for first Q in memory and clock inversion is not
               -- necessary.
               when "1010" =>
                  start_ctr_cal_d      <= '0';
                  save_rise_edge_d     <= '1';
                  save_current_d       <= '0';
                  force_clk_invert_d   <= '0';
                  cal_ns               <= CAL_DET_OPT;
               
               -- Center was found for first Q in memory and clock inversion
               -- needs to be checked for better results.
               when "1011" =>
                  start_ctr_cal_d <= '1';
                  save_rise_edge_d <= '1';
                  save_current_d <= '0';
                  force_clk_invert_d <= '1';
                  issue_dly_rst_d <= '1';
                  cal_ns <= CAL_Q_RISE_INV;

               -- Center was found for a Q other than the first in the memory.
               when "1000" | "1001" =>
                  start_ctr_cal_d    <= '0';
                  save_rise_edge_d   <= '0';
                  save_current_d     <= '1';
                  force_clk_invert_d <= '0';
                  cal_ns             <= CAL_QBIT_DET;

               -- Wait until the centering algorithm returns.
               when others =>
                  start_ctr_cal_d    <= '0';
                  save_rise_edge_d   <= '0';
                  save_current_d     <= '0';
                  force_clk_invert_d <= '0';
                  cal_ns             <= CAL_Q_RISE;
            end case;

         -- Wait for tap centering state machine to return the best tap settings
         -- for first rising edge bit in the memory using the inverted clock.
         when CAL_Q_RISE_INV =>
            if ((ctr_done_sig and not(start_in_progress)) = '1') then
               save_rise_edge_inv_d <= '1';
               cal_ns               <= CAL_DET_OPT;
            else
               save_rise_edge_inv_d <= '0';
               cal_ns               <= CAL_Q_RISE_INV;
            end if;

         -- Determine the optimal tap setting for the first Q bit in the target CQ
         -- group. This dictates if the ISERDES clock should be inverted and is
         -- used for the remainder of the calibration. Set the calibrated clock
         -- polarity and proceed to calibration the falling data for the first Q
         -- in the memory.
         when CAL_DET_OPT =>
            if (det_opt_done = '1' and MEMORY_TYPE = "RLD2") then
               set_clk_polarity  <= '1';
               start_ctr_cal_d   <= '0';
               issue_dly_rst_d   <= '1';
               cal_rise_d        <= '1';
               cal_ns            <= CAL_DET_OVR;
            elsif (det_opt_done = '1' and MEMORY_TYPE = "QDR") then
               set_clk_polarity  <= '1';
               start_ctr_cal_d   <= '1';
               issue_dly_rst_d   <= '1';
               cal_rise_d        <= '0';
               cal_ns            <= CAL_Q_FALL;
            else
               set_clk_polarity  <= '0';
               start_ctr_cal_d   <= '0';
               issue_dly_rst_d   <= '0';
               cal_rise_d        <= '1';
               cal_ns            <= CAL_DET_OPT;
            end if;

         -- Wait for tap centering state machine to return the best tap settings
         -- for first falling edge bit in the memory using the clock polarity
         -- previously chosen by the rising edge data.
         when CAL_Q_FALL =>
            if (ctr_done_sig = '1' and start_in_progress = '0') then
               save_fall_edge_d  <= '1';
               cal_ns            <= CAL_DET_OVR;
            else
               save_fall_edge_d <= '0';
               cal_ns           <= CAL_Q_FALL;
            end if;

         -- Now that both rising and falling edge data have been calibrated for
         -- the first Q in the memory, determine and the overall settings that
         -- best suit the rise and fall data.
         when CAL_DET_OVR =>
            if (MEMORY_TYPE = "RLD2" and det_ovr_done = '1') then
               issue_load_c_d <= '0';
               issue_load_q_d <= '0';
               load_init      <= '0';
               cal_ns         <= CAL_RST_WAIT;
            elsif (det_ovr_done = '1') then
               issue_load_c_d <= '1';
               issue_load_q_d <= '1';
               load_init      <= '1';
               cal_ns         <= CAL_SET_OVR;
            else
               issue_load_c_d <= '0';
               issue_load_q_d <= '0';
               load_init      <= '0';
               cal_ns         <= CAL_DET_OVR;
            end if;

         -- The statemachine waits for cq_rst_done to go high before issuing load_c
         when CAL_RST_WAIT =>
            if (cq_rst_done = '1') then
               issue_load_c_d <= '1';
               issue_load_q_d <= '1';
               load_init      <= '1';
               cal_ns         <= CAL_SET_OVR;
            else
               issue_load_c_d <= '0';
               issue_load_q_d <= '0';
               load_init      <= '0';
               cal_ns         <= CAL_RST_WAIT;
            end if;

         -- Set the overall settings for both the rise and fall data for the first
         -- Q in the memory. Wait for the update to complete before advancing on
         -- and calibrating the next Q bit in the memory.
         when CAL_SET_OVR =>
            if (set_ovr_done = '1' and data_stable = '1') then
               if (SIM_CAL_OPTION = "FAST_CAL") then
                  start_ctr_cal_d <= '0';
                  inc_q_d         <= '0';
                  cal_rise_d      <= '1';
                  cal_ns          <= CAL_SET_PHASE;
               else
                  start_ctr_cal_d <= '1';
                  inc_q_d         <= '1';
                  cal_rise_d      <= '1';
                  issue_dly_rst_d <= '1';
                  cal_ns          <= CAL_Q_RISE;
               end if;
            else
               start_ctr_cal_d <= '0';
               inc_q_d         <= '0';
               cal_rise_d      <= cal_rise;
               cal_ns          <= CAL_SET_OVR;
            end if;

         -- Determine the settings for the current Q being calibrated and if any
         -- adjustments to the previous Q's in the memory must be made.
         when CAL_QBIT_DET =>
            case cal_qbit_det_case is
               -- Settings for the current Q have been determined and adjustments
               -- to previous Q's are required. Load the C and Q values for the
               -- current Q before adjusting the previous Q's.
               when "11" =>
                  issue_load_c_d <= '1';
                  issue_load_q_d <= '1';
                  save_target_q  <= '1';
                  capture_adj    <= '1';
                  cal_ns         <= CAL_QBIT_SET;

               -- Settings for the current Q have been determined and no adjustments
               -- to the previous Q's are required.
               when "10" =>
                  issue_load_c_d <= q_mem_max;
                  issue_load_q_d <= '1';
                  save_target_q  <= '0';
                  capture_adj    <= '1';
                  cal_ns         <= CAL_QBIT_SET;
               
               -- Wait until the current Q settings are determined and if any prior
               -- Q adjustments are needed.
               when others =>
                  issue_load_c_d <= '0';
                  issue_load_q_d <= '0';
                  save_target_q  <= '0';
                  capture_adj    <= '0';
                  cal_ns         <= CAL_QBIT_DET;
            end case;

         -- Set the data tap delay for the current Q being calibrated.
         when CAL_QBIT_SET =>
            
            -- Data delay has been set and updates have completed. Continue on
            -- calibrating the next Q in the memory.  
            
            -- commented since XST is not mapping the logic correctly to LUTs
            --case cal_qbit_set_case is
            --   when "10100" =>
            --      clr_q           <= '0';
            --      start_ctr_cal_d <= '1';
            --      inc_q_d         <= '1';
            --      inc_cq_d        <= '0';
            --      issue_dly_rst_d <= '1';
            --      cal_ns          <= CAL_Q_RISE;
            --   
            --   -- Data delay has been set and updated have completed. There are no
            --   -- more Q's to calibrated.
            --   when "10110" =>
            --      clr_q           <= '0';
            --      start_ctr_cal_d <= '0';
            --      inc_q_d         <= '0';
            --      inc_cq_d        <= '0';
            --      cal_ns          <= CAL_DONE;
            --
            --   -- The final Q in the memory has been set. Proceed on to set the
            --   -- phase for the data alignment logic.
            --   when "11100" | "11110" =>
            --      clr_q           <= '0';
            --      start_ctr_cal_d <= '0';
            --      inc_q_d         <= '0';
            --      inc_cq_d        <= '0';
            --      cal_ns          <= CAL_SET_PHASE;
            --
            --   -- The C and Q values for the current Q be calibrated have been
            --   -- loaded. Adjustments are required for previous Q's.
            --   when "10101" | "11101" | "10111" | "11111" =>
            --      clr_q           <= '1';
            --      start_ctr_cal_d <= '0';
            --      inc_q_d         <= '0';
            --      inc_cq_d        <= '0';
            --      cal_ns          <= CAL_ADJ_REQ;
            --
            --   -- Wait for the data delay to be set and the updates to take effect.
            --   when others =>
            --      clr_q           <= '0';
            --      start_ctr_cal_d <= '0';
            --      inc_q_d         <= '0';
            --      inc_cq_d        <= '0';
            --      cal_ns          <= CAL_QBIT_SET;
            --end case;
            
            if (data_stable = '1' and qbit_set_done = '1') then
                     if (q_mem_max = '0' and cap_prev_adj_req = '0') then
                         if (q_bit_max = '0') then
                             clr_q           <= '0';        
                             start_ctr_cal_d <= '1';        
                             inc_q_d         <= '1';        
                             inc_cq_d        <= '0';        
                             issue_dly_rst_d <= '1';        
                             cal_ns          <= CAL_Q_RISE; 
                          else
                             clr_q           <= '0';     
                             start_ctr_cal_d <= '0';     
                             inc_q_d         <= '0';     
                             inc_cq_d        <= '0';     
                             cal_ns          <= CAL_DONE;  
                          end if;
                     elsif  (q_mem_max = '1' and cap_prev_adj_req = '0') then  
                           clr_q           <= '0';          
                           start_ctr_cal_d <= '0';          
                           inc_q_d         <= '0';          
                           inc_cq_d        <= '0';          
                           cal_ns          <= CAL_SET_PHASE;
                     elsif  (cap_prev_adj_req = '1') then
                           clr_q           <= '1';          
                           start_ctr_cal_d <= '0';          
                           inc_q_d         <= '0';          
                           inc_cq_d        <= '0';         
                           cal_ns          <= CAL_ADJ_REQ; 
                     end if;
             else
                 clr_q           <= '0';         
                 start_ctr_cal_d <= '0';         
                 inc_q_d         <= '0';         
                 inc_cq_d        <= '0';         
                 cal_ns          <= CAL_QBIT_SET;   
             end if;

         -- Data delay adjustments are required for previous Q's in the memory.
         when CAL_ADJ_REQ =>
            case cal_adj_req_case is
               -- The values for the current Q have been loaded and completed
               -- updating and all previous Q's have been adjusted. It is not
               -- necessary to wait for the settings of those previous Q's to
               -- update since they do not affect other Q's. There are additional
               -- Q's to calibrate within the memory.
               when "101110" | "101111" =>
                  start_ctr_cal_d <= '1';
                  inc_q_d         <= '1';
                  inc_cq_d        <= '0';
                  start_adj       <= '0';
                  issue_dly_rst_d <= '1';
                  cal_ns          <= CAL_Q_RISE;
               
               -- All Q's in the memory have been adjusted. Proceed on to set the
               -- phase for the data alignment.
               when "111111" =>
                  start_ctr_cal_d <= '0';
                  inc_q_d         <= '0';
                  inc_cq_d        <= '0';
                  start_adj       <= '0';
                  cal_ns          <= CAL_SET_PHASE;

               -- After the Q bit setting has stabilized, proceed to adjust the data
               -- delay for that bit.
               when "100010" | "110010" | "100110" | "110110" | "100011" | "110011" | "100111" | "110111" =>
                  start_ctr_cal_d <= '0';
                  inc_q_d         <= '0';
                  inc_cq_d        <= '0';
                  start_adj       <= '1';
                  cal_ns          <= CAL_ADJ;

               -- Wait until either all previous Q's have been adjusted or when the
               -- target Q being adjusted for has had time to update.
               when others =>
                  start_ctr_cal_d <= '0';
                  inc_q_d         <= '0';
                  inc_cq_d        <= '0';
                  start_adj       <= '0';
                  cal_ns          <= CAL_ADJ_REQ;
            end case;

         -- Adjust the data tap delay for the target Q. This handles adding data
         -- delay for previous Q's when required. After the complete data delay
         -- has been added for the target Q, continue to check if there are other
         -- Q's that need adjusting.
         when CAL_ADJ =>
            if (q_bit_adj_done = '1') then
               inc_q_d <= '1';
               cal_ns  <= CAL_ADJ_REQ;
            else
               inc_q_d <= '0';
               cal_ns  <= CAL_ADJ;
            end if;
         
         -- Set the proper phase for the data alignment logic. If there are
         -- additional memories to calibrate, continue on to them otherwise
         -- calibration is complete. Finish calibration when
         -- SIM_CAL_OPTION="SKIP_CAL.
         when CAL_SET_PHASE =>
            if (SIM_CAL_OPTION = "NONE") then
               start_ctr_cal_d   <= not(q_bit_max);
               inc_cq_d          <= not(q_bit_max);
               inc_q_d           <= not(q_bit_max);
               next_q_grp_d      <= '0';
               clear_clk_invert  <= not(q_bit_max);
               cal_ns            <= set_phase_next_none;
               
            elsif (SIM_CAL_OPTION = "FAST_CAL") then
              if (cq_num_sig /= NUM_DEVICES-1) then
                start_ctr_cal_d  <= '1';
                inc_cq_d         <= '1';
                clear_clk_invert <= '1';
                inc_q_d          <= '1';
                next_q_grp_d     <= '1';
              else
                start_ctr_cal_d  <= '0';
                inc_cq_d         <= '0';
                clear_clk_invert <= '0';
                inc_q_d          <= '0';
                next_q_grp_d     <= '0';
              end if; 
              cal_ns           <= set_phase_next_fast;
              
            elsif (SIM_CAL_OPTION = "SKIP_CAL") then
               start_ctr_cal_d  <= '0';
               inc_cq_d         <= '0';
               inc_q_d          <= '0';
               next_q_grp_d     <= '0';
               clear_clk_invert <= '0';
               cal_ns           <= CAL_DONE;
            end if;
         
         -- Delay calibration is complete.
         when CAL_DONE =>
            cal_ns <= CAL_DONE;
         
         when others =>
            cal_ns <= CAL_IDLE;
      end case;
   end process;
   
   
   -- Indicate that stage 2 calibration should begin after stage one calibration
   -- is complete.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cal_stage2_start <= '0' after TCQ*1 ps;
         elsif (cal_ns = CAL_DONE) then
            cal_stage2_start <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Extend the tap centering start signal to three cycles. This is necessary
   -- to both exit the DONE state and proceed through the IDLE state.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            start_ctr_cal_int_r  <= '0' after TCQ*1 ps;
            start_ctr_cal_int_2r <= '0' after TCQ*1 ps;
         else
            start_ctr_cal_int_r  <= start_ctr_cal_int after TCQ*1 ps;
            start_ctr_cal_int_2r <= start_ctr_cal_int_r after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            start_ctr_cal <= '0' after TCQ*1 ps;
         else
            start_ctr_cal <= start_ctr_cal_int or start_ctr_cal_int_r or start_ctr_cal_int_2r after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Wait to begin centering state machine until q_bit_rdy and c_num_rdy are
   -- asserted. This is necessary to allow time to mux in new data based on
   -- q_bit.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            start_ctr_cal_hold <= '0' after TCQ*1 ps;
         elsif (start_ctr_cal = '1') then
            start_ctr_cal_hold <= '1' after TCQ*1 ps;
         elsif (start_ctr_cal_rdy = '1') then
            start_ctr_cal_hold <= '0' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            start_ctr_cal_rdy <= '0' after TCQ*1 ps;
         elsif (start_ctr_cal_hold = '1') then
            start_ctr_cal_rdy <= q_bit_rdy and c_num_rdy and rst_done and polarity_done after TCQ*1 ps;
         elsif (start_ctr_cal_hold = '0') then
            start_ctr_cal_rdy <= '0' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate when the start is active which will be used to gate the checking
   -- of ctr_done_sig.
   start_in_progress <= start_ctr_cal_int or start_ctr_cal;
   
   -- Save the results from the tap centering state machine for the rising edge
   -- data.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            re_cdt_selected      <= '0' after TCQ*1 ps;
            re_optimal_tap       <= (others =>'0') after TCQ*1 ps;
            re_tap_offset        <= (others =>'0') after TCQ*1 ps;
            re_true_center       <= '0' after TCQ*1 ps;
            re_start_left0       <= '0' after TCQ*1 ps;
            re_left0_tap         <= (others =>'0') after TCQ*1 ps;
            re_window_size0      <= '0' after TCQ*1 ps;
            re_qmem0_left0_tap   <= (others =>'0') after TCQ*1 ps;
            re_qmem0_right_tap   <= (others =>'0') after TCQ*1 ps;
            re_qmem0_left1_tap   <= (others =>'0') after TCQ*1 ps;
            re_qmem0_found_left0 <= '0' after TCQ*1 ps;
            re_qmem0_found_right <= '0' after TCQ*1 ps;
            re_qmem0_found_left1 <= '0' after TCQ*1 ps;
            re_qmem0_cdt_max     <= '0' after TCQ*1 ps;
            re_qmem0_qdt_max     <= '0' after TCQ*1 ps;
            re_qmem0_opp_first   <= '0' after TCQ*1 ps;
            re_qmem0_start_left0 <= '0' after TCQ*1 ps;
         elsif (cal_rise ='1' and save_rise_edge = '1') then
            re_cdt_selected      <= cdt_selected after TCQ*1 ps;
            re_optimal_tap       <= optimal_tap after TCQ*1 ps;
            re_tap_offset        <= tap_offset after TCQ*1 ps;
            re_true_center       <= true_center after TCQ*1 ps;
            re_start_left0       <= start_left0 after TCQ*1 ps;
            re_left0_tap         <= left0_tap after TCQ*1 ps;
            re_window_size0      <= bool_to_std_logic(window_size = "000000") after TCQ*1 ps;
            re_qmem0_left0_tap   <= q0mem_left0_tap after TCQ*1 ps;
            re_qmem0_right_tap   <= q0mem_right_tap after TCQ*1 ps;
            re_qmem0_left1_tap   <= q0mem_left1_tap after TCQ*1 ps;
            re_qmem0_found_left0 <= q0mem_found_left0 after TCQ*1 ps;
            re_qmem0_found_right <= q0mem_found_right after TCQ*1 ps;
            re_qmem0_found_left1 <= q0mem_found_left1 after TCQ*1 ps;
            re_qmem0_cdt_max     <= q0mem_cdt_max after TCQ*1 ps;
            re_qmem0_qdt_max     <= q0mem_qdt_max after TCQ*1 ps;
            re_qmem0_opp_first   <= q0mem_opp_first after TCQ*1 ps;
            re_qmem0_start_left0 <= q0mem_start_left0 after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate when rising edge has been captured.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            re_captured <= '0' after TCQ*1 ps;
         else
            re_captured <= cal_rise and save_rise_edge after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Save the results from the tap centering state machine for the rising edge
   -- data now with the clk/clkb inputs to the ISERDES inverted.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            rei_cdt_selected        <= '0' after TCQ*1 ps;
            rei_optimal_tap         <= (others =>'0') after TCQ*1 ps;
            rei_true_center         <= '0' after TCQ*1 ps;
            rei_start_left0         <= '0' after TCQ*1 ps;
            rei_left0_tap           <= (others =>'0') after TCQ*1 ps;
            rei_window_size0        <= '0' after TCQ*1 ps;
            rei_qmem0_left0_tap     <= (others =>'0') after TCQ*1 ps;
            rei_qmem0_right_tap     <= (others =>'0') after TCQ*1 ps;
            rei_qmem0_left1_tap     <= (others =>'0') after TCQ*1 ps;
            rei_qmem0_found_left0   <= '0' after TCQ*1 ps;
            rei_qmem0_found_right   <= '0' after TCQ*1 ps;
            rei_qmem0_found_left1   <= '0' after TCQ*1 ps;
            rei_qmem0_cdt_max       <= '0' after TCQ*1 ps;
            rei_qmem0_qdt_max       <= '0' after TCQ*1 ps;
            rei_qmem0_opp_first     <= '0' after TCQ*1 ps;
            rei_qmem0_start_left0   <= '0' after TCQ*1 ps;
         elsif ((cal_rise and save_rise_edge_inv) = '1') then
            rei_cdt_selected        <= cdt_selected after TCQ*1 ps;
            rei_optimal_tap         <= optimal_tap after TCQ*1 ps;
            rei_true_center         <= true_center after TCQ*1 ps;
            rei_start_left0         <= start_left0 after TCQ*1 ps;
            rei_left0_tap           <= left0_tap after TCQ*1 ps;
            rei_window_size0        <= bool_to_std_logic((window_size = "000000")) after TCQ*1 ps;
            rei_qmem0_left0_tap     <= q0mem_left0_tap after TCQ*1 ps;
            rei_qmem0_right_tap     <= q0mem_right_tap after TCQ*1 ps;
            rei_qmem0_left1_tap     <= q0mem_left1_tap after TCQ*1 ps;
            rei_qmem0_found_left0   <= q0mem_found_left0 after TCQ*1 ps;
            rei_qmem0_found_right   <= q0mem_found_right after TCQ*1 ps;
            rei_qmem0_found_left1   <= q0mem_found_left1 after TCQ*1 ps;
            rei_qmem0_cdt_max       <= q0mem_cdt_max after TCQ*1 ps;
            rei_qmem0_qdt_max       <= q0mem_qdt_max after TCQ*1 ps;
            rei_qmem0_opp_first     <= q0mem_opp_first after TCQ*1 ps;
            rei_qmem0_start_left0   <= q0mem_start_left0 after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate when rising edge using inverted ISERDES clock has been captured.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            rei_captured <= '0' after TCQ*1 ps;
         else
            rei_captured <= cal_rise and save_rise_edge_inv after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Save the results from the tap centering state machine for the falling edge
   -- data using the optimal clock polarity from the rising edge calibration.
   -- For RLDRAM, there is no separate falling edge capture and hence the rising edge
   -- signals are assigned.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            fe_cdt_selected   <= '0' after TCQ*1 ps;
            fe_optimal_tap    <= (others =>'0') after TCQ*1 ps;
         elsif (cal_rise = '1' and save_rise_edge = '1' and MEMORY_TYPE = "RLD2") then
            fe_cdt_selected   <= cdt_selected after TCQ*1 ps;
            fe_optimal_tap    <= optimal_tap after TCQ*1 ps;
         elsif (cal_rise = '1' and save_rise_edge_inv = '1' and MEMORY_TYPE = "RLD2") then
            fe_cdt_selected   <= cdt_selected after TCQ*1 ps;
            fe_optimal_tap    <= optimal_tap after TCQ*1 ps;		
         elsif (cal_rise = '0' and save_fall_edge = '1') then
            fe_cdt_selected   <= cdt_selected after TCQ*1 ps;
            fe_optimal_tap    <= optimal_tap after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate when falling edge has been captured.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            fe_captured <= '0' after TCQ*1 ps;
         elsif (MEMORY_TYPE = "RLD2" and cq_num_rst_sig = '1') then
            fe_captured <= '1';
         else
            fe_captured <= not(cal_rise) and save_fall_edge after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Save results from the tap centering state machine for the subsequent bits
   -- following Q0 from each memory. This will be for the rising edge data using
   -- the previously determined clock inversion.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            curr_cdt_selected <= '0' after TCQ*1 ps;
            curr_optimal_tap <= (others =>'0') after TCQ*1 ps;
         elsif (save_current = '1') then
            curr_cdt_selected <= cdt_selected after TCQ*1 ps;
            curr_optimal_tap <= optimal_tap after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate when current Q has been captured.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            curr_captured <= '0' after TCQ*1 ps;
         else
            curr_captured <= save_current after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- }}} end Overall Calibration Control --------
   
   -- {{{ Determine Optimal Q0 Tap Setting -------
   
   -- Determine optimal edge setting between using the non-inverted clk/clkb
   -- inputs to the ISERDES versus the inverted clks (if applicable). The best
   -- option is the one that can find the exact middle (or closest) with
   -- priority given to clock delay over data (because of the better jitter
   -- characteristics).
   
   -- Determine if the settings were able to find the middle
   tap_offset0 <= bool_to_std_logic(tap_offset = "00000");
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            re_tap_off0 <= '0' after TCQ*1 ps;
         elsif (cal_rise = '1' and save_rise_edge = '1') then
            re_tap_off0 <= tap_offset0 after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            rei_tap_off0 <= '0' after TCQ*1 ps;
         elsif (cal_rise = '1' and save_rise_edge_inv = '1') then
            rei_tap_off0 <= tap_offset0 after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Determine if the rising edge clock/data was closer to the middle of the
   -- eye than the rising clock/data using clk/clkb ISERDES inversion.
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            re_better_tap_off <= '1' after TCQ*1 ps;
         elsif (cal_rise = '1' and save_rise_edge = '1') then
            re_better_tap_off <= '1' after TCQ*1 ps;
         elsif (cal_rise = '1' and save_rise_edge_inv = '1') then
            re_better_tap_off <= bool_to_std_logic((re_tap_offset <= tap_offset)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   sel_best_taps_case <= (re_cdt_selected & rei_cdt_selected & re_tap_off0 & rei_tap_off0 & 
                          re_true_center & rei_true_center & re_window_size0 & 
                          rei_window_size0 & re_better_tap_off);

   -- Select best setting
   process (re_cdt_selected, rei_cdt_selected, re_tap_off0, rei_tap_off0, 
            re_true_center, rei_true_center, re_window_size0, rei_window_size0,
            re_better_tap_off, re_captured, rei_captured, sel_best_taps_case)
   begin
      
      case sel_best_taps_case is
         -- Delaying the clock without any inversion found exact middle    
         
         when "101010000" | "111010000" | "101110000" | "111110000" | 
              "101011000" | "111011000" | "101111000" | "111111000" | 
              "101010100" | "111010100" | "101110100" | "111110100" | 
              "101011100" | "111011100" | "101111100" | "111111100" | 
              "101010010" | "111010010" | "101110010" | "111110010" | 
              "101011010" | "111011010" | "101111010" | "111111010" | 
              "101010110" | "111010110" | "101110110" | "111110110" | 
              "101011110" | "111011110" | "101111110" | "111111110" | 
              "101010001" | "111010001" | "101110001" | "111110001" | 
              "101011001" | "111011001" | "101111001" | "111111001" | 
              "101010101" | "111010101" | "101110101" | "111110101" | 
              "101011101" | "111011101" | "101111101" | "111111101" | 
              "101010011" | "111010011" | "101110011" | "111110011" | 
              "101011011" | "111011011" | "101111011" | "111111011" | 
              "101010111" | "111010111" | "101110111" | "111110111" | 
              "101011111" | "111011111" | "101111111" | "111111111" =>
            invert_clk_d         <= '0';
            rise_cdt_delayed_d   <= '1';
            det_opt_done_d       <= re_captured;
            det_opt_setting_d    <= "0000";
            
            
           -- Delaying the clock with inversion found exact middle (rising edge data
         -- delay was used)
         when "010101000" | "110101000" | "011101000" | "111101000" | 
              "010101100" | "110101100" | "011101100" | "111101100" | 
              "010101010" | "110101010" | "011101010" | "111101010" | 
              "010101110" | "110101110" | "011101110" | "111101110" | 
              "010101001" | "110101001" | "011101001" | "111101001" | 
              "010101101" | "110101101" | "011101101" | "111101101" | 
              "010101011" | "110101011" | "011101011" | "111101011" | 
              "010101111" | "110101111" | "011101111" | "111101111" |
              "010111000" | "011111000" | "010111100" | "011111100" | 
              "010111010" | "011111010" | "010111110" | "011111110" | 
              "010111001" | "011111001" | "010111101" | "011111101" | 
              "010111011" | "011111011" | "010111111" | "011111111" =>
            invert_clk_d         <= '1';
            rise_cdt_delayed_d   <= '1';
            det_opt_done_d       <= rei_captured;
            det_opt_setting_d    <= "0001";        
         
-- Delaying the clock without any inversion found approximate middle
-- (rising edge with inversion was not able to find the exact middle)
--when "010101000" | "011101000" | "010111000" | "011111000" | 
--     "010101100" | "011101100" | "010111100" | "011111100" | 
--     "010101010" | "011101010" | "010111010" | "011111010" | 
--     "010101110" | "011101110" | "010111110" | "011111110" | 
--     "010101001" | "011101001" | "010111001" | "011111001" | 
--     "010101101" | "011101101" | "010111101" | "011111101" | 
--     "010101011" | "011101011" | "010111011" | "011111011" | 
--     "010101111" | "011101111" | "010111111" | "011111111" =>
--   invert_clk_d         <= '1';
--   rise_cdt_delayed_d   <= '1';
--   det_opt_done_d       <= rei_captured;
--   det_opt_setting_d    <= "0010";
-- Delaying the clock without any inversion found approximate middle
-- (rising edge with inversion used data delay)
         when "101000000" | "111000000" | "101100000" | "111100000" | 
              "101000100" | "111000100" | "101100100" | "111100100" | 
              "101000010" | "111000010" | "101100010" | "111100010" | 
              "101000110" | "111000110" | "101100110" | "111100110" | 
              "101000001" | "111000001" | "101100001" | "111100001" | 
              "101000101" | "111000101" | "101100101" | "111100101" | 
              "101000011" | "111000011" | "101100011" | "111100011" | 
              "101000111" | "111000111" | "101100111" | "111100111" |
              "101001000" | "101101000" | "101001100" | "101101100" | 
              "101001010" | "101101010" | "101001110" | "101101110" | 
              "101001001" | "101101001" | "101001101" | "101101101" | 
              "101001011" | "101101011" | "101001111" | "101101111" =>
            invert_clk_d         <= '0';
            rise_cdt_delayed_d   <= '1';
            det_opt_done_d       <= rei_captured;
            det_opt_setting_d    <= "0011";
         -- Delaying the clock with inversion found approximate middle (rising
         -- edge clock or data delay was not able to find approximate middle)
--         when "101000000" | "101100000" | "101001000" | "101101000" | 
--              "101000100" | "101100100" | "101001100" | "101101100" | 
--              "101000010" | "101100010" | "101001010" | "101101010" | 
--              "101000110" | "101100110" | "101001110" | "101101110" | 
--              "101000001" | "101100001" | "101001001" | "101101001" | 
--              "101000101" | "101100101" | "101001101" | "101101101" | 
--              "101000011" | "101100011" | "101001011" | "101101011" | 
--              "101000111" | "101100111" | "101001111" | "101101111" =>
--            invert_clk_d         <= '0';
--            rise_cdt_delayed_d   <= '1';
--            det_opt_done_d       <= rei_captured;
--            det_opt_setting_d    <= "0100";
         -- Delaying the clock with inversion found approximate middle (rising
         -- edge used data delay)
         when "010100000" | "110100000" | "010100100" | "110100100" | 
              "010100010" | "110100010" | "010100110" | "110100110" | 
              "010100001" | "110100001" | "010100101" | "110100101" | 
              "010100011" | "110100011" | "010100111" | "110100111" |
             "011100000" | "010110000" | "011110000" | "011100100" | 
             "010110100" | "011110100" | "011100010" | "010110010" | 
             "011110010" | "011100110" | "010110110" | "011110110" | 
             "011100001" | "010110001" | "011110001" | "011100101" | 
             "010110101" | "011110101" | "011100011" | "010110011" | 
             "011110011" | "011100111" | "010110111" | "011110111" =>
            invert_clk_d         <= '1';
            rise_cdt_delayed_d   <= '1';
            det_opt_done_d       <= rei_captured;
            det_opt_setting_d    <= "0101";
         -- Delaying the clock without any inversion got closest to middle (rising
         -- edge with inversion was not able to get closer to middle)
--         when "010100000" | "011100000" | "010110000" | "011110000" | 
--              "010100100" | "011100100" | "010110100" | "011110100" | 
--              "010100010" | "011100010" | "010110010" | "011110010" | 
--              "010100110" | "011100110" | "010110110" | "011110110" | 
--              "010100001" | "011100001" | "010110001" | "011110001" | 
--              "010100101" | "011100101" | "010110101" | "011110101" | 
--              "010100011" | "011100011" | "010110011" | "011110011" | 
--              "010100111" | "011100111" | "010110111" | "011110111" =>
--            invert_clk_d         <= '1';
--            rise_cdt_delayed_d   <= '1';
--            det_opt_done_d       <= rei_captured;
--            det_opt_setting_d    <= "0110";
         -- Delaying the clock without any inversion got closest to middle (rising
         -- edge with inversion used data delay)
         when "100000001" | "110000001" | "100010001" | "110010001" | 
              "100001001" | "110001001" | "100011001" | "110011001" | 
              "100000011" | "110000011" | "100010011" | "110010011" | 
              "100001011" | "110001011" | "100011011" | "110011011" | 
              "100000000" | "100100000" | "100010000" | "100110000" | 
              "100001000" | "100101000" | "100011000" | "100111000" | 
              "100000010" | "100100010" | "100010010" | "100110010" | 
              "100001010" | "100101010" | "100011010" | "100111010" | 
              "100100001" | "100110001" | "100101001" | "100111001" | 
              "100100011" | "100110011" | "100101011" | "100111011" =>
            invert_clk_d         <= '0';
            rise_cdt_delayed_d   <= '1';
            det_opt_done_d       <= rei_captured;
            det_opt_setting_d    <= "0111";
         -- Delaying the clock with inversion got closest to middle (rising edge
         -- clock or data delay was not able to get closer to the middle)
--         when "100000000" | "100100000" | "100010000" | "100110000" | 
--              "100001000" | "100101000" | "100011000" | "100111000" | 
--              "100000010" | "100100010" | "100010010" | "100110010" | 
--              "100001010" | "100101010" | "100011010" | "100111010" | 
--              "100000001" | "100100001" | "100010001" | "100110001" | 
--              "100001001" | "100101001" | "100011001" | "100111001" | 
--              "100000011" | "100100011" | "100010011" | "100110011" | 
--              "100001011" | "100101011" | "100011011" | "100111011" =>
--            invert_clk_d         <= '0';
--            rise_cdt_delayed_d   <= '1';
--            det_opt_done_d       <= rei_captured;
--            det_opt_setting_d    <= "1000";
         -- Delaying the clock with inversion got closest to middle (rising edge
         -- used data delay)
         when "010000000" | "110000000" | "010010000" | "110010000" | 
              "010001000" | "110001000" | "010011000" | "110011000" | 
              "010000100" | "110000100" | "010010100" | "110010100" | 
              "010001100" | "110001100" | "010011100" | "110011100" |
              "011000000" | "011010000" | "011001000" | "011011000" | 
              "011000100" | "011010100" | "011001100" | "011011100" | 
              "010000001" | "011000001" | "010010001" | "011010001" | 
              "010001001" | "011001001" | "010011001" | "011011001" | 
              "010000101" | "011000101" | "010010101" | "011010101" | 
              "010001101" | "011001101" | "010011101" | "011011101" =>
            invert_clk_d         <= '1';
            rise_cdt_delayed_d   <= '1';
            det_opt_done_d       <= rei_captured;
            det_opt_setting_d    <= "1001";
         -- Default to delaying data with better tap offset. This is a last resort.
--         when "010000000" | "011000000" | "010010000" | "011010000" | 
--              "010001000" | "011001000" | "010011000" | "011011000" | 
--              "010000100" | "011000100" | "010010100" | "011010100" | 
--              "010001100" | "011001100" | "010011100" | "011011100" | 
--              "010000001" | "011000001" | "010010001" | "011010001" | 
--              "010001001" | "011001001" | "010011001" | "011011001" | 
--              "010000101" | "011000101" | "010010101" | "011010101" | 
--              "010001101" | "011001101" | "010011101" | "011011101" =>
--            invert_clk_d         <= '1';
--            rise_cdt_delayed_d   <= '1';
--            det_opt_done_d       <= rei_captured;
--            det_opt_setting_d    <= "1010";
         when others =>
            invert_clk_d         <= not(re_better_tap_off);
            rise_cdt_delayed_d   <= '0';
            det_opt_done_d       <= rei_captured;
            det_opt_setting_d    <= "1011";
      end case;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            invert_clk        <= '0' after TCQ*1 ps;
            rise_cdt_delayed  <= '1' after TCQ*1 ps;
            det_opt_done      <= '0' after TCQ*1 ps;
            det_opt_setting   <= "0000" after TCQ*1 ps;
         else
            invert_clk        <= invert_clk_d after TCQ*1 ps;
            rise_cdt_delayed  <= rise_cdt_delayed_d after TCQ*1 ps;
            det_opt_done      <= det_opt_done_d after TCQ*1 ps;
            det_opt_setting   <= det_opt_setting_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- }}} end Determine Optimal Q0 Tap Setting ---
   
   -- {{{ Set Overall Q0 Tap Setting -------------
   
   -- Set overall Q0 tap setting. If both rise and fall edge data used clock
   -- delays to center, then no adjustments are needed as both CQ and CQ# can
   -- be independently controlled. However, if data delay is required for either
   -- or both, then the clocks will need to be adjusted as well since delaying
   -- the data for one edge affects the other edge.
   
   rise_optimal_tap <= rei_optimal_tap when (invert_clk = '1') else
                       re_optimal_tap;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_qdly_larger <= '0' after TCQ*1 ps;
            fe_captured_r  <= '0' after TCQ*1 ps;
         else
            cq_qdly_larger <= bool_to_std_logic(rise_optimal_tap > fe_optimal_tap) after TCQ*1 ps;
            fe_captured_r  <= fe_captured after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   adj_case <= (MEM_TYPE_RLD & rise_cdt_delayed & fe_cdt_selected & cq_qdly_larger);

   process (rise_cdt_delayed, fe_cdt_selected, cq_qdly_larger, 
            rise_optimal_tap, fe_optimal_tap, adj_case)
   begin
      -- Both CQ and CQ# are centered with clock delay only. No adjustment is
      -- required.
      case adj_case is
         -- RLD case where clocks are centered with clock delay only.
         when"1100" | "1110" | "1101" | "1111" =>
            cq_num_load_val_d   <= rise_optimal_tap;
            cqn_num_load_val_d  <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS));
            q_bit_load_val_d    <= (others => '0');
         -- RLD case where clocks are centered with data delay only.
         when "1000" | "1010" | "1001" | "1011" =>
            cq_num_load_val_d   <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS));
            cqn_num_load_val_d  <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS));
            q_bit_load_val_d    <= rise_optimal_tap;
         -- Both CQ and CQ# are centered with clock delay only. No adjustment is
         -- required.
         when "0110" | "0111" => 
            cq_num_load_val_d   <= rise_optimal_tap;
            cqn_num_load_val_d  <= fe_optimal_tap;
            q_bit_load_val_d    <= (others => '0');
         -- CQ can be centered with clock delay but CQ# requires data delay. Thus
         -- the CQ clock delay must be adjusted further to account for the Q being
         -- delayed.
         when "0100" | "0101" =>
            cq_num_load_val_d    <= rise_optimal_tap + fe_optimal_tap;
            cqn_num_load_val_d   <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS));
            q_bit_load_val_d     <= fe_optimal_tap;
         -- CQ# can be centered with clock delay but CQ requires data delay. Thus
         -- the CQ# clock delay must be adjusted further to account for the Q
         -- being delayed   
         when "0010" | "0011" =>
            cq_num_load_val_d    <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS));
            cqn_num_load_val_d   <= fe_optimal_tap + rise_optimal_tap;
            q_bit_load_val_d     <= rise_optimal_tap;
         -- Both CQ and CQ# required data delays and the CQ data delay is larger
         -- than the data delay for CQ#. CQ# clock delay must be adjusted to
         -- account for larger Q delay.   
         when "0001" =>
            cq_num_load_val_d    <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS));
            cqn_num_load_val_d   <= rise_optimal_tap - fe_optimal_tap;
            q_bit_load_val_d     <= rise_optimal_tap;
         -- Both CQ and CQ# required data delays and the CQ# data delay is larger
         -- than the data delay for CQ. CQ clock delay must be adjusted to
         -- account for larger Q delay.
         when others => 
            cq_num_load_val_d    <= fe_optimal_tap - rise_optimal_tap;
            cqn_num_load_val_d   <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS));
            q_bit_load_val_d     <= fe_optimal_tap;
      end case;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_num_load_val   <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
            cqn_num_load_val  <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
            q_bit_load_val    <= (others => '0') after TCQ*1 ps;
         else
            cq_num_load_val   <= cq_num_load_val_d after TCQ*1 ps;
            cqn_num_load_val  <= cqn_num_load_val_d after TCQ*1 ps;
            q_bit_load_val    <= q_bit_load_val_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate when the overall Q0 settings have been determined.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            det_ovr_done <= '0' after TCQ*1 ps;
         else
            det_ovr_done <= fe_captured_r after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Save the left0 info for the first bit in the memory that indicate if the
   -- first bit initially found the left0 edge of the eye and what the tap
   -- setting was of that left0 edge.
   qmem0_start_left0_d <= rei_start_left0 when (invert_clk = '1') else
                          re_start_left0;
   qmem0_left0_tap_d   <= rei_left0_tap when (invert_clk = '1') else
                          re_left0_tap;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            qmem0_start_left0 <= '0' after TCQ*1 ps;
            qmem0_left0_tap   <= (others =>'0') after TCQ*1 ps;
         elsif (q_mem_0 = '1') then
            qmem0_start_left0 <= qmem0_start_left0_d after TCQ*1 ps;
            qmem0_left0_tap   <= qmem0_left0_tap_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Setting the overall Q0 tap settings is complete once the tap values have
   -- been loaded and reset and the data has allowed to settle.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            set_ovr_st     <= '0' after TCQ*1 ps;
            set_ovr_done   <= '0' after TCQ*1 ps;
         else
            set_ovr_st     <= bool_to_std_logic((cal_cs = CAL_SET_OVR)) after TCQ*1 ps;
            set_ovr_done   <= set_ovr_st and load_done and rst_done and polarity_done after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- }}} end Set Overall Q0 Tap Setting ---------
   
   -- {{{ Determine Q_bit Tap Settings -----------
   
   -- As additional Q bits are calibrated against following the first bit of the
   -- memory, adjustments may be required to all previous bits if more clock
   -- delay is needed than had previously been set.
   new_cdt_larger <= bool_to_std_logic((curr_optimal_tap > cq_tap));
   
   -- Current q bit setting - existing cq setting
   curr_minus_cq <= curr_optimal_tap - cq_tap;
   
   -- Existing cqn setting + current q bit setting - existing cq setting
   cqn_plus_curr_minus_cq <= ('0' & cqn_tap + curr_optimal_tap - cq_tap);
   
   -- Determine if cqn_tap will overflow when existing cqn setting is added to
   -- q setting for current bit minus existing cq setting
   cqn_tap_overflow <= bool_to_std_logic(cqn_plus_curr_minus_cq > "011111");
   
   -- cq setting plus q setting for current bit
   --cq_plus_curr <= ('0' & cq_tap + curr_optimal_tap);
   cq_plus_curr <=  ('0' & curr_optimal_tap);
   
   -- Determine if q_tap will overflow when desired q setting plus the existing
   -- cq setting are added
   q_tap_overflow <= bool_to_std_logic(cq_plus_curr > "011111");
   
   cqn_tap_d_sel  <= "11111" when (cqn_tap_overflow = '1') else
                     cqn_plus_curr_minus_cq(4 downto 0);
   q_tap_d_sel    <= "11111" when (q_tap_overflow = '1') else
                     cq_plus_curr(4 downto 0);
            
   new_cdt_case <= (curr_cdt_selected & new_cdt_larger);

   process (curr_cdt_selected, new_cdt_larger, curr_optimal_tap, 
            cq_tap, cqn_tap_overflow, cqn_plus_curr_minus_cq, cqn_tap, 
            q_tap_overflow, cq_plus_curr, new_cdt_case, cqn_tap_d_sel, 
            q_tap_d_sel)
   begin
      case new_cdt_case is
      
         -- Current Q calibration requires clock delay larger than what was needed
         -- for previously calibrated bits. Data delay must be added to previous
         -- bits to account for larger clock delay.
         when "11" =>
            prev_q_adj_d   <= curr_optimal_tap - cq_tap;
            q_tap_d        <= "00000";
            cq_tap_d       <= curr_optimal_tap;
            cqn_tap_d      <= cqn_tap_d_sel;
            prev_adj_req_d <= '1';
            
         -- Current Q calibration requires less clock delay that what was needed
         -- for previously calibrated bits. Data delay must be added to the
         -- current bit to account for larger clock delay.
         when "10" =>
            prev_q_adj_d   <= "00000";
            q_tap_d        <= cq_tap - curr_optimal_tap;
            cq_tap_d       <= cq_tap;
            cqn_tap_d      <= cqn_tap;
            prev_adj_req_d <= '0';

         -- Current Q calibration requires data delay only. No other adjustments
         -- are required since data delay only affects this bit.
         when "00" | "01" =>
            prev_q_adj_d   <= "00000";
            q_tap_d        <= q_tap_d_sel;
            cq_tap_d       <= cq_tap;
            cqn_tap_d      <= cqn_tap;
            prev_adj_req_d <= '0';
            
         when others =>
            prev_q_adj_d   <= "XXXXX";
            q_tap_d        <= "XXXXX";
            cq_tap_d       <= "XXXXX";
            cqn_tap_d      <= "XXXXX";
            prev_adj_req_d <= 'X';
      end case;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            prev_adj_req <= '0' after TCQ*1 ps;
         else
            prev_adj_req <= prev_adj_req_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            prev_q_adj        <= (others =>'0') after TCQ*1 ps;
            cap_prev_adj_req  <= '0' after TCQ*1 ps;
         elsif (capture_adj = '1') then
            prev_q_adj        <= prev_q_adj_d after TCQ*1 ps;
            cap_prev_adj_req  <= prev_adj_req after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- For CQ/CQ#, initial values are loaded from values determined during the Q0
   -- calibration. After that values from the adjustment logic are used.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_tap   <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
            cqn_tap  <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
         elsif (load_init = '1') then
            cq_tap   <= cq_num_load_val after TCQ*1 ps;
            cqn_tap  <= cqn_num_load_val after TCQ*1 ps;
         elsif (capture_adj = '1') then
            cq_tap   <= cq_tap_d after TCQ*1 ps;
            cqn_tap  <= cqn_tap_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- For Q, initial values are loaded from values determined during the Q0
   -- calibration. After that values from the adjustment logic are used.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_tap <= (others =>'0') after TCQ*1 ps;
         elsif (load_init = '1') then
            q_tap <= q_bit_load_val after TCQ*1 ps;
         elsif (capture_adj = '1') then
            q_tap <= q_tap_d after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate when the current Q tap settings have been determined.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            qbit_det_done <= '0' after TCQ*1 ps;
         else
            qbit_det_done <= curr_captured after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- }}} end Determine Q_bit Tap Settings -------
   
   -- {{{ Set Q_bit Tap Settings -----------------
   
   -- In the case that only the current Q needs the tap set and no adjustment is
   -- needed for previous bits, the step is complete once the tap values have
   -- been loaded and reset and the data has allowed to settle.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            qbit_set_st <= '0' after TCQ*1 ps;
         else
            qbit_set_st <= bool_to_std_logic((cal_cs = CAL_QBIT_SET)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            qbit_set_done <= '0' after TCQ*1 ps;
         else
            qbit_set_done <= qbit_set_st and load_done and rst_done after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Otherwise, the previous bits do require adjusting.
   
   -- Save the current Q bit being worked on before reseting it to adjust
   -- previous bits.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            target_q <= (others => '0') after TCQ*1 ps;
         elsif (save_target_q = '1') then
            target_q <= q_bit_sig after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Issue an enable to adjust the Q tap setting for previous bits by enabling
   -- the increment (asserting clock enable) for the number of cycles needed to
   -- adjust. Adjustments are complete once the target Q has been adjusted by
   -- the desired number of taps.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_adj_val      <= (others =>'0') after TCQ*1 ps;
            q_bit_adj_done <= '0' after TCQ*1 ps;
         elsif (start_adj = '1') then
            q_adj_val      <= prev_q_adj after TCQ*1 ps;
            q_bit_adj_done <= '0' after TCQ*1 ps;
         elsif (q_adj_val = "00000") then
            q_adj_val      <= (others =>'0') after TCQ*1 ps;
            q_bit_adj_done <= '1' after TCQ*1 ps;
         else
            q_adj_val      <= q_adj_val - "00001" after TCQ*1 ps;
            q_bit_adj_done <= '0' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   adjust_q <= or_br(q_adj_val) and bool_to_std_logic(cal_cs = CAL_ADJ);
   
   -- Indicate when all previous bits have been adjusted.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            all_q_adj <= '0' after TCQ*1 ps;
         else
            all_q_adj <= bool_to_std_logic((target_q = q_bit_sig)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- }}} end Set Q_bit Tap Settings -------------
   
   -- {{{ Phase Alignment ------------------------
   
   -- The data from the ISERDES can appear either in order and all in the same
   -- cycle OR it can be spread across two cycles with the order out of sync.
   -- The behavior depends on how the ISERDES input and output clock align with
   -- each other. A phase setting of 0 indicates that no realigning is required
   -- while a setting of 1 indicates that realignment is necessary.
   
   -- Mux in the data for the current CQ/CQ# data being operated on. This data
   -- will be used for checking and setting the data alignment.
   nd_cnum_data : for nd_j in 0 to  NUM_DEVICES - 1 generate

      cnum_rise_data0(nd_j) <= rise_data0_r((nd_j+1)*MEMORY_WIDTH-1 downto nd_j*MEMORY_WIDTH);
      cnum_fall_data0(nd_j) <= fall_data0_r((nd_j+1)*MEMORY_WIDTH-1 downto nd_j*MEMORY_WIDTH);
      cnum_rise_data1(nd_j) <= rise_data1_r((nd_j+1)*MEMORY_WIDTH-1 downto nd_j*MEMORY_WIDTH);
      cnum_fall_data1(nd_j) <= fall_data1_r((nd_j+1)*MEMORY_WIDTH-1 downto nd_j*MEMORY_WIDTH);

   end generate;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cnum_rd0 <= (others => '0') after TCQ*1 ps;
            cnum_fd0 <= (others => '0') after TCQ*1 ps;
            cnum_rd1 <= (others => '0') after TCQ*1 ps;
            cnum_fd1 <= (others => '0') after TCQ*1 ps;
         else
            cnum_rd0 <= cnum_rise_data0(to_integer(unsigned(cq_num_sig))) after TCQ*1 ps;
            cnum_fd0 <= cnum_fall_data0(to_integer(unsigned(cq_num_sig))) after TCQ*1 ps;
            cnum_rd1 <= cnum_rise_data1(to_integer(unsigned(cq_num_sig))) after TCQ*1 ps;
            cnum_fd1 <= cnum_fall_data1(to_integer(unsigned(cq_num_sig))) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- The incoming data stream for any given bit is ideally 01100101 - (first
   -- cycle - rd0, fd0, rd1, fd1 followed by second cycle - rd0, fd0, rd1, fd1).
   -- If a phase setting of 0 is correct (the inital mode), then the pattern
   -- will be 01100101 or 01010110. Either one is valid since the pattern is
   -- spread over two cycles and it is unknown which cycle it is sampling on.
   -- If a phase setting of 1 is correct, then the pattern will be 01011001 or
   -- 10010101.
   mw_phase_inst : 
      for mw_i in 0 to  MEMORY_WIDTH - 1 generate
         phase0_mw_vld(mw_i) <= (bool_to_std_logic((cnum_rd0(mw_i) = '0') and 
                                (cnum_fd0(mw_i) = '1')) and (cnum_rd1(mw_i)
                                xor cnum_fd1(mw_i)));
         phase1_mw_vld(mw_i) <= (bool_to_std_logic((cnum_rd1(mw_i) = '0') and 
                                (cnum_fd1(mw_i) = '1')) and (cnum_rd0(mw_i)
                                xor cnum_fd0(mw_i)));
      end generate;
   
   phase0_data_vld0 <= and_br(phase0_mw_vld);
   phase1_data_vld0 <= and_br(phase1_mw_vld);
   
   -- Because of the pattern, one phase will toggle in and out of being valid
   -- while the other is constantly valid. Checking that it is valid for two
   -- consecutive cycles will ensure that the toggling phase is sample on one
   -- of the valid cycles.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            phase0_data_vld1 <= '0' after TCQ*1 ps;
            phase1_data_vld1 <= '0' after TCQ*1 ps;
         else
            phase0_data_vld1 <= phase0_data_vld0 after TCQ*1 ps;
            phase1_data_vld1 <= phase1_data_vld0 after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   phase0_data_vld <= phase0_data_vld0 and phase0_data_vld1;
   phase1_data_vld <= phase1_data_vld0 and phase1_data_vld1;
   
   -- Indicate which phase setting is correct. If neither are correct across all
   -- bits or if both are indicating they are correct, issue an error.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            phase1_vld  <= '0' after TCQ*1 ps;
            phase0_vld  <= '0' after TCQ*1 ps;
            phase_error <= '0' after TCQ*1 ps;
         else
            phase1_vld  <= phase1_data_vld after TCQ*1 ps;
            phase0_vld  <= phase0_data_vld after TCQ*1 ps;
            phase_error <= not((phase0_data_vld xor phase1_data_vld)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   
   -- Set the correct phase for the current memory when in the CAL_SET_PHASE.
   -- SIM_CAL_OPTION="SKIP_CAL" assumes the same phase setting across all
   -- devices.
   nd_phase_inst : for nd_i in 0 to  NUM_DEVICES - 1 generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst_clk = '1') then
               phase(nd_i) <= '0' after TCQ*1 ps;
            elsif ((cal_cs = CAL_SET_PHASE) and 
                   ((SIM_CAL_OPTION = "NONE") or 
                   (SIM_CAL_OPTION = "FAST_CAL")) and 
                   (cq_num_sig = nd_i) and data_stable_r = '1') then
               phase(nd_i) <= phase1_vld after TCQ*1 ps;
            elsif ((cal_cs = CAL_SET_PHASE) 
                   and (SIM_CAL_OPTION = "SKIP_CAL")) then
               phase(nd_i) <= phase1_vld after TCQ*1 ps;
            end if;
         end if;
      end process;
      
      
      -- Indicate an error when neither phase setting provided valid data.
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst_clk = '1') then
               error_align(nd_i) <= '0' after TCQ*1 ps;
            elsif ((cal_cs = CAL_SET_PHASE) 
                   and (SIM_CAL_OPTION = "NONE") and 
                   (cq_num_sig = nd_i)) then
               error_align(nd_i) <= phase_error after TCQ*1 ps;
            elsif ((cal_cs = CAL_SET_PHASE) and
                   (SIM_CAL_OPTION = "SKIP_CAL")) then
               error_align(nd_i) <= phase_error after TCQ*1 ps;
            end if;
         end if;
      end process;
      
      
   end generate;
   
   -- }}} end Phase Alignment --------------------
   
   -- {{{ IDELAY/ISERDES Control -----------------
   
   -- {{{ Target Indicator -------------
   
   -- Indicate which CQ/CQ# is currently being worked on.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_num_sig <= (others => '0') after TCQ*1 ps;
         elsif (inc_cq = '1') then
            cq_num_sig <= cq_num_sig + '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Indicate which Q for the entire memory (q_bit) and which Q for a given
   -- memory (q_mem) is currently being worked on.
   q_mem_sel <= (others =>'0') when (q_mem = std_logic_vector(to_unsigned(MEMORY_WIDTH-1, Q_BITS))) else
                q_mem + '1';
                
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_bit_sig <= (others => '0') after TCQ*1 ps;
            q_mem     <= (others => '0') after TCQ*1 ps;
         elsif (clr_q = '1') then
            --q_bit_sig <= (cq_num_sig * std_logic_vector(to_unsigned(MEMORY_WIDTH, CQ_BITS))) after TCQ*1 ps; 
            q_bit_sig <= std_logic_vector(to_unsigned((to_integer(unsigned(cq_num_sig)) * MEMORY_WIDTH),Q_BITS)) after TCQ*1 ps;
            q_mem     <= (others => '0') after TCQ*1 ps;
         elsif (inc_q = '1' and next_q_grp = '0') then
            q_bit_sig <= q_bit_sig + 1 after TCQ*1 ps;
            q_mem <= q_mem_sel after TCQ*1 ps;
         elsif (inc_q = '1' and next_q_grp = '1') then
            q_bit_sig <= (q_bit_sig + std_logic_vector(to_unsigned(MEMORY_WIDTH, Q_BITS))) after TCQ*1 ps;
            q_mem <= (others => '0') after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Wait C_NUM_RDY_DLY cycle after cq_num is changed to allow time for it to
   -- cross into clk_rd domain before issuing any control to target idelay. It
   -- is considered ready when all consequetive c_num_changed bits have passed
   -- (i.e. - looks for falling edge out of SRL).
   process (clk)
   begin
      if (clk'event and clk = '1') then
        --if (rst_clk = '1') then
        --  c_num_done_tmp <= (others => '0') after TCQ*1 ps;
        --else
          c_num_done_tmp <= (c_num_done_tmp(C_NUM_RDY_DLY - 1 downto 0) & inc_cq) after TCQ*1 ps;
        --end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            c_num_done_int <= '0' after TCQ*1 ps;
         else
            c_num_done_int <= c_num_done_tmp(C_NUM_RDY_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            c_num_done <= '0' after TCQ*1 ps;
         else
            c_num_done <= c_num_done_int and 
                          not(c_num_done_tmp(C_NUM_RDY_DLY)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            c_num_rdy <= '1' after TCQ*1 ps;
         elsif (inc_cq = '1') then
            c_num_rdy <= '0' after TCQ*1 ps;
         elsif (c_num_done = '1') then
            c_num_rdy <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Wait Q_BIT_RDY_DLY cycle after q_bit is changed to allow time for it to
   -- cross into clk_rd domain before issuing any control to target idelay. It
   -- is considered ready when all consequetive q_bit_changed bits have passed
   -- (i.e. - looks for falling edge out of SRL).
   q_bit_changed <= clr_q or inc_q_d;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
        --if (rst_clk = '1') then
        --  q_bit_done_tmp <= (others => '0') after TCQ*1 ps;
        --else
          q_bit_done_tmp <= (q_bit_done_tmp(Q_BIT_RDY_DLY - 1 downto 0) & 
                              q_bit_changed) after TCQ*1 ps;
        --end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_bit_done_int <= '0' after TCQ*1 ps;
         else
            q_bit_done_int <= q_bit_done_tmp(Q_BIT_RDY_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_bit_done <= '0' after TCQ*1 ps;
         else
            q_bit_done <= q_bit_done_int and not(q_bit_done_tmp(Q_BIT_RDY_DLY)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_bit_rdy <= '1' after TCQ*1 ps;
         elsif (q_bit_changed = '1') then
            q_bit_rdy <= '0' after TCQ*1 ps;
         elsif (q_bit_done = '1') then
            q_bit_rdy <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- }}} end Target Indicator ---------
   
   -- {{{ IDELAY CE Control ------------
   
   -- The calibration logic currently only increments taps.
   cq_num_inc  <= '1';
   cqn_num_inc <= '1';
   q_bit_inc   <= '1';
   
   -- CQ/CQ# tap inc control. The taps are incremented each cycle that ce is
   -- asserted for current cq_num (target CQ/CQ#). It is incremented during the
   -- tap centering state machine in order to find the edges.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_num_ce_sig <= '0' after TCQ*1 ps;
         elsif (ctr_c_dly_st = '1') then
            cq_num_ce_sig <= en_rise_tap or en_fall_tap after TCQ*1 ps;
         else
            cq_num_ce_sig <= '0' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cqn_num_ce_sig <= '0' after TCQ*1 ps;
         elsif (ctr_c_dly_st = '1' and MEMORY_TYPE = "RLD2") then
            cqn_num_ce_sig <= en_rise_tap after TCQ*1 ps;
         elsif (ctr_c_dly_st = '1') then
            cqn_num_ce_sig <= en_fall_tap or en_rise_tap after TCQ*1 ps;
         else
            cqn_num_ce_sig <= '0' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Q tap inc control. The taps are incremented each cycle that ce is asserted
   -- for current q_bit (target Q). It is incremented during the tap centering
   -- state machine in order to find the left edge from within the target window
   -- and during the adjustment process in the overall calibration flow.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_bit_ce_sig <= '0' after TCQ*1 ps;
         elsif (ctr_q_dly_st = '1') then
            q_bit_ce_sig <= en_tap_adj after TCQ*1 ps;
         elsif (adjust_q = '1') then
            q_bit_ce_sig <= '1' after TCQ*1 ps;
         else
            q_bit_ce_sig <= '0' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Wait TAP_DLY cycles after a tap has been adjusted (ce asserted) to allow
   -- time for the control to pass into the clk_rd domain and for the update to
   -- take place. Done is deasserted as soon as the reset is issued and then
   -- isn't released until the final delayed rst has propogated through the
   -- shift chain.
   
   -- cq ce done
   process (clk)
   begin
      if (clk'event and clk = '1') then
         cq_tap_done_tmp <= (cq_tap_done_tmp(TAP_DLY - 1 downto 0) 
                            & cq_num_ce_sig) after TCQ*1 ps;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_tap_done_int <= '0' after TCQ*1 ps;
         else
            cq_tap_done_int <= cq_tap_done_tmp(TAP_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_tap_done <= '1' after TCQ*1 ps;
         elsif (cq_num_ce_sig = '1') then
            cq_tap_done <= '0' after TCQ*1 ps;
         elsif (cq_tap_done_int = '1') then
            cq_tap_done <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- cq# ce done
   process (clk)
   begin
      if (clk'event and clk = '1') then
         cqn_tap_done_tmp <= (cqn_tap_done_tmp(TAP_DLY - 1 downto 0) 
                             & cqn_num_ce_sig) after TCQ*1 ps;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cqn_tap_done_int <= '0' after TCQ*1 ps;
         else
            cqn_tap_done_int <= cqn_tap_done_tmp(TAP_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cqn_tap_done <= '1' after TCQ*1 ps;
         elsif (cqn_num_ce_sig = '1') then
            cqn_tap_done <= '0' after TCQ*1 ps;
         elsif (cqn_tap_done_int = '1') then
            cqn_tap_done <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- q ce done
   process (clk)
   begin
      if (clk'event and clk = '1') then
        --if (rst_clk = '1') then
        --  q_tap_done_tmp <= (others => '0') after TCQ*1 ps;
        --else
         q_tap_done_tmp <= (q_tap_done_tmp(TAP_DLY - 1 downto 0) 
                            & q_bit_ce_sig) after TCQ*1 ps;
        --end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_tap_done_int <= '0' after TCQ*1 ps;
         else
            q_tap_done_int <= q_tap_done_tmp(TAP_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_tap_done <= '1' after TCQ*1 ps;
         elsif (q_bit_ce_sig = '1') then
            q_tap_done <= '0' after TCQ*1 ps;
         elsif (q_tap_done_int = '1') then
            q_tap_done <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   tap_done <= cq_tap_done and cqn_tap_done and q_tap_done;
   
   -- }}} end IDLEAY CE Control --------
   
   -- {{{ Load Control -----------------
   
   -- Wait LOAD_DLYto allow time for the
   -- load data to  cycles after load_c/q has been issued uing the rst to     
   -- actually loadcross into the clk_rd domain before iss                    
   --                 the value into the IODELAY.                               
   -- load_c
   process (clk)
   begin
      if (clk'event and clk = '1') then
        --if (rst_clk = '1') then
        --  load_c_tmp <= (others => '0') after TCQ*1 ps;
        --else
          load_c_tmp <= (load_c_tmp(LOAD_DLY - 1 downto 0) & issue_load_c) after TCQ*1 ps;
        --end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            load_c <= '0' after TCQ*1 ps;
         else
            load_c <= load_c_tmp(LOAD_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            load_c_fall <= '0' after TCQ*1 ps;
         else
            load_c_fall <= load_c and not(load_c_tmp(LOAD_DLY)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            load_c_done <= '1' after TCQ*1 ps;
         elsif (issue_load_c = '1') then
            load_c_done <= '0' after TCQ*1 ps;
         elsif (load_c_fall = '1') then
            load_c_done <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- load_q
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            load_q_changed <= '0' after TCQ*1 ps;
         else
            load_q_changed <= issue_load_q after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         load_q_tmp <= (load_q_tmp(LOAD_DLY - 1 downto 0) & load_q_changed) after TCQ*1 ps;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            load_q <= '0' after TCQ*1 ps;
         else
            load_q <= load_q_tmp(LOAD_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            load_q_fall <= '0' after TCQ*1 ps;
         else
            load_q_fall <= load_q and not(load_q_tmp(LOAD_DLY)) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            load_q_done <= '1' after TCQ*1 ps;
         elsif (issue_load_q = '1') then
            load_q_done <= '0' after TCQ*1 ps;
         elsif (load_q_fall = '1') then
            load_q_done <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   load_done <= load_c_done and load_q_done;
   
   -- }}} end Load Control -------------
   
   -- {{{ IDELAY RST Control -----------
   
   -- Upon reset, the IDELAY tap is set to the load value. The taps can be reset
   -- to a default value or loaded with a target value. When loaded with a
   -- target value, the load value must be allowed time to cross into the clk_rd
   -- domain before the reset is issued.
   
   -- cq rst
   
   -- cq rst
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_num_rst_sig    <= '1' after TCQ*1 ps;
            cq_num_load_sig   <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
         elsif (issue_cdt_rst = '1' or issue_dly_rst = '1') then
            cq_num_rst_sig    <= '1' after TCQ*1 ps;
            cq_num_load_sig   <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
         elsif (load_c = '1') then
            cq_num_rst_sig    <= '1' after TCQ*1 ps;
            cq_num_load_sig   <= cq_tap after TCQ*1 ps;
         else
            cq_num_rst_sig    <= '0' after TCQ*1 ps;
            cq_num_load_sig   <= cq_tap after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   --cq# rst
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cqn_num_rst_sig   <= '1' after TCQ*1 ps;
            cqn_num_load_sig  <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
         elsif ((issue_cdt_rst or issue_dly_rst) = '1') then
            cqn_num_rst_sig   <= '1' after TCQ*1 ps;
            cqn_num_load_sig  <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
         elsif (load_c = '1' and MEMORY_TYPE = "RLD2") then
            cqn_num_rst_sig   <= '1' after TCQ*1 ps;
            cqn_num_load_sig  <= cq_tap after TCQ*1 ps;
         elsif (load_c = '1' and MEMORY_TYPE = "QDR") then
            cqn_num_rst_sig   <= '1' after TCQ*1 ps;
            cqn_num_load_sig  <= cqn_tap after TCQ*1 ps;
         elsif (MEMORY_TYPE = "QDR") then
            cqn_num_rst_sig   <= '0' after TCQ*1 ps;
            cqn_num_load_sig  <= cqn_tap after TCQ*1 ps;
         elsif (MEMORY_TYPE = "RLD2") then
            cqn_num_rst_sig   <= '0' after TCQ*1 ps;
            cqn_num_load_sig  <= cq_tap after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- q rst
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_bit_rst_sig  <= '1' after TCQ*1 ps;
            q_bit_load_sig <= (others =>'0') after TCQ*1 ps;
         elsif (issue_dly_rst = '1') then
            q_bit_rst_sig  <= '1' after TCQ*1 ps;
            q_bit_load_sig <= (others =>'0') after TCQ*1 ps;
         elsif (load_q = '1') then
            q_bit_rst_sig  <= '1' after TCQ*1 ps;
            q_bit_load_sig <= q_tap after TCQ*1 ps;
         else
            q_bit_rst_sig  <= '0' after TCQ*1 ps;
            q_bit_load_sig <= q_tap after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Wait RST_DLY cycles after the resets have been issued to allow time for
   -- the control to pass into the clk_rd domain and for the update to take
   -- place. Done is deasserted as soon as the reset is issued and then isn't
   -- released until the final delayed rst has propogated through the shift
   -- chain.
   
   -- cq/cq# rst done
   cq_rst_changed <= issue_cdt_rst or issue_dly_rst or load_c;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         cq_rst_done_tmp <= (cq_rst_done_tmp(RST_DLY - 1 downto 0) & 
                            cq_rst_changed) after TCQ*1 ps;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_rst_done_int <= '0' after TCQ*1 ps;
         else
            cq_rst_done_int <= cq_rst_done_tmp(RST_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Keep track of the outstanding resets in the shift register
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            outstanding_cq_rst <= (others =>'0') after TCQ*1 ps;
         elsif (cq_rst_changed = '1' and cq_rst_done_int = '0') then
            outstanding_cq_rst <= outstanding_cq_rst + "0001" after TCQ*1 ps;
         elsif (cq_rst_done_int = '1' and cq_rst_changed = '0') then
            outstanding_cq_rst <= outstanding_cq_rst - "0001" after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Wait to signal that the reset is done until all resets leave the shift
   -- register
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            cq_rst_done <= '1' after TCQ*1 ps;
         elsif (cq_rst_changed = '1') then
            cq_rst_done <= '0' after TCQ*1 ps;
         elsif (outstanding_cq_rst = "0000") then
            cq_rst_done <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- q rst done
   q_rst_changed <= issue_dly_rst or load_q;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         q_rst_done_tmp <= (q_rst_done_tmp(RST_DLY - 1 downto 0) 
                           & q_rst_changed) after TCQ*1 ps;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_rst_done_int <= '0' after TCQ*1 ps;
         else
            q_rst_done_int <= q_rst_done_tmp(RST_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Keep track of the outstanding resets in the shift register
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            outstanding_q_rst <= (others =>'0') after TCQ*1 ps;
         elsif (q_rst_changed = '1' and q_rst_done_int = '0') then
            outstanding_q_rst <= outstanding_q_rst + "0001" after TCQ*1 ps;
         elsif (q_rst_done_int = '1' and q_rst_changed = '0') then
            outstanding_q_rst <= outstanding_q_rst - "0001" after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Wait to signal that the reset is done until all resets leave the shift
   -- register
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_rst_done <= '1' after TCQ*1 ps;
         elsif (q_rst_changed = '1') then
            q_rst_done <= '0' after TCQ*1 ps;
         elsif (outstanding_q_rst = "0000") then
            q_rst_done <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   rst_done <= cq_rst_done and q_rst_done;
   
   -- }}} end IDELAY RST Control --------------
   
   -- {{{ ISERDES Clock Control --------
   
   -- Delay clearing the clock invert signal by a few cycles to allow time for
   -- changes / updates to take affect before reseting it.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            clear_clk_invert_r   <= '0' after TCQ*1 ps;
            clear_clk_invert_2r  <= '0' after TCQ*1 ps;
            clear_clk_invert_3r  <= '0' after TCQ*1 ps;
         else
            clear_clk_invert_r   <= clear_clk_invert after TCQ*1 ps;
            clear_clk_invert_2r  <= clear_clk_invert_r after TCQ*1 ps;
            clear_clk_invert_3r  <= clear_clk_invert_2r after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Set ISERDES clk/clkb clock polarity. It can be forced to use the inverted
   -- clock or can be selected to use the chosen clock inversion.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            q_bit_clkinv_sig <= '0' after TCQ*1 ps;
         elsif (force_clk_invert = '1') then
            q_bit_clkinv_sig <= '1' after TCQ*1 ps;
         elsif (set_clk_polarity = '1') then
            q_bit_clkinv_sig <= invert_clk after TCQ*1 ps;
         elsif (clear_clk_invert_3r = '1') then
            q_bit_clkinv_sig <= '0' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Wait POL_DLY cycles after the ISERDES clk/clkb polarity has been changed
   -- to allow time for the control to pass into the clk_rd domain and for the
   -- update to take place.
   polarity_changed <= force_clk_invert or set_clk_polarity or clear_clk_invert;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
        --if (rst_clk = '1') then
        --  polarity_done_tmp <= (others => '0');
        --else
         polarity_done_tmp <= (polarity_done_tmp(POL_DLY - 1 downto 0) & 
                              polarity_changed) after TCQ*1 ps;
        --end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            polarity_done_int <= '0' after TCQ*1 ps;
         else
            polarity_done_int <= polarity_done_tmp(POL_DLY) after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_clk = '1') then
            polarity_done <= '1' after TCQ*1 ps;
         elsif (polarity_changed = '1') then
            polarity_done <= '0' after TCQ*1 ps;
         elsif (polarity_done_int = '1') then
            polarity_done <= '1' after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   
end architecture trans;

-- }}} end ISERDES Clock Control ----

-- }}} end IDELAY/ISERDES Control -------------
