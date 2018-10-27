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
--  /   /         Filename           : phy_ocb_mon.vhd
-- /___/   /\     Timestamp          : 
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--
--/////////////////////////////////////////////////////////////////////////////
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity qdr_rld_phy_ocb_mon is
  generic(
    SIM_CAL_OPTION  : string := "NONE";   -- "NONE", "FAST_CAL", "SKIP_CAL"
    SIM_INIT_OPTION : string := "NONE";   -- "NONE", "SIM_MODE"
    TCQ             : integer:= 100       -- Register Delay
  );
  port(
    dbg_ocb_mon          : out std_logic_vector(255 downto 0);  -- debug signals
    ocb_mon_PSEN         : out std_logic;   -- to MCMM_ADV
    ocb_mon_PSINCDEC     : out std_logic;   -- to MCMM_ADV
    ocb_mon_calib_done   : out std_logic;   -- ocb clock calibration done
    ocb_wc               : out std_logic;   -- to OSERDESE1

    ocb_extend           : in std_logic;    -- from OSERDESE1
    ocb_mon_PSDONE       : in std_logic;    -- from MCMM_ADV
    ocb_mon_go           : in std_logic;    -- start the OCB monitor state machine 
    clk                  : in std_logic;    -- clkmem/2
    rst                  : in std_logic;          
    ocb_enabled_n        : in std_logic            
   );
end qdr_rld_phy_ocb_mon;

