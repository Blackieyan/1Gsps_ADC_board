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
--  /   /         Filename           : phy_read_dly_ctrl.v
-- /___/   /\     Timestamp          : Dec 14, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--  This module
--  1. Drives the IODELAY control (rst, ce, inc, and load) for each clock and
--     data I/O based on the control from the calibration logic.
--
--Revision History:
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity phy_read_dly_ctrl is 
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
end entity phy_read_dly_ctrl;

architecture arch of phy_read_dly_ctrl is

  signal q_dly_clkinv_r : std_logic;
  signal clkinv_changed : std_logic;
  signal iserdes_rst_int : std_logic;
  signal iserdes_rst_int_r : std_logic;
  signal iserdes_rst_int_2r : std_logic;
  signal iserdes_rst_int_3r : std_logic;
  signal iserdes_rst_int_4r : std_logic;
  signal q_bit_target : std_logic_vector(TAP_BITS-1 downto 0);
  signal q_bit_current : std_logic_vector(TAP_BITS-1 downto 0);
  signal q_dly_load_sig : std_logic_vector(TAP_BITS-1 downto 0);
  signal q_bit_load_ce : std_logic_vector(MEMORY_WIDTH-1 downto 0);
  signal taps_match : std_logic;
  signal q_dly_clkinv_sig : std_logic;
  signal q_dly_rst_sig : std_logic_vector(MEMORY_WIDTH-1 downto 0);
  signal cq_dly_rst_sig : std_logic; 
  signal cqn_dly_rst_sig : std_logic; 

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

  -- Assign Internal signals to outputs
  q_dly_load   <= q_dly_load_sig;
  q_dly_clkinv <= q_dly_clkinv_sig;
  q_dly_rst    <= q_dly_rst_sig;
  cq_dly_rst   <= cq_dly_rst_sig;
  cqn_dly_rst  <= cqn_dly_rst_sig;

  -- Drive IODELAY load values to all CQs, CQ#s, and Qs - loaded on reset
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        cq_dly_load     <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
        cqn_dly_load    <= std_logic_vector(to_unsigned(MIN_TAPS, TAP_BITS)) after TCQ*1 ps;
        q_dly_load_sig  <= (others => '0') after TCQ*1 ps;
      else
        cq_dly_load     <= cq_num_load after TCQ*1 ps;
        cqn_dly_load    <= cqn_num_load after TCQ*1 ps;
        q_dly_load_sig  <= q_bit_load after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  -- Drive IODLEAY inc values to all CQs, CQ#s, and Qs. Drive with signals from
  -- stage 1 calibration until stage 2 is complete. Then drive with signals
  -- from phase detector.
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        cq_dly_inc    <= '1' after TCQ*1 ps;
        cqn_dly_inc   <= '1' after TCQ*1 ps;
        q_dly_inc     <= '1' after TCQ*1 ps;
      else
        if (DEBUG_PORT = "OFF") then  
          if (cal_stage2_done = '1') then
            cq_dly_inc  <= pd_incdec_maintain after TCQ*1 ps;
            cqn_dly_inc <= pd_incdec_maintain after TCQ*1 ps;
            q_dly_inc   <= '0' after TCQ*1 ps;
          else
            cq_dly_inc  <= cq_num_inc after TCQ*1 ps;
            cqn_dly_inc <= cqn_num_inc after TCQ*1 ps;
            q_dly_inc   <= q_bit_inc after TCQ*1 ps;
          end if;
        else
          if (cal_stage1_done = '1') then
            --DEBUG_PORT = ON
            cq_dly_inc  <= pd_incdec_maintain or dbg_inc_cq_clkrd or 
                           dbg_inc_cq_all_clkrd after TCQ*1 ps; 
            cqn_dly_inc <= pd_incdec_maintain or dbg_inc_cqn_clkrd or 
                           dbg_inc_cqn_all_clkrd after TCQ*1 ps;
            q_dly_inc   <= dbg_inc_q_clkrd or dbg_inc_q_all_clkrd after TCQ*1 ps;
          else 
            cq_dly_inc  <= cq_num_inc after TCQ*1 ps; 
            cqn_dly_inc <= cqn_num_inc after TCQ*1 ps;
            q_dly_inc   <= q_bit_inc after TCQ*1 ps;
          end if;
        end if;

      end if;
    end if;
  end process;
  
  -- IODELAY/ISERDES control is sent to the I/O's for this memory only if this
  -- device is the target (cq_num_active == DEVICE_ID). For clock enables, send
  -- the control to the I/O's from calibration logic during stage 1 and 2
  -- calibration. After that they are driven from the phase detector.

  -- ISERDES  clk/clkb input polarity control
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        q_dly_clkinv_sig    <= '0' after TCQ*1 ps;
      else
        if (cq_num_active = DEVICE_ID) then
          q_dly_clkinv_sig  <= q_bit_clkinv;
        end if;
      end if;
    end if;
  end process;
 
  -- Issue ISERDES reset whenever clock inversion control changes
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        q_dly_clkinv_r <= '0' after TCQ*1 ps;
      else
        q_dly_clkinv_r <= q_dly_clkinv_sig after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Indicate if q_bit_clkinv changed states
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        clkinv_changed <= '0' after TCQ*1 ps;
      else
        clkinv_changed <= q_dly_clkinv_sig xor q_dly_clkinv_r after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Shared ISERDES reset across all clock and data within clock group. 
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        iserdes_rst_int <= '1' after TCQ*1 ps;
      elsif (cq_num_active = DEVICE_ID) then
        iserdes_rst_int <= clkinv_changed or cq_num_rst or cqn_num_rst after TCQ*1 ps;
      else
        iserdes_rst_int <= '0' after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Extend the reset to ensure that it is seen when the clocks move as a
  -- result of the taps be inc/dec or reset
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        iserdes_rst_int_r   <= '1' after TCQ*1 ps;
        iserdes_rst_int_2r  <= '1' after TCQ*1 ps;
        iserdes_rst_int_3r  <= '1' after TCQ*1 ps;
        iserdes_rst_int_4r  <= '1' after TCQ*1 ps;
      else
        iserdes_rst_int_r   <= iserdes_rst_int after TCQ*1 ps;
        iserdes_rst_int_2r  <= iserdes_rst_int_r after TCQ*1 ps;
        iserdes_rst_int_3r  <= iserdes_rst_int_2r after TCQ*1 ps;
        iserdes_rst_int_4r  <= iserdes_rst_int_3r after TCQ*1 ps;
      end if;
    end if;
  end process;

  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        iserdes_rst <= '1' after TCQ*1 ps;
      else
        iserdes_rst <= iserdes_rst_int or iserdes_rst_int_r or iserdes_rst_int_2r or 
                              iserdes_rst_int_3r or iserdes_rst_int_4r after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Individual CQ IODELAY enables
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        cq_dly_ce <= '0' after TCQ*1 ps;
      elsif (DEBUG_PORT = "OFF") then
                    
        if (cq_num_active = DEVICE_ID) then
          if (cal_stage2_done = '1') then
            cq_dly_ce <= pd_en_maintain after TCQ*1 ps;
          else
            cq_dly_ce <= cq_num_ce after TCQ*1 ps;
          end if;
        else
          if (cal_stage2_done = '1') then
            cq_dly_ce <= pd_en_maintain after TCQ*1 ps;
          else
            cq_dly_ce <= '0' after TCQ*1 ps;
          end if;
        end if; 

      elsif (DEBUG_PORT = "ON" and cal_stage2_done = '1' ) then
        if (dbg_sel_cq_clkrd = DEVICE_ID) then
            cq_dly_ce <= pd_en_maintain or dbg_inc_cq_clkrd or
                         dbg_dec_cq_clkrd or dbg_inc_cq_all_clkrd or
                         dbg_dec_cq_all_clkrd after TCQ*1 ps;
         else
            cq_dly_ce <= pd_en_maintain or dbg_inc_cq_all_clkrd or
                         dbg_dec_cq_all_clkrd after TCQ*1 ps;
         end if;
      elsif ((DEBUG_PORT = "ON") and (cal_stage2_done = '0')) then
          if (cq_num_active = DEVICE_ID) then
             cq_dly_ce <= cq_num_ce after TCQ*1 ps;
           else
             cq_dly_ce <= '0' after TCQ*1 ps;
          end if;
      else
          cq_dly_ce <= '0' after TCQ*1 ps;
      end if; 
    end if;
  end process;
  
  -- Individual CQ IODELAY resets with load values
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        cq_dly_rst_sig <= '1' after TCQ*1 ps;
      else
        if (cq_num_active = DEVICE_ID) then
          cq_dly_rst_sig <= cq_num_rst after TCQ*1 ps;
        else
          cq_dly_rst_sig <= '0' after TCQ*1 ps;
        end if;
      end if;
    end if;
  end process;
  
  -- Individual CQN IODELAY enables
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        cqn_dly_ce <= '0' after TCQ*1 ps;
      elsif (DEBUG_PORT = "OFF") then                  
         if (cq_num_active = DEVICE_ID) then
           if (cal_stage2_done = '1') then
             cqn_dly_ce <= pd_en_maintain after TCQ*1 ps;
           else
             cqn_dly_ce <= cqn_num_ce after TCQ*1 ps;
           end if;
         else
           if (cal_stage2_done = '1') then
             cqn_dly_ce <= pd_en_maintain after TCQ*1 ps;
           else
             cqn_dly_ce <= '0' after TCQ*1 ps;
           end if;
         end if;

      elsif (DEBUG_PORT = "ON" and cal_stage2_done = '1' ) then
        if (dbg_sel_cqn_clkrd = DEVICE_ID) then
            cqn_dly_ce <= pd_en_maintain or dbg_inc_cqn_clkrd or
                      dbg_dec_cqn_clkrd or dbg_inc_cqn_all_clkrd or
                      dbg_dec_cqn_all_clkrd after TCQ*1 ps;
         else
            cqn_dly_ce <= pd_en_maintain or dbg_inc_cqn_all_clkrd or
                         dbg_dec_cqn_all_clkrd after TCQ*1 ps;
         end if;
      elsif ((DEBUG_PORT = "ON") and (cal_stage2_done = '0')) then
          if (cq_num_active = DEVICE_ID) then
             cqn_dly_ce <= cqn_num_ce after TCQ*1 ps;
           else
             cqn_dly_ce <= '0' after TCQ*1 ps;
          end if;
      else
          cqn_dly_ce <= '0' after TCQ*1 ps;
      end if; 
    end if;
  end process;
  
  -- Individual CQ# IODELAY resets with load values
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        cqn_dly_rst_sig <= '1' after TCQ*1 ps;
      else
        if (cq_num_active = DEVICE_ID) then
          cqn_dly_rst_sig <= cqn_num_rst after TCQ*1 ps;
        else
          cqn_dly_rst_sig <= '0' after TCQ*1 ps;
        end if;
      end if;
    end if;
  end process;

  -- Save the value of q_bit load whenever a reset is issued
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        q_bit_target   <= (others => '0') after TCQ*1 ps;
      elsif (MEM_TYPE="QDR2PLUS" or MEM_TYPE="QDR2") then
        q_bit_target   <= (others => '0') after TCQ*1 ps;
      elsif (or_br(q_dly_rst_sig) = '1') then --save for any reset since a shared signal
        q_bit_target   <= q_dly_load_sig after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- generate a flag for when taps expected and current do not match
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        taps_match   <= '0' after TCQ*1 ps;
      elsif (q_bit_current = q_bit_target) then
        taps_match   <= '1' after TCQ*1 ps;
      else 
        taps_match   <= '0' after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  -- Update the value of q_bit_current
  -- want to increment taps to match the q_bit_target value
  -- set via parralel load
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        q_bit_current   <= (others => '0') after TCQ*1 ps;
      elsif (MEM_TYPE="QDR2PLUS" or MEM_TYPE="QDR2") then
        q_bit_current   <= (others => '0') after TCQ*1 ps;
      elsif (or_br(q_dly_rst_sig) = '1') then
        q_bit_current   <= (others => '0') after TCQ*1 ps;
      elsif (q_bit_current /= q_bit_target) then
        q_bit_current   <= q_bit_current + 1 after TCQ*1 ps;
      else
        q_bit_current   <= q_bit_current after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  -- IODELAY control is sent to the I/O's for this memory only if this
  -- device is the target.
  
  q_dlyctrl_inst : for mw_i in 0 to MEMORY_WIDTH-1 generate
  begin
    -- Increment the taps of a given bit to the target value
    -- this assumes enough time is given after rst with the current bit 
    -- to reach the target value
    process (clk_rd) 
    begin
      if (clk_rd'event and clk_rd = '1') then
        if (rst_clk_rd = '1') then
          q_bit_load_ce(mw_i) <= '0' after TCQ*1 ps;
        elsif (MEM_TYPE="QDR2PLUS" or MEM_TYPE="QDR2" ) then
          q_bit_load_ce(mw_i) <= '0' after TCQ*1 ps;
        elsif (taps_match = '0') then
          if (q_bit_active = mw_i+(MEMORY_WIDTH*DEVICE_ID)) then
            q_bit_load_ce(mw_i) <= '1' after TCQ*1 ps;
          elsif (SIM_CAL_OPTION = "FAST_CAL" and cq_num_active = DEVICE_ID) then
            q_bit_load_ce(mw_i) <= '1' after TCQ*1 ps;
          else
            q_bit_load_ce(mw_i) <= '0' after TCQ*1 ps;
          end if;
        else
          q_bit_load_ce(mw_i) <= '0' after TCQ*1 ps;
        end if;
      end if;
    end process;


    --Individual Q IODELAY enables
    process (clk_rd) 
    begin
      if (clk_rd'event and clk_rd = '1') then
        if (rst_clk_rd = '1') then
          q_dly_ce(mw_i) <= '0' after TCQ*1 ps;

        elsif (SIM_CAL_OPTION = "FAST_CAL"  and cq_num_active = DEVICE_ID) then
          q_dly_ce(mw_i) <= q_bit_ce or q_bit_load_ce(mw_i) after TCQ*1 ps;

        elsif (DEBUG_PORT = "OFF") then
          if (q_bit_active = mw_i+(MEMORY_WIDTH*DEVICE_ID)) then
            q_dly_ce(mw_i) <= q_bit_ce or q_bit_load_ce(mw_i) after TCQ*1 ps;
          else
            q_dly_ce(mw_i) <= '0' after TCQ*1 ps;
          end if;

        elsif ((DEBUG_PORT = "ON") and cal_stage1_done = '1') then
          if (dbg_sel_q_clkrd = mw_i+(MEMORY_WIDTH*DEVICE_ID)) then
            q_dly_ce(mw_i) <= (dbg_inc_q_clkrd or dbg_dec_q_clkrd or 
                               dbg_inc_q_all_clkrd or dbg_dec_q_all_clkrd);
          else
            q_dly_ce(mw_i) <= (dbg_inc_q_all_clkrd or dbg_dec_q_all_clkrd);
          end if;

        elsif ((DEBUG_PORT = "ON") and cal_stage1_done = '0') then
          if (q_bit_active = mw_i+(MEMORY_WIDTH*DEVICE_ID)) then
            q_dly_ce(mw_i) <= q_bit_ce or q_bit_load_ce(mw_i) after TCQ*1 ps;
          else
            q_dly_ce(mw_i) <= '0' after TCQ*1 ps;
          end if;
        
        else
          q_dly_ce(mw_i) <= '0' after TCQ*1 ps;
        end if;
      end if;
    end process;
    
    -- Individual Q IODELAY resets with load values
    process (clk_rd) 
    begin
      if (clk_rd'event and clk_rd = '1') then
        if (rst_clk_rd = '1') then
          q_dly_rst_sig(mw_i) <= '1' after TCQ*1 ps;
        elsif (SIM_CAL_OPTION = "FAST_CAL" and cq_num_active = DEVICE_ID) then
          q_dly_rst_sig(mw_i) <= q_bit_rst after TCQ*1 ps;
        elsif (q_bit_active = (mw_i + (MEMORY_WIDTH * DEVICE_ID))) then
          q_dly_rst_sig(mw_i) <= q_bit_rst after TCQ*1 ps;
        else
          q_dly_rst_sig(mw_i) <= '0' after TCQ*1 ps;
        end if;
      end if;
    end process;
    
  end generate q_dlyctrl_inst;
  
end architecture arch;
