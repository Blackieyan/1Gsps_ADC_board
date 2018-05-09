----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:31:56 04/13/2017 
-- Design Name: 
-- Module Name:    Pstprc_fifo - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Pstprc_fifo_top is
  port(
    rst_n : IN STD_LOGIC;
    Pstprc_fifo_wr_clk : IN STD_LOGIC;
    Pstprc_fifo_rd_clk : IN STD_LOGIC;
    Pstprc_fifo_din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    Pstprc_fifo_wren : IN STD_LOGIC;
    Pstprc_fifo_rden : IN STD_LOGIC;
    -- prog_empty_thresh : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    Pstprc_fifo_dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    Pstprc_fifo_valid : OUT STD_LOGIC;
    Pstprc_fifo_pempty : OUT STD_LOGIC;
    pstprc_fifo_alempty : out STD_LOGIC
);
end Pstprc_fifo_top;

architecture Behavioral of Pstprc_fifo_top is
  
  signal full : std_logic;
  signal empty : std_logic;
  signal dout : std_logic_vector(7 downto 0);
  signal empty_rst : std_logic;
  signal empty_d : std_logic;
  signal empty_d2 : std_logic;
  
COMPONENT Pstprc_Fifo

  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    -- prog_empty_thresh : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    almost_empty : OUT STD_LOGIC;
    prog_empty : OUT STD_LOGIC
  );
END COMPONENT;

begin
  Pstprc_Fifo_inst : Pstprc_Fifo
  PORT MAP (
    rst => (not rst_n) or empty_rst,
    wr_clk => Pstprc_fifo_wr_clk,
    rd_clk => Pstprc_fifo_rd_clk,
    din => Pstprc_fifo_din,
    wr_en =>Pstprc_fifo_wren,
    rd_en =>Pstprc_fifo_rden,
    -- prog_empty_thresh => prog_empty_thresh,
    dout => dout,
    full => full,
    empty => empty,
    valid => Pstprc_fifo_valid,
    prog_empty => pstprc_fifo_pempty,
    almost_empty => pstprc_fifo_alempty
  );

  Pstprc_fifo_dout_ps: process (Pstprc_fifo_rd_clk, rst_n) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
        Pstprc_fifo_dout<=(others => '0');
    elsif Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      Pstprc_fifo_dout<= dout;
    end if;
  end process Pstprc_fifo_dout_ps;

  empty_d_ps: process (Pstprc_fifo_rd_clk, rst_n) is
  begin  -- process empty_rst_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      empty_d<=empty;
      empty_d2<=empty_d;
    end if;
  end process empty_d_ps;

  empty_rst_ps: process (Pstprc_fifo_rd_clk, rst_n) is
  begin  -- process empty_rst_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      empty_rst<='0';
    elsif Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      if empty_d='1' and empty_d2 ='0' then
        empty_rst<='1';
      else
        empty_rst<='0';
      end if;
    end if;
  end process empty_rst_ps;
end Behavioral;

