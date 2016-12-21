----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:15:35 12/15/2016 
-- Design Name: 
-- Module Name:    multi_accum_top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;

use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use UNISIM.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity multi_accum_top is
  port(
    mult_accum_clk    : in  std_logic;
    mult_accum_ce     : in  std_logic;
    mult_accum_sclr   : in  std_logic;
    mult_accum_bypass : in  std_logic;
    -------------------------------------------------------------------------
    channel_data      : in  std_logic_vector(7 downto 0);
    dds_sin           : in  std_logic_vector(15 downto 0);
    dds_cos           : in  std_logic_vector(15 downto 0);
    -------------------------------------------------------------------------
    accm_data_x_cos        : out std_logic_vector(47 downto 0);
    accm_data_x_sin        : out std_logic_vector(47 downto 0)
    );
end multi_accum_top;

architecture Behavioral of multi_accum_top is
  
  signal mult_accum1_a : std_logic_vector(7 downto 0);
  signal mult_accum1_b : std_logic_vector(15 downto 0);
  signal mult_accum1_s : std_logic_vector(47 downto 0);
  signal mult_accum2_a : std_logic_vector(7 downto 0);
  signal mult_accum2_b : std_logic_vector(15 downto 0);
  signal mult_accum2_s : std_logic_vector(47 downto 0);
  signal accm_data_x_cos : std_logic_vector(47 downto 0);
  signal accm_data_x_sin : std_logic_vector(47 downto 0);
  
  component multi_accum
    port (
      clk    : in  std_logic;
      ce     : in  std_logic;
      sclr   : in  std_logic;
      bypass : in  std_logic;
      a      : in  std_logic_vector(7 downto 0);
      b      : in  std_logic_vector(15 downto 0);
      s      : out std_logic_vector(47 downto 0)
      );
  end component;
-------------------------------------------------------------------------------
begin

  Inst_multi_accum1 : multi_accum
    port map (
      clk    => mult_accum_clk,
      ce     => mult_accum_ce,
      sclr   => mult_accum_sclr,
      bypass => mult_accum_bypass,
      a      => mult_accum1_a,
      b      => mult_accum1_b,
      s      => mult_accum1_s
      );
  mult_accum1_a <= channel_data;
  mult_accum1_b <= dds_cos;             --Qdata.*coswt or Idata.*coswt
  accm_data_x_cos <= mult_accum1_s;

  Inst_multi_accum2 : multi_accum
    port map (
      clk    => mult_accum_clk,
      ce     => mult_accum_ce,
      sclr   => mult_accum_sclr,
      bypass => mult_accum_bypass,
      a      => mult_accum2_a,
      b      => mult_accum2_b,
      s      => mult_accum2_s
      );
  mult_accum2_a <= channel_data;
  mult_accum2_b <= dds_sin;             --Qdata.*sinwt or Idata.*sinwt
  accm_data_x_sin <= mult_accum2_s;
-------------------------------------------------------------------------------
  identify_IQdata_ps: process (mult_accum_clk, multi_accum_sclr) is
  begin  -- process identify_Qdata_ps
    if multi_accum_sclr = '1' then      -- asynchronous reset (active low)
      
    elsif mult_accum_clk'event and mult_accum_clk = '1' then  -- rising clock edge
      if ram_q_addra =  then
          Q_x_sin<=accm_data_x_sin;
          else
          Q_x_sin
        end if;
      end if;
    end if;
  end process identify_Qdata_ps;
  
end Behavioral;