architecture arch of qdr_rld_phy_ocb_mon is

  --***************************************************************************
  -- Local signals (other than state assignments)
  --***************************************************************************

  -- width of high counter (11 for synthesis, less for simulation)
  function CALC_HC_WIDTH return integer is
  begin
    if (SIM_CAL_OPTION = "FAST_CAL" or SIM_INIT_OPTION = "SIM_MODE"
        or SIM_INIT_OPTION = "SKIP_PU_DLY") then
      return 1;
    else
      return 11;
    end if;
  end function CALC_HC_WIDTH;
  constant hc_width  : integer := CALC_HC_WIDTH;

  -- width of calibration done counter (6 for synthesis, less for simulation)
  function CALC_CDC_WIDTH return integer is
  begin
    if (SIM_CAL_OPTION = "FAST_CAL" or SIM_INIT_OPTION = "SIM_MODE"
        or SIM_INIT_OPTION = "SKIP_PU_DLY") then
      return 2;
   else
      return 6;
    end if;
  end function CALC_CDC_WIDTH;
  constant cdc_width  : integer := CALC_CDC_WIDTH; 

  constant c_width    : integer := 4; -- width of clk cycle counter

  --***************************************************************************
  -- ocb state assignments
  --***************************************************************************

  constant OCB_IDLE         : std_logic_vector(2 downto 0) := "000";
  constant OCB_OUTSIDE_LOOP : std_logic_vector(2 downto 0) := "001";
  constant OCB_INSIDE_LOOP  : std_logic_vector(2 downto 0) := "010";
  constant OCB_WAIT1        : std_logic_vector(2 downto 0) := "011";
  constant OCB_INSIDE_JMP   : std_logic_vector(2 downto 0) := "100";
  constant OCB_UPDATE       : std_logic_vector(2 downto 0) := "101";
  constant OCB_WAIT2        : std_logic_vector(2 downto 0) := "110";


  --***************************************************************************
  -- Internal signals
  --***************************************************************************
  signal reset           : std_logic;         -- rst is synchronized to clk
  signal ocb_state_r       : std_logic_vector(2 downto 0);
  signal ocb_next_state     : std_logic_vector(2 downto 0);
  signal high             : std_logic_vector(hc_width-1 downto 0); -- high counter
  signal samples           : std_logic_vector(hc_width downto 0);  -- sample counter
  -- cycle counter _vector(to wait after wc is pulsed)
  signal cycles           : std_logic_vector(c_width-1 downto 0);             
                                     
  signal inc_cntrs         : std_logic;   
  signal clr_high         : std_logic;
  signal high_ce           : std_logic;
  signal clr_samples       : std_logic;
  signal samples_ce         : std_logic;
  signal clr_cycles         : std_logic;
  signal cycles_ce         : std_logic;
  signal update_phase       : std_logic;
  signal calib_done_cntr     : std_logic_vector(cdc_width-1 downto 0);
  signal calib_done_cntr_inc   : std_logic;
  signal calib_done_cntr_ce   : std_logic;
  signal high_gt_low       : std_logic;         
  
  -- These 4 signals needed for Phase Shift Control workarounds only
  --signal wait_psdone_ff     : std_logic;
  signal ocb_mon_go_1       : std_logic;
  --signal en_count         : std_logic;
  --signal cntr_msb         : std_logic;

  signal samples_done       : std_logic;
  signal cycles_done        : std_logic;

  signal ocb_mon_PSEN_sig     : std_logic;
  signal high_d          : std_logic_vector(hc_width-1 downto 0);
  signal samples_d        : std_logic_vector(hc_width downto 0);
  signal cycles_d          : std_logic_vector(c_width-1 downto 0);
  
  signal dbg_ocb_mon_16bit    	: std_logic_vector((16-hc_width-1) downto 0);
  signal dbg_ocb_mon_15bit    	: std_logic_vector((15-hc_width-1) downto 0);
  signal dbg_ocb_mon_8cwid    	: std_logic_vector((8-c_width-1) downto 0);
  signal dbg_ocb_mon_8cdcwid  	: std_logic_vector((8-cdc_width-1) downto 0);
  
  signal ocb_mon_PSINCDEC_sig     : std_logic;
  signal ocb_mon_calib_done_sig   : std_logic;
  signal ocb_wc_sig               : std_logic;
  
  begin
 
  --***************************************************************************
   -- Debug
   --***************************************************************************
   
   dbg_ocb_mon_16bit   <= (others => '0');
  dbg_ocb_mon_15bit   <= (others => '0');
  dbg_ocb_mon_8cwid   <= (others => '0');
  dbg_ocb_mon_8cdcwid <= (others => '0');
   
   -- Temporary debug assignments - remove for release code
   dbg_ocb_mon(0)	<= ocb_mon_PSEN_sig;
   dbg_ocb_mon(1)	<= ocb_mon_PSINCDEC_sig;
   dbg_ocb_mon(2)	<= ocb_mon_calib_done_sig;
   dbg_ocb_mon(3)	<= ocb_wc_sig;
   dbg_ocb_mon(4)	<= ocb_extend;
   dbg_ocb_mon(5)	<= ocb_mon_PSDONE;
   dbg_ocb_mon(6)	<= ocb_mon_go;
   dbg_ocb_mon(7)	<= samples_done;
   dbg_ocb_mon(8)	<= cycles_done;
   dbg_ocb_mon(9)	<= inc_cntrs;
   dbg_ocb_mon(10)	<= clr_high;
   dbg_ocb_mon(11)	<= high_ce;
   dbg_ocb_mon(12)	<= clr_samples;
   dbg_ocb_mon(13)	<= samples_ce;
   dbg_ocb_mon(14)	<= clr_cycles;
   dbg_ocb_mon(15)	<= cycles_ce;
   dbg_ocb_mon(16)	<= update_phase;
   dbg_ocb_mon(17)	<= calib_done_cntr_inc;
   dbg_ocb_mon(18)	<= calib_done_cntr_ce;
   dbg_ocb_mon(19)	<= high_gt_low;
   dbg_ocb_mon(29 downto 20) <= (others => '0');                         --spare scalor bits
   dbg_ocb_mon(33 downto 30) <= ('0' & ocb_state_r);                    --1 spare
   dbg_ocb_mon(37 downto 34) <= ('0' & ocb_next_state);                 --1 spare
   dbg_ocb_mon(38 + (hc_width -1) downto 38) <=  high;            --max(16)
   dbg_ocb_mon(53 downto 38+hc_width) <= (others => '0');            --max(16)
   dbg_ocb_mon(54 + hc_width downto 54) <= samples;         --max(16)
   dbg_ocb_mon(69 downto 54+(hc_width+1)) <= (others => '0');         --max(16)
   dbg_ocb_mon(70 + (c_width -1) downto 70) <= cycles;            --max(8)
   dbg_ocb_mon(77 downto 70 + c_width) <= (others => '0');            --max(8)
   dbg_ocb_mon(78 + (cdc_width-1) downto 78) <= calib_done_cntr; --max(8)
   dbg_ocb_mon(85 downto 78 + cdc_width) <= (others => '0'); --max(8)
   dbg_ocb_mon(255 downto 86)<= (others => '0');


  samples_done <= samples(hc_width);
  cycles_done  <= cycles(c_width-1);
  ocb_mon_PSEN <= ocb_mon_PSEN_sig;
  ocb_mon_PSINCDEC <= ocb_mon_PSINCDEC_sig;
  ocb_mon_calib_done <= ocb_mon_calib_done_sig;
  ocb_wc <= ocb_wc_sig; 
  
  
  -- V6 Engineering Samples (ES) chips require the following Phase Shift 
  -- Control workarounds:

  -- 1. Must wait for PSDONE to pulse active after the trailing edge of 
  --    RST before using the PS interface.
  -- 2. Must double pulse PSEN, with one inactive period between pulses.
  -- 3. Must maintain PSINCDEC from the PSEN though PSDONE (this is already 
  --    done, so no change to the design).

