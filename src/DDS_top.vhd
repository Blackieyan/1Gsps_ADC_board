----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:39:06 12/13/2016 
-- Design Name: 
-- Module Name:    DDS_top - Behavioral 
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

entity DDS_top is
  port(
    dds_clk : in std_logic;
    dds_sclr : in std_logic;
    dds_we : in std_logic;
    dds_phase_shift : in std_logic_vector(15 downto 0);
    dds_cos : out std_logic_vector(15 downto 0);
    dds_sin : out std_logic_vector(15 downto 0)
    );
end DDS_top;

architecture Behavioral of DDS_top is
  signal dds_reg_select : std_logic;
  signal dds_ce : std_logic;
  signal dds_rdy : std_logic;
  signal dds_rfd : std_logic;
  signal dds_phase_out : std_logic_vector(15 downto 0);
  
  component DDS1
    port (
      reg_select : in  std_logic;
      ce         : in  std_logic;
      clk        : in  std_logic;
      sclr       : in  std_logic;
      we         : in  std_logic;
      data       : in  std_logic_vector(15 downto 0);
      rdy        : out std_logic;
      rfd        : out std_logic;
      cosine     : out std_logic_vector(15 downto 0);
      sine       : out std_logic_vector(15 downto 0);
      phase_out  : out std_logic_vector(15 downto 0));
  end component;
begin
  DDS_inst : DDS1
    port map (
      reg_select => dds_reg_select,
      ce         => dds_ce,
      clk        => dds_clk,
      sclr       => dds_sclr,
      we         => dds_we,
      data       => dds_phase_shift,
      rdy        => dds_rdy,
      rfd        => dds_rfd,
      cosine     => dds_cos,
      sine       => dds_sin,
      phase_out  => dds_phase_out);

end Behavioral;

