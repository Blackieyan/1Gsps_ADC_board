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
--  /   /         Filename           : phy_reset_sync.vhd
-- /___/   /\     Timestamp          : 
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This module
--  reset synchronization and memory initialization
--Revision History:
--
--/////////////////////////////////////////////////////////////////////////////
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity phy_reset_sync is
  generic(
    CLK_STABLE      : integer := 2048;   --Cycles till CQ/CQ# are stable
    CLK_PERIOD      : integer := 3752;   --Internal Fabric Clk Period (in ps)
    RST_ACT_LOW     : integer := 1;      --sys reset is active low
    NUM_DEVICES     : integer := 2;      --No. of Memory Devices
    SIM_INIT_OPTION : string  := "NONE"; --Simulation Only mode
    TCQ             : integer := 100     --Register Delay
  );
  port(
    sys_rst          : in  std_logic;    --System Reset from MMCM
    clk              : in  std_logic;    --Half Freq. System Clock
    rst_clk          : out std_logic;    --Reset Sync to CLK
    rst_wr_clk       : out std_logic;    --Reset Sync to CLK for write path only
    --Read Path clock generated from CQ/CQ#
    clk_rd           : in  std_logic_vector(NUM_DEVICES-1 downto 0); 
  --Reset Sync to CLK_RD    
    rst_clk_rd       : out std_logic_vector(NUM_DEVICES-1 downto 0); 
    mmcm_locked      : in  std_logic;    --MMCM clocks are locked
    iodelay_ctrl_rdy : in  std_logic;    --IODELAY controller ready signal
    mem_dll_off_n    : out std_logic     --DLL off signal to Memory Device
  );

  attribute shreg_extract : string;
  attribute shreg_extract of rst_clk     : signal is "no";
  attribute shreg_extract of rst_wr_clk   : signal is "no";
  attribute shreg_extract of rst_clk_rd  : signal is "no";

end phy_reset_sync;

