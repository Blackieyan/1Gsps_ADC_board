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
--  /   /         Filename           : phy_read_sync.v
-- /___/   /\     Timestamp          : Nov 19, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--  This module
--  1. Resynchronizes IODELAY controls from stage 1 calibration in the clk domain
--     to the IODELAYs in the clk_rd domains.
--  2. Resynchronizes control for phase detectors between stage 2 calibration in
--     clk domain and the remaining logic in the clk_rd domains.
--
--Revision History:
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity phy_read_sync is
generic(
  TAP_BITS   : integer := 5;     -- Number of bits needed to represent DEVICE_TAPS
  CQ_BITS    : integer := 1;     -- Number of bits needed to represent number 
                                 -- of cq/cq#'s
  Q_BITS     : integer := 7;     -- Number of bits needed to represent number 
                                 --of q's
  DEVICE_ID  : integer := 0;     -- Indicates memory device instance
  DEBUG_PORT : string  := "ON";  -- Debug using Chipscope controls
  TCQ        : integer := 100    -- Register delay
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

  attribute max_fanout : string;
  attribute max_fanout of q_bit_active : signal is "8";
  
end entity phy_read_sync;

architecture arch of phy_read_sync is
  --declare attributes
  attribute ASYNC_REG : string;
    
  --Signal declarations
  signal q_bit_active_clk_r   : std_logic_vector(Q_BITS-1 downto 0);
  signal cq_num_active_clk_r  : std_logic_vector(CQ_BITS-1 downto 0);
  signal q_bit_changed        : std_logic;
  signal cq_num_changed       : std_logic;
  signal wr_en                : std_logic;
  signal rd_en                : std_logic;
  signal fifo_empty           : std_logic;
  signal fifo_wr_data         : std_logic_vector(35 downto 0);
  signal fifo_rd_data         : std_logic_vector(35 downto 0);
  signal q_bit_load_int       : std_logic_vector(4 downto 0);
  signal cqn_num_load_int     : std_logic_vector(4 downto 0);
  signal cq_num_load_int      :  std_logic_vector(4 downto 0);
  signal q_bit_inc_int        : std_logic;
  signal q_bit_ce_int         : std_logic;
  signal q_bit_rst_int        : std_logic;
  signal cqn_num_inc_int      : std_logic;
  signal cqn_num_ce_int       : std_logic;
  signal cqn_num_rst_int      : std_logic;
  signal cq_num_inc_int       : std_logic;
  signal cq_num_ce_int        : std_logic;
  signal cq_num_rst_int       : std_logic;
  signal q_bit_active_int     : std_logic_vector(Q_BITS-1 downto 0);
  signal cq_num_active_int    : std_logic_vector(CQ_BITS-1 downto 0);

  signal cq_num_active_clkrd_r    : std_logic_vector(CQ_BITS-1 downto 0);
  signal q_bit_active_clkrd_r     : std_logic_vector(Q_BITS-1 downto 0);
  signal cq_num_load_clk_r        : std_logic_vector(TAP_BITS-1 downto 0);
  signal cq_num_load_clkrd_r      : std_logic_vector(TAP_BITS-1 downto 0);
  signal cqn_num_load_clk_r       : std_logic_vector(TAP_BITS-1 downto 0);
  signal cqn_num_load_clkrd_r     : std_logic_vector(TAP_BITS-1 downto 0);
  signal q_bit_load_clk_r         : std_logic_vector(TAP_BITS-1 downto 0);
  signal q_bit_load_clkrd_r       : std_logic_vector(TAP_BITS-1 downto 0);
  signal cq_num_rst_clk_r         : std_logic;
  signal cq_num_rst_clkrd_r       : std_logic;
  signal cq_num_ce_clk_r          : std_logic;
  signal cq_num_ce_clkrd_r        : std_logic;
  signal cq_num_inc_clk_r         : std_logic;
  signal cq_num_inc_clkrd_r       : std_logic;
  signal cqn_num_rst_clk_r        : std_logic;
  signal cqn_num_rst_clkrd_r      : std_logic;
  signal cqn_num_ce_clk_r         : std_logic;
  signal cqn_num_ce_clkrd_r       : std_logic;
  signal cqn_num_inc_clk_r        : std_logic;
  signal cqn_num_inc_clkrd_r      : std_logic;
  signal q_bit_rst_clk_r          : std_logic;
  signal q_bit_rst_clkrd_r        : std_logic;
  signal q_bit_ce_clk_r           : std_logic;
  signal q_bit_ce_clkrd_r         : std_logic;
  signal q_bit_inc_clk_r          : std_logic;
  signal q_bit_inc_clkrd_r        : std_logic;
  signal q_bit_clkinv_clk_r       : std_logic;
  signal q_bit_clkinv_clkrd_r     : std_logic;
  signal q_bit_clkinv_int         : std_logic;
  signal q_bit_clkinv_int_r       : std_logic;
  signal q_bit_clkinv_int_2r      : std_logic;
  signal phase_clk_r              : std_logic;
  signal phase_clkrd_r            : std_logic;
  signal cal_stage1_done_clk_r    : std_logic;
  signal cal_stage2_done_clk_r    : std_logic;
  signal cal_stage1_done_clkrd_r  : std_logic;
  signal cal_stage2_done_clkrd_r  : std_logic;
  signal pd_calib_done_clkrd_r    : std_logic;
  signal pd_calib_done_clk        : std_logic; 
  signal dbg_inc_cq_all_r         : std_logic;  
  signal dbg_inc_cqn_all_r        : std_logic; 
  signal dbg_inc_q_all_r          : std_logic;   
  signal dbg_dec_cq_all_r         : std_logic;  
  signal dbg_dec_cqn_all_r        : std_logic; 
  signal dbg_dec_q_all_r          : std_logic;   
  signal dbg_inc_cq_r             : std_logic;      
  signal dbg_inc_cqn_r            : std_logic;     
  signal dbg_inc_q_r              : std_logic;       
  signal dbg_dec_cq_r             : std_logic;      
  signal dbg_dec_cqn_r            : std_logic;     
  signal dbg_dec_q_r              : std_logic;       
  signal dbg_sel_cq_r             : std_logic_vector(CQ_BITS-1 downto 0);      
  signal dbg_sel_cqn_r            : std_logic_vector(CQ_BITS-1 downto 0);     
  signal dbg_sel_q_r              : std_logic_vector(Q_BITS-1 downto 0);       
  signal dbg_inc_cq_all_2r        : std_logic; 
  signal dbg_inc_cqn_all_2r       : std_logic;
  signal dbg_inc_q_all_2r         : std_logic;  
  signal dbg_dec_cq_all_2r        : std_logic; 
  signal dbg_dec_cqn_all_2r       : std_logic;
  signal dbg_dec_q_all_2r         : std_logic;  
  signal dbg_inc_cq_2r            : std_logic;     
  signal dbg_inc_cqn_2r           : std_logic;    
  signal dbg_inc_q_2r             : std_logic;      
  signal dbg_dec_cq_2r            : std_logic;     
  signal dbg_dec_cqn_2r           : std_logic;    
  signal dbg_dec_q_2r             : std_logic;      
  signal dbg_sel_cq_2r            : std_logic_vector(CQ_BITS-1 downto 0);     
  signal dbg_sel_cqn_2r           : std_logic_vector(CQ_BITS-1 downto 0);    
  signal dbg_sel_q_2r             : std_logic_vector(Q_BITS-1 downto 0);
  signal dbg_sel_q_clk_r          : std_logic_vector(Q_BITS-1 downto 0);
  signal dbg_sel_cq_clk_r         : std_logic_vector(CQ_BITS-1 downto 0);
  signal dbg_sel_cqn_clk_r        : std_logic_vector(CQ_BITS-1 downto 0);
  signal dbg_inc_q_clk_r          : std_logic;
  signal dbg_dec_q_clk_r          : std_logic;
  signal dbg_inc_cq_clk_r         : std_logic;
  signal dbg_dec_cq_clk_r         : std_logic;
  signal dbg_inc_cqn_clk_r        : std_logic;
  signal dbg_dec_cqn_clk_r        : std_logic;
  signal dbg_inc_q_all_clk_r      : std_logic;
  signal dbg_dec_q_all_clk_r      : std_logic;
  signal dbg_inc_cq_all_clk_r     : std_logic;
  signal dbg_dec_cq_all_clk_r     : std_logic;
  signal dbg_inc_cqn_all_clk_r    : std_logic;
  signal dbg_dec_cqn_all_clk_r    : std_logic;
  signal dbg_sel_q_clkrd_r        : std_logic_vector(Q_BITS-1 downto 0);
  signal dbg_sel_cq_clkrd_r       : std_logic_vector(CQ_BITS-1 downto 0);
  signal dbg_sel_cqn_clkrd_r      : std_logic_vector(CQ_BITS-1 downto 0);
  signal dbg_inc_q_clkrd_r        : std_logic;
  signal dbg_dec_q_clkrd_r        : std_logic;
  signal dbg_inc_cq_clkrd_r       : std_logic;
  signal dbg_dec_cq_clkrd_r       : std_logic;
  signal dbg_inc_cqn_clkrd_r      : std_logic;
  signal dbg_dec_cqn_clkrd_r      : std_logic; 
  signal dbg_inc_q_all_clkrd_r    : std_logic;
  signal dbg_dec_q_all_clkrd_r    : std_logic;
  signal dbg_inc_cq_all_clkrd_r   : std_logic;
  signal dbg_dec_cq_all_clkrd_r   : std_logic;
  signal dbg_inc_cqn_all_clkrd_r  : std_logic;
  signal dbg_dec_cqn_all_clkrd_r  : std_logic;

  signal not_fifo_empty : std_logic;


  --Attributes for ASYNC_REG
  attribute ASYNC_REG of q_bit_clkinv_clkrd_r     : signal is "TRUE";
  attribute ASYNC_REG of phase_clkrd_r            : signal is "TRUE";
  attribute ASYNC_REG of cal_stage1_done_clkrd_r  : signal is "TRUE";
  attribute ASYNC_REG of cal_stage2_done_clkrd_r  : signal is "TRUE";
  attribute ASYNC_REG of pd_calib_done_clk        : signal is "TRUE";

  begin
  
  -- Indicate when q_bit and cq_num have changed so that it can be
  -- used to trigger a write enable to the FIFO.
  process (clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        q_bit_active_clk_r  <= (others =>'0') after TCQ*1 ps;
        cq_num_active_clk_r <= (others =>'0') after TCQ*1 ps;
      else
        q_bit_active_clk_r  <= q_bit_active_clk after TCQ*1 ps;
        cq_num_active_clk_r <= cq_num_active_clk after TCQ*1 ps;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        q_bit_changed   <= '0' after TCQ*1 ps;
        cq_num_changed  <= '0' after TCQ*1 ps;
      else
        if ((q_bit_active_clk = q_bit_active_clk_r)) then
          q_bit_changed <= '0' after TCQ*1 ps;    
        else
          q_bit_changed <= '1' after TCQ*1 ps;
        end if;

        if ((cq_num_active_clk = cq_num_active_clk_r)) then
          cq_num_changed  <= '0' after TCQ*1 ps;
        else
          cq_num_changed  <= '1' after TCQ*1 ps;
        end if;
      end if;
    end if;
  end process;

  -- Only write to the FIFO when active control is present
  wr_en <= (cq_num_rst_clk or cq_num_ce_clk or
            cqn_num_rst_clk or cqn_num_ce_clk or
            q_bit_rst_clk or q_bit_ce_clk or
            q_bit_changed or cq_num_changed) and (not(rst_clk));
 

   fifo_wr_data(35 downto 24+Q_BITS+CQ_BITS)          <= (others => '0');
   fifo_wr_data(24+Q_BITS+CQ_BITS-1 downto 24+Q_BITS) <= cq_num_active_clk;
   fifo_wr_data(24+Q_BITS-1 downto 24)                <= q_bit_active_clk;
   fifo_wr_data(23)                                   <= cq_num_rst_clk;
   fifo_wr_data(22)                                   <= cq_num_ce_clk;
   fifo_wr_data(21)                                   <= cq_num_inc_clk;
   fifo_wr_data(20)                                   <= cqn_num_rst_clk;
   fifo_wr_data(19)                                   <= cqn_num_ce_clk;
   fifo_wr_data(18)                                   <= cqn_num_inc_clk;
   fifo_wr_data(17)                                   <= q_bit_rst_clk;
   fifo_wr_data(16)                                   <= q_bit_ce_clk;
   fifo_wr_data(15)                                   <= q_bit_inc_clk;
   fifo_wr_data(14 downto 10)                         <= cq_num_load_clk;
   fifo_wr_data(9 downto 5)                           <= cqn_num_load_clk;
   fifo_wr_data(4 downto 0)                           <= q_bit_load_clk;
    
   not_fifo_empty <= not(fifo_empty);

   -- Cross clock domains through async FIFO to avoid losing pulses
   u_read_sync_afifo : FIFO18E1 
   generic map(
     DATA_WIDTH               => 36,
     DO_REG                   => 1,
     EN_SYN                   => false,
     FIFO_MODE                => "FIFO18_36",
     FIRST_WORD_FALL_THROUGH  => false
   ) 
  port map (
     DI           => fifo_wr_data(31 downto 0),
     DIP          => fifo_wr_data(35 downto 32),
     RDCLK        => clk_rd,
     RDEN         => not_fifo_empty,
     REGCE        => '1',
     RST          => rst_clk,
     RSTREG       => '0',
     WRCLK        => clk,
     WREN         => wr_en,
     ALMOSTEMPTY  => open,
     ALMOSTFULL   => open,
     DO           => fifo_rd_data(31 downto 0),
     DOP          => fifo_rd_data(35 downto 32),
     EMPTY        => fifo_empty,
     FULL         => open,
     RDCOUNT      => open,
     RDERR        => open,
     WRCOUNT      => open,
     WRERR        => open
   );
 
  -- Only read from FIFO when there is something to read (not empty)
  process (clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        rd_en   <= '0' after TCQ*1 ps;
      else
        rd_en   <= not(fifo_empty) after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  q_bit_load_int     <= fifo_rd_data(4 downto 0);
  cqn_num_load_int   <= fifo_rd_data(9 downto 5);
  cq_num_load_int    <= fifo_rd_data(14 downto 10);
  q_bit_inc_int      <= fifo_rd_data(15);
  q_bit_ce_int       <= fifo_rd_data(16);
  q_bit_rst_int      <= fifo_rd_data(17);
  cqn_num_inc_int    <= fifo_rd_data(18);
  cqn_num_ce_int     <= fifo_rd_data(19);
  cqn_num_rst_int    <= fifo_rd_data(20);
  cq_num_inc_int     <= fifo_rd_data(21);
  cq_num_ce_int      <= fifo_rd_data(22);
  cq_num_rst_int     <= fifo_rd_data(23);
  q_bit_active_int   <= fifo_rd_data((24+Q_BITS-1) downto 24);
  cq_num_active_int  <= fifo_rd_data((24+Q_BITS+CQ_BITS-1) downto 24+Q_BITS);

  -- Only assign control from the fifo outputs when there is valid data
  -- present in the fifo. Otherwise, tie off to zero to prevent invalid
  -- active control from being assigned.
  process (clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        q_bit_load    <= (others =>'0') after TCQ*1 ps;
        cqn_num_load  <= (others => '0') after TCQ*1 ps;
        cq_num_load   <= (others => '0') after TCQ*1 ps;
        q_bit_inc     <= '0' after TCQ*1 ps;
        q_bit_ce      <= '0' after TCQ*1 ps;
        q_bit_rst     <= '0' after TCQ*1 ps;
        cqn_num_inc   <= '0' after TCQ*1 ps;
        cqn_num_ce    <= '0' after TCQ*1 ps;
        cqn_num_rst   <= '0' after TCQ*1 ps;
        cq_num_inc    <= '0' after TCQ*1 ps;
        cq_num_ce     <= '0' after TCQ*1 ps;
        cq_num_rst    <= '0' after TCQ*1 ps;
        q_bit_active  <= (others => '0') after TCQ*1 ps;
        cq_num_active <= (others => '0') after TCQ*1 ps;
      else
        q_bit_load    <= q_bit_load_int after TCQ*1 ps;
        cqn_num_load  <= cqn_num_load_int after TCQ*1 ps;
        cq_num_load   <= cq_num_load_int after TCQ*1 ps;
        q_bit_inc     <= q_bit_inc_int after TCQ*1 ps;
        cqn_num_inc   <= cqn_num_inc_int after TCQ*1 ps;
        cq_num_inc    <= cq_num_inc_int after TCQ*1 ps;
        q_bit_active  <= q_bit_active_int after TCQ*1 ps;
        cq_num_active <= cq_num_active_int after TCQ*1 ps;

        if (rd_en = '1') then
          cq_num_ce     <= cq_num_ce_int after TCQ*1 ps;
          cq_num_rst    <= cq_num_rst_int after TCQ*1 ps;
          cqn_num_ce    <= cqn_num_ce_int after TCQ*1 ps;
          cqn_num_rst   <= cqn_num_rst_int after TCQ*1 ps;
          q_bit_ce      <= q_bit_ce_int after TCQ*1 ps;
          q_bit_rst     <= q_bit_rst_int after TCQ*1 ps;
        else
          cq_num_ce     <= '0';
          cq_num_rst    <= '0';
          cqn_num_ce    <= '0';
          cqn_num_rst   <= '0';
          q_bit_ce      <= '0';
          q_bit_rst     <= '0';
        end if;
      end if;
    end if;
  end process;

  -- register vio signals into clk domain
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        dbg_inc_cq_all_r   <= '0' after TCQ*1 ps;    
        dbg_inc_cqn_all_r  <= '0' after TCQ*1 ps;  
        dbg_inc_q_all_r    <= '0' after TCQ*1 ps;
        dbg_dec_cq_all_r   <= '0' after TCQ*1 ps;  
        dbg_dec_cqn_all_r  <= '0' after TCQ*1 ps;  
        dbg_dec_q_all_r    <= '0' after TCQ*1 ps;  
        dbg_inc_cq_r       <= '0' after TCQ*1 ps;  
        dbg_inc_cqn_r      <= '0' after TCQ*1 ps;  
        dbg_inc_q_r        <= '0' after TCQ*1 ps;  
        dbg_dec_cq_r       <= '0' after TCQ*1 ps;  
        dbg_dec_cqn_r      <= '0' after TCQ*1 ps;  
        dbg_dec_q_r        <= '0' after TCQ*1 ps;  
        dbg_sel_cq_r       <= (others => '0') after TCQ*1 ps;  
        dbg_sel_cqn_r      <= (others => '0') after TCQ*1 ps;  
        dbg_sel_q_r        <= (others => '0') after TCQ*1 ps;   
        dbg_inc_cq_all_2r  <= '0' after TCQ*1 ps;    
        dbg_inc_cqn_all_2r <= '0' after TCQ*1 ps;  
        dbg_inc_q_all_2r   <= '0' after TCQ*1 ps;
        dbg_dec_cq_all_2r  <= '0' after TCQ*1 ps;  
        dbg_dec_cqn_all_2r <= '0' after TCQ*1 ps;  
        dbg_dec_q_all_2r   <= '0' after TCQ*1 ps;  
        dbg_inc_cq_2r      <= '0' after TCQ*1 ps;  
        dbg_inc_cqn_2r     <= '0' after TCQ*1 ps;  
        dbg_inc_q_2r       <= '0' after TCQ*1 ps;  
        dbg_dec_cq_2r      <= '0' after TCQ*1 ps;  
        dbg_dec_cqn_2r     <= '0' after TCQ*1 ps;  
        dbg_dec_q_2r       <= '0' after TCQ*1 ps;  
        dbg_sel_cq_2r      <= (others => '0') after TCQ*1 ps;  
        dbg_sel_cqn_2r     <= (others => '0') after TCQ*1 ps;  
        dbg_sel_q_2r       <= (others => '0') after TCQ*1 ps; 
      else
        dbg_inc_cq_all_r   <= dbg_inc_cq_all after TCQ*1 ps;    
        dbg_inc_cqn_all_r  <= dbg_inc_cqn_all after TCQ*1 ps;  
        dbg_inc_q_all_r    <= dbg_inc_q_all after TCQ*1 ps;
        dbg_dec_cq_all_r   <= dbg_dec_cq_all after TCQ*1 ps;  
        dbg_dec_cqn_all_r  <= dbg_dec_cqn_all after TCQ*1 ps;  
        dbg_dec_q_all_r    <= dbg_dec_q_all after TCQ*1 ps;  
        dbg_inc_cq_r       <= dbg_inc_cq after TCQ*1 ps;  
        dbg_inc_cqn_r      <= dbg_inc_cqn after TCQ*1 ps;  
        dbg_inc_q_r        <= dbg_inc_q after TCQ*1 ps;  
        dbg_dec_cq_r       <= dbg_dec_cq after TCQ*1 ps;  
        dbg_dec_cqn_r      <= dbg_dec_cqn after TCQ*1 ps;  
        dbg_dec_q_r        <= dbg_dec_q after TCQ*1 ps;  
        dbg_sel_cq_r       <= dbg_sel_cq after TCQ*1 ps;  
        dbg_sel_cqn_r      <= dbg_sel_cqn after TCQ*1 ps;  
        dbg_sel_q_r        <= dbg_sel_q after TCQ*1 ps;   
        dbg_inc_cq_all_2r  <= dbg_inc_cq_all_r after TCQ*1 ps;    
        dbg_inc_cqn_all_2r <= dbg_inc_cqn_all_r after TCQ*1 ps;  
        dbg_inc_q_all_2r   <= dbg_inc_q_all_r after TCQ*1 ps;
        dbg_dec_cq_all_2r  <= dbg_dec_cq_all_r after TCQ*1 ps;  
        dbg_dec_cqn_all_2r <= dbg_dec_cqn_all_r after TCQ*1 ps;  
        dbg_dec_q_all_2r   <= dbg_dec_q_all_r after TCQ*1 ps;  
        dbg_inc_cq_2r      <= dbg_inc_cq_r after TCQ*1 ps;  
        dbg_inc_cqn_2r     <= dbg_inc_cqn_r after TCQ*1 ps;  
        dbg_inc_q_2r       <= dbg_inc_q_r after TCQ*1 ps;  
        dbg_dec_cq_2r      <= dbg_dec_cq_r after TCQ*1 ps;  
        dbg_dec_cqn_2r     <= dbg_dec_cqn_r after TCQ*1 ps;  
        dbg_dec_q_2r       <= dbg_dec_q_r after TCQ*1 ps;  
        dbg_sel_cq_2r      <= dbg_sel_cq_r after TCQ*1 ps;  
        dbg_sel_cqn_2r     <= dbg_sel_cqn_r after TCQ*1 ps;  
        dbg_sel_q_2r       <= dbg_sel_q_r after TCQ*1 ps; 
      end if; 
    end if;
  end process;
  
  -- Synchronize signals going from clk domain to clk_rd domain

  -- First register all signals in the clk domain
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        q_bit_clkinv_clk_r    <= '0' after TCQ*1 ps;
        phase_clk_r           <= '0' after TCQ*1 ps;
        cal_stage1_done_clk_r <= '0' after TCQ*1 ps;
        cal_stage2_done_clk_r <= '0' after TCQ*1 ps;
      else
        q_bit_clkinv_clk_r    <= q_bit_clkinv_clk after TCQ*1 ps;
        phase_clk_r           <= phase_clk after TCQ*1 ps;
        cal_stage1_done_clk_r <= cal_stage1_done_clk after TCQ*1 ps;
        cal_stage2_done_clk_r <= cal_stage2_done_clk after TCQ*1 ps;
      end if;
    end if;
  end process;
    
  dbg_sel_q_clk_r       <= dbg_sel_q_2r when (DEBUG_PORT = "ON") else (others => '0');
  dbg_sel_cq_clk_r      <= dbg_sel_cq_2r when (DEBUG_PORT = "ON") else (others => '0');
  dbg_sel_cqn_clk_r     <= dbg_sel_cqn_2r when (DEBUG_PORT = "ON") else (others => '0');
  dbg_inc_q_clk_r       <= dbg_inc_q_2r when (DEBUG_PORT = "ON") else '0';
  dbg_dec_q_clk_r       <= dbg_dec_q_2r when (DEBUG_PORT = "ON") else '0';
  dbg_inc_cq_clk_r      <= dbg_inc_cq_2r when (DEBUG_PORT = "ON") else '0';
  dbg_dec_cq_clk_r      <= dbg_dec_cq_2r when (DEBUG_PORT = "ON") else '0';
  dbg_inc_cqn_clk_r     <= dbg_inc_cqn_2r when (DEBUG_PORT = "ON") else '0';
  dbg_dec_cqn_clk_r     <= dbg_dec_cqn_2r when (DEBUG_PORT = "ON") else '0';
  dbg_inc_q_all_clk_r   <= dbg_inc_q_all_2r when (DEBUG_PORT = "ON") else '0';
  dbg_dec_q_all_clk_r   <= dbg_dec_q_all_2r when (DEBUG_PORT = "ON") else '0';
  dbg_inc_cq_all_clk_r  <= dbg_inc_cq_all_2r when (DEBUG_PORT = "ON") else '0';
  dbg_dec_cq_all_clk_r  <= dbg_dec_cq_all_2r when (DEBUG_PORT = "ON") else '0';
  dbg_inc_cqn_all_clk_r <= dbg_inc_cqn_all_2r when (DEBUG_PORT = "ON") else '0';
  dbg_dec_cqn_all_clk_r <= dbg_dec_cqn_all_2r when (DEBUG_PORT = "ON") else '0';

  -- Now double register each signal into the clk_rd domain  process(clk)
  process (clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        q_bit_clkinv_clkrd_r    <= '0' after TCQ*1 ps;
        q_bit_clkinv_int        <= '0' after TCQ*1 ps;
        phase_clkrd_r           <= '0' after TCQ*1 ps;
        phase                   <= '0' after TCQ*1 ps;
        cal_stage1_done_clkrd_r <= '0' after TCQ*1 ps;
        cal_stage1_done         <= '0' after TCQ*1 ps;
        cal_stage2_done_clkrd_r <= '0' after TCQ*1 ps;
        cal_stage2_done         <= '0' after TCQ*1 ps;
      else
        q_bit_clkinv_clkrd_r    <= q_bit_clkinv_clk_r after TCQ*1 ps;
        q_bit_clkinv_int        <= q_bit_clkinv_clkrd_r after TCQ*1 ps;
        phase_clkrd_r           <= phase_clk_r after TCQ*1 ps;
        phase                   <= phase_clkrd_r after TCQ*1 ps;
        cal_stage1_done_clkrd_r <= cal_stage1_done_clk_r after TCQ*1 ps;
        cal_stage1_done         <= cal_stage1_done_clkrd_r after TCQ*1 ps;
        cal_stage2_done_clkrd_r <= cal_stage2_done_clk_r after TCQ*1 ps;
        cal_stage2_done         <= cal_stage2_done_clkrd_r after TCQ*1 ps; 
      
        --chipscope debug controls for CQ & Q
        dbg_sel_q_clkrd_r       <= dbg_sel_q_clk_r after TCQ*1 ps;   
        dbg_sel_cq_clkrd_r      <= dbg_sel_cq_clk_r after TCQ*1 ps;   
        dbg_sel_cqn_clkrd_r     <= dbg_sel_cqn_clk_r after TCQ*1 ps;    
        dbg_inc_q_clkrd_r       <= dbg_inc_q_clk_r after TCQ*1 ps;    
        dbg_dec_q_clkrd_r       <= dbg_dec_q_clk_r after TCQ*1 ps;
        dbg_inc_cq_clkrd_r      <= dbg_inc_cq_clk_r after TCQ*1 ps;    
        dbg_dec_cq_clkrd_r      <= dbg_dec_cq_clk_r after TCQ*1 ps; 
        dbg_inc_cqn_clkrd_r     <= dbg_inc_cqn_clk_r after TCQ*1 ps;    
        dbg_dec_cqn_clkrd_r     <= dbg_dec_cqn_clk_r after TCQ*1 ps;  
        dbg_inc_q_all_clkrd_r   <= dbg_inc_q_all_clk_r after TCQ*1 ps;
        dbg_dec_q_all_clkrd_r   <= dbg_dec_q_all_clk_r after TCQ*1 ps;
        dbg_inc_cq_all_clkrd_r  <= dbg_inc_cq_all_clk_r after TCQ*1 ps;
        dbg_dec_cq_all_clkrd_r  <= dbg_dec_cq_all_clk_r after TCQ*1 ps;
        dbg_inc_cqn_all_clkrd_r <= dbg_inc_cqn_all_clk_r after TCQ*1 ps;
        dbg_dec_cqn_all_clkrd_r <= dbg_dec_cqn_all_clk_r after TCQ*1 ps; 
        dbg_sel_q_clkrd         <= dbg_sel_q_clkrd_r after TCQ*1 ps;
        dbg_sel_cq_clkrd        <= dbg_sel_cq_clkrd_r after TCQ*1 ps;  
        dbg_sel_cqn_clkrd       <= dbg_sel_cqn_clkrd_r after TCQ*1 ps;  
        dbg_inc_q_clkrd         <= dbg_inc_q_clkrd_r after TCQ*1 ps;    
        dbg_dec_q_clkrd         <= dbg_dec_q_clkrd_r after TCQ*1 ps;
        dbg_inc_cq_clkrd        <= dbg_inc_cq_clkrd_r after TCQ*1 ps;    
        dbg_dec_cq_clkrd        <= dbg_dec_cq_clkrd_r after TCQ*1 ps;
        dbg_inc_cqn_clkrd       <= dbg_inc_cqn_clkrd_r after TCQ*1 ps;    
        dbg_dec_cqn_clkrd       <= dbg_dec_cqn_clkrd_r after TCQ*1 ps;   
        dbg_inc_q_all_clkrd     <= dbg_inc_q_all_clkrd_r after TCQ*1 ps;
        dbg_dec_q_all_clkrd     <= dbg_dec_q_all_clkrd_r after TCQ*1 ps;
        dbg_inc_cq_all_clkrd    <= dbg_inc_cq_all_clkrd_r after TCQ*1 ps;
        dbg_dec_cq_all_clkrd    <= dbg_dec_cq_all_clkrd_r after TCQ*1 ps;
        dbg_inc_cqn_all_clkrd   <= dbg_inc_cqn_all_clkrd_r after TCQ*1 ps;
        dbg_dec_cqn_all_clkrd   <= dbg_dec_cqn_all_clkrd_r after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Further delay the clock invert signal to stay aligned with
  -- cq_num_active
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        q_bit_clkinv_int_r  <= '0' after TCQ*1 ps;
        q_bit_clkinv_int_2r <= '0' after TCQ*1 ps;
        q_bit_clkinv        <= '0' after TCQ*1 ps;
      else
        q_bit_clkinv_int_r  <= q_bit_clkinv_int after TCQ*1 ps;
        q_bit_clkinv_int_2r <= q_bit_clkinv_int_r after TCQ*1 ps;
        q_bit_clkinv        <= q_bit_clkinv_int_2r after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Synchronize signals going from clk_rd domain to clk domain

  -- First register all signals in the clk_rd domain
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        pd_calib_done_clkrd_r <= '0' after TCQ*1 ps;
      else
        pd_calib_done_clkrd_r <= pd_calib_done after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Now double register each signal into the clk domain
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        pd_calib_done_clk   <= '0' after TCQ*1 ps;
        pd_calib_done_clk_r <= '0' after TCQ*1 ps;
      else
        pd_calib_done_clk   <= pd_calib_done_clkrd_r after TCQ*1 ps;
        pd_calib_done_clk_r <= pd_calib_done_clk after TCQ*1 ps;
      end if;
    end if;
  end process;


end architecture arch;
