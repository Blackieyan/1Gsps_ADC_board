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
--  /   /         Filename           : phy_read_data_align.v
-- /___/   /\     Timestamp          : Nov 17, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:32 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--  This module
--  1. Realigns the incoming data based on the phase signal from the delay /
--     alignment calibration. If phase = 0, no realignment occurs and data
--     exits in the same manner that it is delivered from the ISERDES. If
--     phase = 1, the data is realigned to correct for the CLK/CLKB
--     relationship relative to CLKDIV in the ISERDES. Specifically it delays
--     iserdes data 1 and swaps position with iserdes data 0.
--
--Revision History:
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity phy_read_data_align is
  generic(
    MEMORY_WIDTH  : integer   := 36;   -- Width of each memory
    TCQ           : integer   := 100
  );
  port(
    -- System Signals
    clk_rd      : in std_logic;   -- half freq CQ clock
    rst_clk_rd  : in std_logic;   -- reset syncrhonized to clk_rd
    
    -- ISERDES Interface
    iserdes_rd0 : in std_logic_vector (MEMORY_WIDTH-1 downto 0); -- rising data 
                                                                 -- 0 from ISERDES
    iserdes_fd0 : in std_logic_vector (MEMORY_WIDTH-1 downto 0); -- falling data 
                                                                 -- 0 from ISERDES    
    iserdes_rd1 : in std_logic_vector (MEMORY_WIDTH-1 downto 0); -- rising data 
                                                                 -- 1 from ISERDES
    iserdes_fd1 : in std_logic_vector (MEMORY_WIDTH-1 downto 0); -- falling data 
                                                                 -- 1 from ISERDES
    
    -- DCB Interface
    rise_data0 : out std_logic_vector (MEMORY_WIDTH-1 downto 0); -- rising data 
                                                                 -- 0 to DCB
    fall_data0 : out std_logic_vector (MEMORY_WIDTH-1 downto 0); -- falling data 
                                                                 -- 0 to DCB
    rise_data1 : out std_logic_vector (MEMORY_WIDTH-1 downto 0); -- rising data 
                                                                 -- 1 to DCB 
    fall_data1 : out std_logic_vector (MEMORY_WIDTH-1 downto 0); -- falling data 
                                                                 -- 1 to DCB
  
    -- Delay/Alignment Calibration Interface
    phase      : in std_logic;    -- realigns when asserted
    
    -- ChipScope Debug Signals
    dbg_phase  : out std_logic    --phase_indicator
  );
end entity phy_read_data_align;

architecture arch of phy_read_data_align is
  
  -- Signal Declarations
  signal iserdes_rd1_r : std_logic_vector(MEMORY_WIDTH-1 downto 0);
  signal iserdes_fd1_r : std_logic_vector(MEMORY_WIDTH-1 downto 0);

begin

  dbg_phase <= phase;
  
  -- Delay rising and falling data 1 from ISERDES in case the data needs
  -- to be realigned
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        iserdes_rd1_r <= (others => '0') after TCQ*1 ps;
        iserdes_fd1_r <= (others => '0') after TCQ*1 ps;
      else
        iserdes_rd1_r <= iserdes_rd1 after TCQ*1 ps;
        iserdes_fd1_r <= iserdes_fd1 after TCQ*1 ps;
      end if;
    end if;
  end process;
    
  -- Realign when phase is asserted. Rise and fall data 0 output is derived from
  -- the registered rise and fall data 1 (from above) from the ISERDES. Rise and
  -- fall data 1 output comes from the ISERDES rise and fall data 0.
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        rise_data0 <= (others => '0') after TCQ*1 ps;
        fall_data0 <= (others => '0') after TCQ*1 ps;
        rise_data1 <= (others => '0') after TCQ*1 ps;
        fall_data1 <= (others => '0') after TCQ*1 ps;
      else
      if (phase = '1') then
        rise_data0 <= iserdes_rd1_r after TCQ*1 ps;
        fall_data0 <= iserdes_fd1_r after TCQ*1 ps;
        rise_data1 <= iserdes_rd0 after TCQ*1 ps;
        fall_data1 <= iserdes_fd0 after TCQ*1 ps;
      else
        rise_data0 <= iserdes_rd0 after TCQ*1 ps;
        fall_data0 <= iserdes_fd0 after TCQ*1 ps;
        rise_data1 <= iserdes_rd1 after TCQ*1 ps;
        fall_data1 <= iserdes_fd1 after TCQ*1 ps;
      end if;
     end if;
    end if;
  end process;
  
end architecture arch;
