--*****************************************************************************
--(c) Copyright 2006 - 2009 Xilinx, Inc. All rights reserved.
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
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version:3.9
--  \   \         Application: MIG
--  /   /         Filename: iodelay_ctrl.vhd
-- /___/   /\     Date Last Modified: $date$
-- \   \  /  \    Date Created: Nov 19, 2008
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: QDRII+ /RLDRAM-II
--Purpose:
--   This module instantiates the IDELAYCTRL primitive of the Virtex-5 device
--   which continously calibrates the IODELAY elements in the region in case of
--   varying operating conditions. It takes a 200MHz clock as an input
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;

entity iodelay_ctrl is
  generic(
    constant IODELAY_GRP    : string := "IODELAY_MIG";  -- May be assigned unique name when
                                              -- multiple IP cores used in design
    constant INPUT_CLK_TYPE : string := "DIFFERENTIAL"; -- input clock type
                                              -- "DIFFERENTIAL","SINGLE_ENDED"
    constant RST_ACT_LOW    : integer := 1;              --sys reset is active low
    constant TCQ            : integer := 100
    );
  port(
    sys_rst          : in  std_logic;
    clk_ref_p        : in  std_logic;
    clk_ref_n        : in  std_logic;
    clk_ref          : in  std_logic;
    iodelay_ctrl_rdy : out std_logic
    );
end entity iodelay_ctrl;

architecture arch_iodelay_ctrl of iodelay_ctrl is

  constant RST_SYNC_NUM : integer := 5;

  --signal Declarations
  signal clk_ref_ibufg     : std_logic;
  signal clk_ref_bufg      : std_logic;
  signal rst_clkref_tmp    : std_logic;
  signal rst_clkref        : std_logic;
  signal sys_rst_act_hi    : std_logic;
  signal rst_clkref_sync_r : std_logic_vector(RST_SYNC_NUM-1 downto 0) := (others => '1');

  attribute IODELAY_GROUP : string;
  attribute shreg_extract : string;
  attribute shreg_extract of rst_clkref : signal is "no";
  attribute IODELAY_GROUP of u_idelayctrl : label is IODELAY_GRP;

begin

  sys_rst_act_hi <= (not sys_rst) when (RST_ACT_LOW = 1) else sys_rst;
  rst_clkref_tmp <= sys_rst_act_hi;

  DIFF_ENDED_CLKS_INST : if(INPUT_CLK_TYPE = "DIFFERENTIAL") generate
    --**************************************************************************
    -- Differential input clock input buffers
    --**************************************************************************
    IDLY_CLK_INST : IBUFGDS
      port map(
        I  => clk_ref_p,
        IB => clk_ref_n,
        O  => clk_ref_ibufg
        );
  end generate DIFF_ENDED_CLKS_INST;

  SINGLE_ENDED_CLKS_INST : if(INPUT_CLK_TYPE = "SINGLE_ENDED") generate
    --**************************************************************************
    -- Single ended input clock input buffers
    --**************************************************************************
--    IDLY_CLK_INST : IBUFG
--      port map(
--        I => clk_ref,
--        O => clk_ref_ibufg
--        );
	clk_ref_bufg <= clk_ref;
  end generate SINGLE_ENDED_CLKS_INST;

  --***************************************************************************
  -- IDELAYCTRL reference clock
  --***************************************************************************

--  u_bufg_clk_ref : BUFG
--    port map(
--      I => clk_ref_ibufg,
--      O => clk_ref_bufg
--      );

  u_idelayctrl : IDELAYCTRL
    port map(
      RDY    => iodelay_ctrl_rdy,
      REFCLK => clk_ref_bufg,
      RST    => rst_clkref
      );

  -- make sure CLK200 doesn't depend on IODELAY_CTRL_RDY, else chicken n' egg
  process(clk_ref_bufg, rst_clkref_tmp)
  begin
    if(rst_clkref_tmp = '1') then
      rst_clkref_sync_r <= (others => '1') after TCQ*1 ps;
    elsif(rising_edge(clk_ref_bufg)) then
      rst_clkref_sync_r <= (rst_clkref_sync_r(RST_SYNC_NUM-2 downto 0) & '0') after TCQ*1 ps;
    end if;
  end process;

  rst_clkref <= rst_clkref_sync_r(RST_SYNC_NUM-1);

end architecture arch_iodelay_ctrl;
