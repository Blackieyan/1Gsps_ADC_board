----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:40:03 12/09/2016 
-- Design Name: 
-- Module Name:    post_process - Behavioral 
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

entity post_process is
  port(
    clk             : in std_logic;
    Q_data          : in std_logic_vector(63 downto 0);
    I_data          : in std_logic_vector(63 downto 0);
    DDS_phase_shift : in std_logic_vector(15 downto 0);
    rst_n           : in std_logic
    );
end post_process;

architecture Behavioral of post_process is

  type array_data_x_cos is array (7 downto 0) of std_logic_vector(17 downto 0);
  -- type array_Q_x_cos is array (7 downto 0) of std_logic_vector(17 downto 0);
  -- type array_I_x_sin is array (7 downto 0) of std_logic_vector(17 downto 0);
  -- type array_Q_x_sin is array (7 downto 0) of std_logic_vector(17 downto 0);
  signal accm_Q_x_cos : array_data_x_cos;
  signal accm_I_x_cos : array_data_x_cos; 
  signal accm_Q_x_sin : array_data_x_cos;
  signal accm_I_x_sin : array_data_x_cos;

  signal IxCOS : std_logic_vector(19 downto 0);
  signal IxSIN : std_logic_vector(19 downto 0);
  signal QxCOS : std_logic_vector(19 downto 0);
  signal QxSIN : std_logic_vector(19 downto 0);

  signal dds_sclr : std_logic;
  signal dds_we   : std_logic;
  signal dds_cos  : std_logic_vector(7 downto 0);
  signal dds_sin  : std_logic_vector(7 downto 0);

  signal mult_accum_clk    : std_logic;
  signal mult_accum_ce     : std_logic;
  signal mult_accum_sclr   : std_logic;
  signal mult_accum_bypass : std_logic;
  -- signal accm_I_x_cos : std_logic_vector(17 downto 0);
  -- signal accm_Q_x_cos : std_logic_vector(17 downto 0);
  -- signal accm_I_x_sin : std_logic_vector(17 downto 0);
  -- signal accm_Q_x_sin : std_logic_vector(17 downto 0);
-------------------------------------------------------------------------------
  component DDS_top
    port(
      dds_clk         : in  std_logic;
      dds_sclr        : in  std_logic;
      dds_we          : in  std_logic;
      dds_phase_shift : in  std_logic_vector(15 downto 0);
      dds_cos         : out std_logic_vector(7 downto 0);
      dds_sin         : out std_logic_vector(7 downto 0)
      );
  end component;

  component multi_accum_top
    port(
      mult_accum_clk    : in  std_logic;
      mult_accum_ce     : in  std_logic;
      mult_accum_sclr   : in  std_logic;
      mult_accum_bypass : in  std_logic;
      Q_data            : in  std_logic_vector(7 downto 0);
      I_data            : in  std_logic_vector(7 downto 0);
      dds_sin           : in  std_logic_vector(7 downto 0);
      dds_cos           : in  std_logic_vector(7 downto 0);
      accm_I_x_cos      : out std_logic_vector(17 downto 0);
      accm_I_x_sin      : out std_logic_vector(17 downto 0);
      accm_Q_x_cos      : out std_logic_vector(17 downto 0);
      accm_Q_x_sin      : out std_logic_vector(17 downto 0)
      );
  end component;

-------------------------------------------------------------------------------
begin
  Inst_DDS : DDS_top port map(
    dds_clk         => clk,
    dds_sclr        => dds_sclr,
    dds_we          => dds_we,
    dds_phase_shift => dds_phase_shift,
    dds_cos         => dds_cos,
    dds_sin         => dds_sin
    );

  multi_accum_inst : for i in 0 to 7 generate
  begin
    Inst_multi_accum_top : multi_accum_top port map(
      mult_accum_clk    => mult_accum_clk,
      mult_accum_ce     => mult_accum_ce,
      mult_accum_sclr   => mult_accum_sclr,
      mult_accum_bypass => mult_accum_bypass,
      Q_data            => Q_data(8*i+7 downto 8*i),
      I_data            => I_data(8*i+7 downto 8*i),
      dds_sin           => dds_sin,
      dds_cos           => dds_cos,
      accm_Q_x_cos      => accm_Q_x_cos(i),
      accm_I_x_sin      => accm_I_x_sin(i),
      accm_I_x_cos      => accm_I_x_cos(i),
      accm_Q_x_sin      => accm_Q_x_sin(i)
      );
  end generate multi_accum_inst;

end Behavioral;

