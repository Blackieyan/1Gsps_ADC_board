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
-- \   \   \/     Version            : 3.9
--  \   \         Application        : MIG
--  /   /         Filename           : qdr_rld_infrastructure.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 07:18:33 $  
-- \   \  /  \    Date Created       : November 19, 2008             
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--Purpose:
--   Clock generation/distribution and reset synchronization
--Revision History:
--
--/////////////////////////////////////////////////////////////////////////////

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity qdr_rld_infrastructure is
  generic(
    -- Active Low Reset
    RST_ACT_LOW          : integer := 1;             
    -- Internal fabric Clk Period (in ps)
    CLK_PERIOD           : integer := 3752;  
    -- MMCM programming algorithm
    MMCM_ADV_BANDWIDTH : string  := "OPTIMIZED";
    -- write PLL VCO multiplier
    CLKFBOUT_MULT_F      : real    := 2.0;     
    -- VCO output divisor for fast (memory) clocks
    CLKOUT_DIVIDE        : integer := 2;     
    -- write PLL VCO divisor
    DIVCLK_DIVIDE        : integer := 1;     
    -- No. of Connected Memories
    NUM_DEVICES          : integer := 2
  );
  port(
    mmcm_clk     : in std_logic;       
    sys_rst      : in std_logic;        -- system reset
    clk0         : out std_logic;       -- full frequency system clock
    clkdiv0      : out std_logic;       -- half frequency system clock
    clk_wr       : out std_logic;
    mmcm_locked  : out std_logic        -- mmcm is locked
);

end qdr_rld_infrastructure;

architecture arch of qdr_rld_infrastructure is

  signal sys_rst_act_hi : std_logic;
  signal clk0_bufg      : std_logic;
  signal clk0_mmcm      : std_logic;
  signal clkdiv0_bufg   : std_logic;
  signal clkdiv0_mmcm   : std_logic;
  signal clkfbout_mmcm  : std_logic;

  -- Clk period in nanosecond used for mmcm clock generation
  -- divide clk_period by 2 to get the external memory frequency
  constant CLK_PERIOD_NS      : real    := real (CLK_PERIOD) /
                                                 real (2*1000);

  constant CLKOUT0_DIVIDE_F : real    := real(CLKOUT_DIVIDE);
  -- output div for fabric clk 
  constant CLKOUT1_DIVIDE   : integer := CLKOUT_DIVIDE * 2; 
  constant CLKOUT2_DIVIDE   : integer := CLKOUT_DIVIDE;
  constant CLKOUT3_DIVIDE   : integer := CLKOUT_DIVIDE;

  constant VCO_PERIOD       : integer := integer((real(DIVCLK_DIVIDE) * real(CLK_PERIOD)/(CLKFBOUT_MULT_F * 2.0)));
  
  --***************************************************************************
  -- Assign global clocks:
  --   1. CLK200  : IDELAYCTRL reference
  --   2. CLK0    : Full rate (used only for IOB) 
  --   3. CLKDIV0 : Half rate (used for majority of internal logic)
  --***************************************************************************

begin

  clk0            <= clk0_bufg;
  clkdiv0         <= clkdiv0_bufg;
  sys_rst_act_hi  <= sys_rst when RST_ACT_LOW = 0 else not(sys_rst);

  --***************************************************************************
  -- Global base clock generation and distribution  
  --***************************************************************************

  --*****************************************************************
  -- VCCO freq = M * (input clock) = [400MHz, 1000MHz] ([400,1200] for -3)
  -- Expect input frequency to be in range [300MHz, 550MHz], choose M = 2
  -- such that VCCO frequency = [600MHz, 1.1MHz]
  --*****************************************************************

  u_mmcm_gen : MMCM_ADV 
  generic map(
    BANDWIDTH               => MMCM_ADV_BANDWIDTH,
    CLOCK_HOLD              => false,
    STARTUP_WAIT            => false,
    COMPENSATION            => "INTERNAL",
    REF_JITTER1             => 0.005,
    REF_JITTER2             => 0.005,
    CLKOUT0_DIVIDE_F        => CLKOUT0_DIVIDE_F,
    CLKOUT1_DIVIDE          => CLKOUT1_DIVIDE,
    CLKOUT2_DIVIDE          => CLKOUT2_DIVIDE,
    CLKOUT3_DIVIDE          => CLKOUT3_DIVIDE,
    CLKOUT4_DIVIDE          => 1,
    CLKOUT5_DIVIDE          => 1,
    CLKOUT6_DIVIDE          => 1,
    DIVCLK_DIVIDE           => DIVCLK_DIVIDE,
    CLKFBOUT_MULT_F         => CLKFBOUT_MULT_F,
    CLKFBOUT_PHASE          => 0.000,
    CLKIN1_PERIOD           => CLK_PERIOD_NS,
    CLKIN2_PERIOD           => 10.000,
    CLKOUT0_DUTY_CYCLE      => 0.500,
    CLKOUT0_PHASE           => 0.000,
    CLKOUT1_DUTY_CYCLE      => 0.500,
    CLKOUT1_PHASE           => 0.000,
    CLKOUT2_DUTY_CYCLE      => 0.500,
    CLKOUT2_PHASE           => 0.000,
    CLKOUT3_DUTY_CYCLE      => 0.500,
    CLKOUT3_PHASE           => 0.000,
    CLKOUT4_DUTY_CYCLE      => 0.500,
    CLKOUT4_PHASE           => 0.000,
    CLKOUT5_DUTY_CYCLE      => 0.500,
    CLKOUT5_PHASE           => 0.000,
    CLKOUT6_DUTY_CYCLE      => 0.500,
    CLKOUT6_PHASE           => 0.000,
    CLKOUT0_USE_FINE_PS     => TRUE,
    CLKOUT1_USE_FINE_PS     => TRUE,
    CLKOUT2_USE_FINE_PS     => TRUE,
    CLKOUT3_USE_FINE_PS     => false,
    CLKOUT4_USE_FINE_PS     => false,
    CLKOUT5_USE_FINE_PS     => false,
    CLKOUT6_USE_FINE_PS     => false
      ) 
  port map( 
    CLKFBOUT          => clkfbout_mmcm,
    CLKFBOUTB         => open,
    CLKFBSTOPPED      => open,
    CLKINSTOPPED      => open,
    CLKOUT0           => clk0_mmcm,
    CLKOUT0B          => open,
    CLKOUT1           => clkdiv0_mmcm,
    CLKOUT1B          => open,
    CLKOUT2           => clk_wr,
    CLKOUT2B          => open,
    CLKOUT3           => open,
    CLKOUT3B          => open,
    CLKOUT4           => open,
    CLKOUT5           => open,
    CLKOUT6           => open,
    DO                => open,
    DRDY              => open,
    LOCKED            => mmcm_locked,
    PSDONE            => open,
    CLKFBIN           => clkfbout_mmcm,
    CLKIN1            => mmcm_clk,
    CLKIN2            => '0',
    CLKINSEL          => '1',
    DADDR             => "0000000",
    DCLK              => '0',
    DEN               => '0',
    DI                => x"0000",
    DWE               => '0',
    PSCLK             => '0',
    PSEN              => '0',
    PSINCDEC          => '0',
    PWRDWN            => '0',
    RST               => sys_rst_act_hi
  );

  u_bufg_clk0 : BUFG 
  port map(
   O => clk0_bufg,
   I => clk0_mmcm
   );

  u_bufg_clkdiv0 : BUFG 
  port map(
   O => clkdiv0_bufg,
   I => clkdiv0_mmcm
   );

    
end architecture arch;

