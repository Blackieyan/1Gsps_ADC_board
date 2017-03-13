----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:18:55 12/08/2016 
-- Design Name: 
-- Module Name:    CDCE62005_interface - Behavioral 
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

entity CDCE62005_interface is
  port(
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    spi_clk     : out std_logic;
    spi_mosi    : out std_logic;
    spi_miso    : in  std_logic;
    spi_le      : out std_logic;
    spi_syn     : out std_logic;
    spi_powerdn : out  std_logic;
    spi_revdata : out std_logic_vector(31 downto 0);
    cfg_finish  : out std_logic
    );

end CDCE62005_interface;

architecture Behavioral of CDCE62005_interface is

  signal clk_div_cnt  : std_logic_vector(7 downto 0);
  constant Div_multi  : std_logic_vector(3 downto 0) := "1010";
  signal div_sclk     : std_logic;
  signal div_sclk_cnt : std_logic_vector(31 downto 0);
  signal cdce62005_en : std_logic;
  signal clk_spi : std_logic;

  component CDCE62005_config
    port(
      clk         : in  std_logic;
      clk_spi     : in  std_logic;
      en          : in  std_logic;
      spi_miso    : in  std_logic;
      spi_clk     : out std_logic;
      spi_mosi    : out std_logic;
      spi_le      : out std_logic;
      spi_syn     : out std_logic;
      spi_powerdn : out std_logic;
      cfg_finish  : out std_logic;
      spi_revdata : out std_logic_vector(31 downto 0)
      );
  end component;

begin

  Inst_CDCE62005_config : CDCE62005_config port map(
    clk         => div_SCLK,
    clk_spi     => clk_spi,
    en          => cdce62005_en,
    spi_clk     => spi_clk,
    spi_mosi    => spi_mosi,
    spi_miso    => spi_miso,
    spi_le      => spi_le,
    spi_syn     => spi_syn,
    spi_powerdn => spi_powerdn,
    cfg_finish  => cfg_finish,
    spi_revdata => spi_revdata
    );
  clk_spi <= not div_SCLK;

  set_clk_div_cnt : process (CLK, rst_n) is  --usb data
  begin  -- process set_clk_div_cnt
    if rst_n = '0' then                      -- asynchronous reset (active
      clk_div_cnt <= x"00";
    elsif CLK'event and CLK = '1' then       -- rising clock edge
      if clk_div_cnt <= Div_multi then
        clk_div_cnt <= clk_div_cnt+1;
      else
        clk_div_cnt <= x"00";
      end if;
    end if;
  end process set_clk_div_cnt;

  set_div_sclk : process (CLK, rst_n) is
  begin  -- process set_ADC_sclk
    if rst_n = '0' then                 -- asynchronous reset (active low)
      div_SCLK <= '0';
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      if clk_div_cnt <= Div_multi(3 downto 1) then
        div_SCLK <= '0';
      else
        div_SCLK <= '1';
      end if;
    end if;
  end process set_div_sclk;

  div_SCLK_cnt_ps : process (div_SCLK) is
  begin  -- process set_Gcnt    
    if div_SCLK'event and div_SCLK = '1' then
      if div_SCLK_cnt <= x"11111111" then
        div_SCLK_cnt <= div_SCLK_cnt+1;
      else
        div_SCLK_cnt <= div_SCLK_cnt;
      end if;
    end if;
  end process div_SCLK_cnt_ps;

  set_cdce62005_en : process (CLK, rst_n) is
  begin  -- process cdce62005_en
    if rst_n = '0' then
        cdce62005_en <= '0';
  elsif CLK'event and CLK = '1' then
      if div_SCLK_cnt >= x"00000000" and div_SCLK_cnt <= x"00000050" then
        cdce62005_en <= '0';
      else
        cdce62005_en <= '1';
      end if;
    end if;
  end process set_cdce62005_en;

end Behavioral;


