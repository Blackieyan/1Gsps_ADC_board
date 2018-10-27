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
--  /   /         Filename           : phy_oserdes_io.vhd
-- /___/   /\     Timestamp          : 
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:32 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This module
--  1. Is an OSERDES wrapper files to simply code output I/O
--Revision History:
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity phy_oserdes_io is
  generic(
   ODELAY_VAL              : integer := 0;             -- value to delay clk_wr
   REFCLK_FREQ             : real    := 300.0;         -- Ref Clk Freq. for IODELAYs
   IODELAY_GRP             : string  := "IODELAY_MIG"; -- May be assigned unique name 
                                                       -- when mult IP cores in design
   HIGH_PERFORMANCE_MODE   : boolean := TRUE;          -- IODELAY High Performance Mode  
   INIT_OQ_VAL             : bit     := '0';
   DIFF_OUT                : integer := 0              -- Use Differential Ouputs Buffer
  );
  port(
  clk          : in std_logic; 
  rst_wr_clk   : in std_logic;
  clk_mem      : in std_logic;
  data_rise0   : in std_logic; 
  data_fall0   : in std_logic; 
  data_rise1   : in std_logic;  
  data_fall1   : in std_logic;   
  data_out_p   : out std_logic;
  data_out_n   : out std_logic 
  );
end phy_oserdes_io;

architecture arch of phy_oserdes_io is
  
  attribute IODELAY_GROUP : string;
  attribute IODELAY_GROUP of u_iodelay_d : label is IODELAY_GRP;
  
  --DIFF_ATT_GEN:
  --if (DIFF_OUT /= 0) generate begin
  --  attribute IODELAY_GROUP of u_iodelay_d_n : label is IODELAY_GRP;
  --end generate;

  signal  oserdes_d_out      : std_logic;
  signal  iodelay_d_out      : std_logic;
  
  --added for n-side generation (WORK_AROUND)
  signal oserdes_d_out_n     : std_logic;
  signal iodelay_d_out_n     : std_logic;
  signal not_data_rise0      : std_logic;
  signal not_data_fall0      : std_logic;
  signal not_data_rise1      : std_logic;
  signal not_data_fall1      : std_logic;

begin

  not_data_rise0 <= not(data_rise0);
  not_data_fall0 <= not(data_fall0);
  not_data_rise1 <= not(data_rise1);
  not_data_fall1 <= not(data_fall1);

  u_oserdes_d : OSERDESE1 
  generic map(
    DATA_RATE_OQ    => "DDR",        --Output 'OQ' as DDR Format
    DATA_RATE_TQ    => "BUF",        --Output 'TQ'  Unused
    DATA_WIDTH      => 4,            --D inputs width of four
    DDR3_DATA       => 0,            --Data is not for DDR3
    INIT_OQ         => INIT_OQ_VAL,  --Initial value of OQ output
    INIT_TQ         => '1',          --Initial value of TQ output
    INTERFACE_TYPE  => "DEFAULT",    --To bypass DDR3 circuitry
    ODELAY_USED     => 0,            --Internal ODELAY unused
    SERDES_MODE     => "MASTER",     --This is the master OSERDES 
    SRVAL_OQ        => '1',          --'OQ' value on reset
    SRVAL_TQ        => '1',          --'TQ' value on reset - Unused
    TRISTATE_WIDTH  => 1             --T inputs width of four - Unused
  )
  port map( 
    OQ            => open,             --Data Output
    SHIFTOUT1     => open,             --Carry out for Data - Unused
    SHIFTOUT2     => open,     
    TQ            => open,             --Tristate outputs - Unused
    CLK           => clk_mem,          --Full Freq  Clock Input clocks D in OCB
    CLKDIV        => clk,              --Half Freq  Clock Input for clking Data
    CLKPERF       => '0',           --Full Freq  Performance Path - Clocks out
    CLKPERFDELAY  => '0',              --Output from IODELAY
    OFB           => oserdes_d_out,   --Feedback path - Unused
    D1            => data_rise0, 
    D2            => data_fall0,
    D3            => data_rise1,
    D4            => data_fall1,
    D5            => '0',              --Data inputs 5/6 - Unused
    D6            => '0',
    OCBEXTEND     => open,
    OCE           => '1',             --Enable Data input bits
    ODV           => '0',             --Set to '0' because delay doesn't 
                                      --exceed 180 degrees
    SHIFTIN1      => '0',             --Carry in for Data - Unused
    SHIFTIN2      => '0',
    RST           => rst_wr_clk,      --Reset for OSERDES
    T1            => '0',             --Tie off Tristate inputs - Unused
    T2            => '0',
    T3            => '0',
    T4            => '0',
    TFB           => open,             
    TCE           => '0',             --Disable Tristate inputs
    WC            => '0'               --Write Command to reset internal cntrs
   );
 
  u_iodelay_d : IODELAYE1 
  generic map(
    DELAY_SRC             => "O",                   --Place dealy on the Output    
    HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE, --EN for higher res > power
    IDELAY_TYPE           => "FIXED",               --Fixed "I" Delay Value
    ODELAY_TYPE           => "FIXED",               --Fixed "O" Delay Value
    IDELAY_VALUE          => 0,                     --"I" delay of 0
    ODELAY_VALUE          => ODELAY_VAL,            --"O" delay of ODELAY_VAL
    REFCLK_FREQUENCY      => REFCLK_FREQ,
    CINVCTRL_SEL          => false     
  )  
  port map( 
    DATAOUT     => iodelay_d_out,       --Delayed signal
    C           => clk,
    CE          => '0',
    DATAIN      => '0',                 --Data in from fabric only
    IDATAIN     => '0',                 --Data in from ilogic/fabric
    INC         => '0',                 --only used in variable mode
    ODATAIN     => oserdes_d_out,       --Data in from ologic/fabic
    RST         => '0',
    T           => '0',                 --Tristate select - "Output"
    CNTVALUEIN  => "00000",             --Loadable counter unused in fixed mode
    CNTVALUEOUT => open,                --Current internal counter value
    CLKIN       => '0',
    CINVCTRL    => '0'
  );


  IO_FF_GEN :
  if (DIFF_OUT = 0) generate
    begin
      IO_FF : OBUFT 
    port map(
      I => iodelay_d_out,
      O => data_out_p,
      T => '0' 
    );
    data_out_n <= '0';
  end generate;
    
  IO_FF_GEN_DS :
  if (DIFF_OUT /= 0) generate
  begin
      u_iobuf_ck : OBUFDS
      port map(
        I  => iodelay_d_out,
        O  => data_out_p,
        OB => data_out_n
      );
  end generate; 
 
end architecture arch;