architecture arch of phy_reset_sync is

  -- # of clock cycles to delay deassertion of reset. Needs to be a fairly
  -- high number not so much for metastability protection, but to give time
  -- for reset (i.e. stable clock cycles) to propagate through all state
  -- machines and to all control signals (i.e. not all control signals have
  -- resets, instead they rely on base state logic being reset, and the effect
  -- of that reset propagating through the logic). Need this because we may not
  -- be getting stable clock cycles while reset asserted (i.e. since reset
  -- depends on DCM lock status)
  constant RST_SYNC_NUM : integer := 5;  --*FIXME*

  --Calculate the number of cycles needed for 200 us.  This is used to
  --initialize the memory device and turn off the dll signal to it.
  function CALC_INIT_DONE return integer is
  begin
    if (SIM_INIT_OPTION /= "NONE") then
      return 10;
    else
      return (200*1000*1000/CLK_PERIOD);
    end if;
  end function CALC_INIT_DONE;
  constant INIT_DONE : integer := CALC_INIT_DONE;

  --Signal Delcarations
  signal sys_rst_act_hi       : std_logic;       
  signal rst_wr_clk_tmp       : std_logic;              
  signal rst_clk_tmp          : std_logic;           
  signal rst_clk_rd_tmp      : std_logic_vector(NUM_DEVICES-1 downto 0);     
        
  signal init_cnt_done        : std_logic;           
  signal init_cnt_done_r      : std_logic;             
  signal cq_stable            : std_logic;      
  signal cq_cnt               : std_logic_vector(11 downto 0);           
  signal init_cnt             : std_logic_vector(16 downto 0);           

  --Initialize all bits to 1
  
  
  signal  rst_wr_clk_sync_r    : std_logic_vector(RST_SYNC_NUM-1 downto 0)    
                                                            := (others => '1');
                               
  signal  rst_clk_sync_r       : std_logic_vector(RST_SYNC_NUM-1 downto 0)  
                                                            := (others => '1'); 
                                                            
  type rst_clk_rd_sync_r_type is array (NUM_DEVICES-1 downto 0) 
                              of std_logic_vector (RST_SYNC_NUM-1 downto 0);
  signal rst_clk_rd_sync_r : rst_clk_rd_sync_r_type; 

  signal rst_wr_clk_sig         : std_logic;
  attribute shreg_extract of rst_wr_clk_sig     : signal is "no";
    
  attribute max_fanout               : string;
  attribute max_fanout of rst_wr_clk_sync_r    : signal is "50";
  attribute max_fanout of rst_clk_sync_r       : signal is "50";

  
  begin

  -----------------------------------------------------------------------------
  --Reset Synchronization Logic
  -- 1. RST_WR_CLK - Synchronized to CLK however should also be 
  -- held as long as the clocks are not locked indicated by the mmcm or 
  -- if the IODELAY controller is not ready yet
  --
  -- 2. RST_CLK - This reset is sync. to CLK and should be held as long as
  -- clocks CQ/CQ# coming back from the memory device is not yet stable.  
  -- It is assumed stable based on the parameter CLK_STABLE taken from the
  -- memory spec.
  --
  -- 3. RST_CLK_RD - Synchonronized to clk_rd, this reset should be held until
  -- clocks CQ/CQ# are stable.
  -----------------------------------------------------------------------------
  sys_rst_act_hi  <= not(sys_rst) when RST_ACT_LOW = 1 else sys_rst;
  rst_wr_clk_tmp  <= not(mmcm_locked) or sys_rst_act_hi or not(iodelay_ctrl_rdy);
  rst_clk_tmp     <= not(cq_stable) or sys_rst_act_hi;
 
  RST_CLK_RD_TMP_GEN:  
  for i in 0 to (NUM_DEVICES-1) generate
  begin
    process(cq_stable, sys_rst_act_hi)
    begin
      rst_clk_rd_tmp(i)  <= not(cq_stable) or sys_rst_act_hi;
    end process;
  end generate;

  process(clk, rst_wr_clk_tmp)
  begin
    if (rst_wr_clk_tmp = '1') then
      rst_wr_clk_sync_r <= (others => '1') after TCQ*1 ps;
    elsif (clk'event and clk = '1') then
      -- logical left shift by one (pads with 0)
      rst_wr_clk_sync_r <= rst_wr_clk_sync_r(RST_SYNC_NUM-2 downto 0) & '0' after TCQ*1 ps;
    end if;
  end process;
 
  rst_wr_clk_sig <= rst_wr_clk_sync_r(RST_SYNC_NUM-1);
  rst_wr_clk     <= rst_wr_clk_sig;

  process(clk, rst_clk_tmp)
  begin
    if (rst_clk_tmp = '1') then
      rst_clk_sync_r <= (others => '1') after TCQ*1 ps;
    elsif (clk'event and clk='1') then 
      -- logical left shift by one (pads with 0)
      rst_clk_sync_r <= rst_clk_sync_r(RST_SYNC_NUM-2 downto 0) & '0' after TCQ*1 ps;
    end if;
  end process;
  
   rst_clk <= rst_clk_sync_r(RST_SYNC_NUM-1);
  
  RST_CLK_RD_SYNC_R_GEN:
  for j in 0 to (NUM_DEVICES-1) generate
  begin
    process(clk_rd, rst_clk_rd_tmp)
    begin
      if (rst_clk_rd_tmp(j) = '1') then
        rst_clk_rd_sync_r(j) <= (others => '1') after TCQ*1 ps;
      elsif rising_edge(clk_rd(j)) then
        rst_clk_rd_sync_r(j) <= rst_clk_rd_sync_r(j)(RST_SYNC_NUM-2 downto 0) & '0' after TCQ*1 ps;    
      end if;
    end process;
  end generate;

  RST_CLK_RD_GEN:
    for k in 0 to (NUM_DEVICES-1) generate
      rst_clk_rd(k) <= rst_clk_rd_sync_r(k)(RST_SYNC_NUM-1);
   end generate;

  -----------------------------------------------------------------------------
  --Initialization Logic for Memory
  --The counters below are used to determine when the CQ/CQ# clocks are stable
  --and memory initialization is complete.
  --This logic operates on the same clock and reset as the write path logic to
  --ensure the counters are in sync to that of driving the K/K# clocks.  They
  --should remain in sync as CQ/CQ# are echos of K/K#
  -----------------------------------------------------------------------------

  --init_cnt generates a 200 us counter based on CLK_PERIOD.
  --This counter is needed to determine when to turn of the dll signal to
  --memory and initialization of the memory is considered complete.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if (rst_wr_clk_sig = '1') then 
        init_cnt <= (others => '0') after TCQ*1 ps;
      elsif ((init_cnt_done_r = '0' and (CONV_INTEGER(init_cnt) /= INIT_DONE))) then 
        init_cnt <= init_cnt + "0000000000001" after TCQ*1 ps;    
      end if;
    end if;
  end process;

  --Signal init_cnt_done once 200 us is up
  process(clk)
  begin
    if (clk'event and clk='1') then 
      if (rst_wr_clk_sig = '1') then
        init_cnt_done   <= '0' after TCQ*1 ps;
        init_cnt_done_r <= '0' after TCQ*1 ps;      
      elsif (conv_integer(init_cnt) = INIT_DONE) then
        init_cnt_done   <= '1' after TCQ*1 ps;
        init_cnt_done_r <= init_cnt_done after TCQ*1 ps;
      end if;
    end if;
  end process;

  mem_dll_off_n <= init_cnt_done_r;  
  
  -- Count CLK_STABLE cycles to determine that CQ/CQ# clocks are stable.  When
  -- ready, both RST_CLK and RST_CLK_RD can come out of reset.  Only start
  -- counting once the the initial count for memory is complete (ie
  -- init_cnt_done_r)
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_wr_clk_sig = '1') then 
        cq_cnt <= (others => '0');
      elsif (init_cnt_done_r = '1' and cq_cnt /= CLK_STABLE) then
        cq_cnt <= cq_cnt + "000000000001";
      else
        cq_cnt <= cq_cnt;
      end if;
    end if;
  end process;
  
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_wr_clk_sig = '1') then
        cq_stable <= '0' after TCQ*1 ps;
      elsif (cq_cnt = CLK_STABLE) then 
        cq_stable <= '1' after TCQ*1 ps;
      else
        cq_stable <= cq_stable after TCQ*1 ps;
      end if;
    end if;
  end process;
  

  
end architecture arch;
