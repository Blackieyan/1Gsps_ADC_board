----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:12:21 03/09/2016 
-- Design Name: 
-- Module Name:    GMII_to_RGMII - Behavioral 
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

entity GMII_to_RGMII is
  port (
    GMII_TX_CLK_i : in  std_logic;
    GMII_TX_TXD_i : in  std_logic_vector(7 downto 0);
    GMII_TX_EN_i  : in  std_logic;
    GMII_TX_ER_i  : in  std_logic;
    PHY_GTXCLK_o  : out std_logic;
    PHY_TXD_o     : out std_logic_vector(3 downto 0);
    PHY_TXEN_o    : out std_logic
    );

end GMII_to_RGMII;

architecture Behavioral of GMII_to_RGMII is
signal phy_txen_o_d1 : std_logic;
begin
  phy_txen_o_d1<=GMII_TX_EN_i xor GMII_TX_ER_i;
  -----------------------------------------------------------------------------
  ODDR_inst1 : ODDR
    generic map(
      DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT         => '0',  -- Initial value for Q port ('1' or '0')
      SRTYPE       => "SYNC")           -- Reset Type ("ASYNC" or "SYNC")
    port map (
      Q  => PHY_GTXCLK_o,               -- 1-bit DDR output
      C  => GMII_TX_CLK_i,              -- 1-bit clock input
      CE => '1',                        -- 1-bit clock enable input
      D1 => '0',                        -- 1-bit data input (positive edge)
      D2 => '1',                        -- 1-bit data input (negative edge)
      R  => '0',                        -- 1-bit reset input
      S  => '0'                         -- 1-bit set input
      );
-------------------------------------------------------------------------------
  ODDR_inst2 : ODDR
    generic map(
      DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT         => '0',  -- Initial value for Q port ('1' or '0')
      SRTYPE       => "SYNC")           -- Reset Type ("ASYNC" or "SYNC")
    port map (
      Q  => PHY_TXEN_o,                 -- 1-bit DDR output
      C  => GMII_TX_CLK_i,              -- 1-bit clock input
      CE => '1',                        -- 1-bit clock enable input
      D1 => phy_txen_o_d1,  -- 1-bit data input (positive edge)
      D2 => GMII_TX_EN_i,               -- 1-bit data input (negative edge)
      R  => '0',                        -- 1-bit reset input
      S  => '0'                         -- 1-bit set input
      );

  gen_i: for i in 0 to 3 generate
  begin  
  
  ODDR_inst3 : ODDR
    generic map(
      DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT         => '0',  -- Initial value for Q port ('1' or '0')
      SRTYPE       => "SYNC")           -- Reset Type ("ASYNC" or "SYNC")
    port map (
      Q  => PHY_TXD_o(i),                          -- 1-bit DDR output
      C  => GMII_TX_CLK_i,                          -- 1-bit clock input
      CE => '1',                         -- 1-bit clock enable input
      D1 => GMII_TX_TXD_i(i+4),                         -- 1-bit data input (positive edge)
      D2 => GMII_TX_TXD_i(i),                         -- 1-bit data input (negative edge)
      R  => '0',                          -- 1-bit reset input
      S  => '0'                           -- 1-bit set input
      );
  end generate gen_i;
  -----------------------------------------------------------------------------
end Behavioral;

