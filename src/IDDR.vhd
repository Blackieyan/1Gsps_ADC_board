----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:47:05 01/06/2016 
-- Design Name: 
-- Module Name:    IDDR - Behavioral 
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
use UNISIM.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity IDDR_inst is
  generic(
    ddr_num : integer := 8
    );

  port(
    CLK : in  std_logic;
    Q1  : out std_logic_vector(ddr_num-1 downto 0);
    Q2  : out std_logic_vector(ddr_num-1 downto 0);
    D   : in  std_logic_vector(ddr_num-1 downto 0)
    );
end IDDR_inst;

architecture Behavioral of IDDR_inst is
  signal ce : std_logic;
  signal R  : std_logic;
  signal S  : std_logic;

begin
  R  <= '0';
  S  <='0';
  CE <= '1';
  gen_ddr : for i in 0 to 7 generate
    begin
    IDDR_inst : IDDR
      generic map (
        DDR_CLK_EDGE => "SAME_EDGE_PIPELINED",  -- "OPPOSITE_EDGE", "SAME_EDGE" 
        -- or "SAME_EDGE_PIPELINED" 
        INIT_Q1      => '0',            -- Initial value of Q1: '0' or '1'
        INIT_Q2      => '0',            -- Initial value of Q2: '0' or '1'
        SRTYPE       => "ASYNC")        -- Set/Reset type: "SYNC" or "ASYNC" 
      port map (
        Q1 => Q1(i),              -- 1-bit output for positive edge of clock 
        Q2 => Q2(i),              -- 1-bit output for negative edge of clock
        C  => CLK,                      -- 1-bit clock input
        CE => CE,                       -- 1-bit clock enable input
        D  => D(i),                     -- 1-bit DDR data input
        R  => R,                        -- 1-bit reset
        S  => S                         -- 1-bit set
        );

  end generate;
  end Behavioral;