--  MMCM_ADV_PS_WA parameter no longer needed. 
--
--  gen_ps_wa:
--  if (MMCM_ADV_PS_WA(1 to 2) = "ON") generate
--  begin
--    process (clk)
--    begin
--      if (clk'event and clk='1') then  
--        wait_psdone_ff <= '1' after TCQ*1 ps;
--      end if;
--    end process;
--    
--    
--      ocb_mon_go_1 <= ocb_mon_go and wait_psdone_ff;    
--      en_count     <= update_phase or cntr_msb or ocb_mon_PSEN_sig;
--    
--    process (clk)
--    begin
--      if (clk'event and clk='1') then  
--        if (reset = '1') then
--          cntr_msb          <= '0' after TCQ*1 ps;  
--          ocb_mon_PSEN_sig  <= '0' after TCQ*1 ps;  
--        else
--          if (en_count = '1') then
--            cntr_msb          <= (cntr_msb xor ocb_mon_PSEN_sig) after TCQ*1 ps;  
--            ocb_mon_PSEN_sig  <= not(ocb_mon_PSEN_sig) after TCQ*1 ps;  
--          end if;      
--        end if;
--      end if;
--    end process;
--  end generate;
  
--  gen_ps_wa_else:
--  if (MMCM_ADV_PS_WA(1 to 2) /= "ON") generate
    ocb_mon_go_1 <= ocb_mon_go;  
    
    process (clk)
    begin
      if (clk'event and clk='1') then  
        if (reset = '1') then
          ocb_mon_PSEN_sig <= '0' after TCQ*1 ps;
        else 
          ocb_mon_PSEN_sig <= update_phase after TCQ*1 ps;
        end if;
      end if;
    end process;
--  end generate; 
  
  ocb_mon_PSINCDEC_sig <= high_gt_low;

  --***************************************************************************
  -- reset synchronization
  --***************************************************************************

  process (clk, rst)
  begin
    if (rst='1') then
      reset <= '1' after TCQ*1 ps;
    elsif (clk'event and clk='1') then
      reset <= '0' after TCQ*1 ps;
    end if;
  end process;

  --***************************************************************************
  -- State register
  --***************************************************************************

  process (clk)
  begin
    if (clk'event and clk='1') then
      if (reset='1') then
        ocb_state_r <= (others => '0') after TCQ*1 ps;
      else 
        ocb_state_r <= ocb_next_state after TCQ*1 ps;
      end if;
    end if;
  end process;

  --***************************************************************************
  -- Next ocb state
  --***************************************************************************
  process(ocb_state_r, ocb_mon_go_1, ocb_enabled_n, cycles_done, 
          samples_done, ocb_mon_PSDONE)
  begin
   -- default state is idle
      ocb_next_state <= OCB_IDLE; 
      
    case (ocb_state_r) is
      when OCB_IDLE =>      -- (0) wait for ocb_mon_go
        if (ocb_mon_go_1 = '1') then
          ocb_next_state <= OCB_OUTSIDE_LOOP;
        end if;
        
        
      when OCB_OUTSIDE_LOOP =>-- (1) clr samples counter, clr high counter
                              -- MODIFIED, 030409, RICHC - allow OCB to be 
                              -- dynamically turned on/off
        if (not(ocb_enabled_n) = '1') then
          ocb_next_state <= OCB_INSIDE_LOOP;
        else
          ocb_next_state <= OCB_OUTSIDE_LOOP;
        end if;
        
        
      when OCB_INSIDE_LOOP => -- (2) pulse ocb_wc, clr cycles counter
        ocb_next_state <= OCB_WAIT1; 
        
        
      when OCB_WAIT1 =>       -- (3) inc cycles counter
        if (cycles_done = '0') then
          ocb_next_state <= OCB_WAIT1;
        else 
          ocb_next_state <= OCB_INSIDE_JMP;
        end if;
        
        
      when OCB_INSIDE_JMP =>  -- (4) inc samples counter, conditionally inc h
        if (samples_done = '1') then
          ocb_next_state <= OCB_UPDATE;
        else 
          ocb_next_state <= OCB_INSIDE_LOOP;
        end if;
        
        
      when OCB_UPDATE =>      -- (5) pulse ocb_mon_PSEN
        ocb_next_state <= OCB_WAIT2; 
        
        
      when OCB_WAIT2 =>
        if (ocb_mon_PSDONE = '1') then
          ocb_next_state <= OCB_OUTSIDE_LOOP;
        else 
          ocb_next_state <= OCB_WAIT2;
        end if;
        
        
      when others =>   
        ocb_next_state <= OCB_IDLE;
    end case;
  end process;

  --***************************************************************************
  -- ocb state translations
  --***************************************************************************

  inc_cntrs    <= '1' when (samples_done = '0' and ocb_state_r = OCB_INSIDE_JMP)   else '0';
  clr_high     <= '1'       when ocb_state_r = OCB_OUTSIDE_LOOP  else '0';
  high_ce      <= clr_high or inc_cntrs;
  clr_samples  <= clr_high;
  samples_ce   <= clr_samples or inc_cntrs;
  clr_cycles   <= '1'       when ocb_state_r = OCB_INSIDE_LOOP  else '0';
  cycles_ce    <= '1'       when (ocb_state_r = OCB_WAIT1 or clr_cycles = '1') else '0';
  update_phase <= '1'       when ocb_state_r = OCB_UPDATE       else '0';

  --***************************************************************************
  -- ocb_mon_calib_done generator
  --***************************************************************************

  calib_done_cntr_inc <= high_gt_low xor calib_done_cntr(0);
  calib_done_cntr_ce  <= update_phase and not(calib_done_cntr(cdc_width-1));

  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (reset = '1') then
        calib_done_cntr <= (others => '0') after TCQ*1 ps;
      elsif (calib_done_cntr_ce = '1') then 
        calib_done_cntr <= calib_done_cntr + calib_done_cntr_inc after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  ocb_mon_calib_done_sig <= calib_done_cntr(cdc_width-1) or ocb_enabled_n;

  --***************************************************************************
  -- ocb_wc generator
  --***************************************************************************

  process(clk)
  begin
    if (clk'event and clk='1') then
      if (reset = '1') then
        ocb_wc_sig <= '0' after TCQ*1 ps;
      else 
        if (ocb_state_r = OCB_INSIDE_LOOP) then
          ocb_wc_sig <= '1' after TCQ*1 ps;
        else 
          ocb_wc_sig <= '0' after TCQ*1 ps;
        end if;  
      end if;
    end if;
  end process;
  
  
   --***************************************************************************
   -- high counter
   --***************************************************************************
   process (clr_high, high, ocb_extend)
      variable high_d_1 : std_logic_vector((hc_width-1) downto 0);
      variable high_d_2 : std_logic_vector((hc_width-1) downto 0);
   begin
      high_d_1 := (others => not(clr_high));
      high_d_2(0) := ocb_extend;
      high_d_2((hc_width-1) downto 1) := (others => '0');
      high_d_2 := high_d_2 + high;
      high_d <= high_d_1 and high_d_2;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
 	    high <= (others => '0') after (TCQ)*1 ps;
	 elsif (high_ce = '1') then
	    high <= high_d after (TCQ)*1 ps;
   	 end if;
      end if;
   end process;
  
  samples_d <= std_logic_vector(TO_UNSIGNED(1, hc_width+1)) when (clr_samples = '1') else -- samples cntr starts at 1
		samples + "1";

  process(clk)
  begin
    if (clk'event and clk='1') then
      if (reset = '1') then
        samples <= (others => '0') after TCQ*1 ps;
      elsif (samples_ce = '1') then
        samples <= samples_d after TCQ*1 ps;
      end if;
    end if;
  end process;
  
   --***************************************************************************
   -- cycle counter
   --***************************************************************************
   process (clr_cycles, cycles)
      variable cycles_d_1 : std_logic_vector((c_width-1) downto 0);
      variable cycles_d_2 : std_logic_vector((c_width-1) downto 0);
   begin
      cycles_d_1 := (others => not(clr_cycles));
      cycles_d_2(0) := '1';
      cycles_d_2((c_width-1) downto 1) := (others => '0');
      cycles_d_2 := cycles_d_2 + cycles;
      cycles_d <= cycles_d_1 and cycles_d_2;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
 	    cycles <= (others => '0') after (TCQ)*1 ps;
	 elsif (cycles_ce = '1') then
	    cycles <= cycles_d after (TCQ)*1 ps;
   	 end if;
      end if;
   end process;

  --***************************************************************************
  -- compare
  --***************************************************************************

  high_gt_low <= high(hc_width-1);

end architecture arch;

