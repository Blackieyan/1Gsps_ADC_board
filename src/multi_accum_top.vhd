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
  generic (
    mult_accum_s_width : integer := 32
   );
  port(
    mult_accum_clk    : in  std_logic;
    mult_accum_ce     : in  std_logic;
    mult_accum_sclr   : in  std_logic;
    mult_accum_bypass : in  std_logic;
    -------------------------------------------------------------------------
    Q_data      : in  std_logic_vector(7 downto 0);
    I_data      : in  std_logic_vector(7 downto 0);
    dds_sin           : in  std_logic_vector(7 downto 0);
    dds_cos           : in  std_logic_vector(7 downto 0);
    -------------------------------------------------------------------------
    accm_I_x_cos   : out std_logic_vector(mult_accum_s_width-1 downto 0);
    accm_I_x_sin   : out std_logic_vector(mult_accum_s_width-1 downto 0);
    accm_Q_x_cos   : out std_logic_vector(mult_accum_s_width-1 downto 0);
    accm_Q_x_sin   : out std_logic_vector(mult_accum_s_width-1 downto 0)
    );
end multi_accum_top;

architecture Behavioral of multi_accum_top is

  signal mult_accum0_a   : std_logic_vector(7 downto 0);
  signal mult_accum0_b   : std_logic_vector(7 downto 0);
  signal mult_accum0_s   : std_logic_vector(mult_accum_s_width-1 downto 0);
  signal mult_accum1_a   : std_logic_vector(7 downto 0);
  signal mult_accum1_b   : std_logic_vector(7 downto 0);
  signal mult_accum1_s   : std_logic_vector(mult_accum_s_width-1 downto 0);
  signal mult_accum2_a   : std_logic_vector(7 downto 0);
  signal mult_accum2_b   : std_logic_vector(7 downto 0);
  signal mult_accum2_s   : std_logic_vector(mult_accum_s_width-1 downto 0);
  signal mult_accum3_a   : std_logic_vector(7 downto 0);
  signal mult_accum3_b   : std_logic_vector(7 downto 0);
  signal mult_accum3_s   : std_logic_vector(mult_accum_s_width-1 downto 0);

  -- signal accm_Q_x_cos : std_logic_vector(17 downto 0);
  -- signal accm_Q_x_sin : std_logic_vector(17 downto 0);
  -- signal accm_I_x_cos : std_logic_vector(17 downto 0);
  -- signal accm_I_x_sin : std_logic_vector(17 downto 0);


COMPONENT multi_accum
  PORT (
    clk : IN STD_LOGIC;
    ce : IN STD_LOGIC;
    sclr : IN STD_LOGIC;
    bypass : IN STD_LOGIC;
    a : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    b : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s : OUT STD_LOGIC_VECTOR(mult_accum_s_width-1 DOWNTO 0)
  );
END COMPONENT;
-------------------------------------------------------------------------------
begin

 Inst_multi_accum0 : multi_accum
    port map (
      clk    => mult_accum_clk,
      ce     => mult_accum_ce,
      sclr   => mult_accum_sclr,
      bypass => mult_accum_bypass,
      a      => mult_accum0_a,
      b      => mult_accum0_b,
      s      => mult_accum0_s
      );
  mult_accum0_a   <= Q_data;
  mult_accum0_b   <= dds_cos;           --Qdata.*coswt 
  accm_Q_x_cos <= mult_accum0_s;

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
  mult_accum1_a   <= Q_data;
  mult_accum1_b   <= dds_sin;           --Qdata.*sinwt 
  accm_Q_x_sin <= mult_accum1_s;

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
  mult_accum2_a   <= I_data;
  mult_accum2_b   <= dds_cos;           --Idata.*coswt 
  accm_I_x_cos <= mult_accum2_s;

  Inst_multi_accum3 : multi_accum
    port map (
      clk    => mult_accum_clk,
      ce     => mult_accum_ce,
      sclr   => mult_accum_sclr,
      bypass => mult_accum_bypass,
      a      => mult_accum3_a,
      b      => mult_accum3_b,
      s      => mult_accum3_s
      );
  mult_accum3_a   <= I_data;
  mult_accum3_b   <= dds_sin;           --Idata.*sinwt 
  accm_I_x_sin <= mult_accum3_s;

-------------------------------------------------------------------------------


end Behavioral;

