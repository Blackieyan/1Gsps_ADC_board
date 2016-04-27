----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:37:33 04/19/2016 
-- Design Name: 
-- Module Name:    command_analysis - Behavioral 
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

entity command_analysis is
  port(
    rd_data         : in  std_logic_vector(7 downto 0);
    rd_clk          : in  std_logic;
    rd_addr         : in  std_logic_vector(13 downto 0);
    rd_en           : in  std_logic;
    frm_length      : out std_logic_vector(15 downto 0);
    frm_type        : out std_logic_vector(15 downto 0);
    -- mac_dst    : out std_logic_vector(47 downto 0);
    -- mac_src    : out std_logic_vector(47 downto 0);
    -- reg_addr   : out std_logic_vector(15 downto 0);
    -- reg_data   : out std_logic_vector(31 downto 0);
    ram_start   : buffer std_logic;
    user_pushbutton : in  std_logic
    );
end command_analysis;

architecture Behavioral of command_analysis is
  signal mac_dst  : std_logic_vector(47 downto 0);
  signal mac_src  : std_logic_vector(47 downto 0);  -- 为了反馈地址预留的信号
  signal reg_addr : std_logic_vector(15 downto 0);
  signal reg_data : std_logic_vector(31 downto 0);
  signal rst_n    : std_logic;
  signal reg_clr_cnt : std_logic_vector(7 downto 0);
  signal rd_en_d : std_logic;
  -- signal reg_clr_cnt : std_logic_vector(7 downto 0);
begin
  rst_n <= user_pushbutton;

  rd_en_d_ps: process (rd_clk, rst_n) is
  begin  -- process rd_en_d
    if rd_clk'event and rd_clk = '1' then  -- rising clock edge
      rd_en_d<=rd_en;
    end if;
  end process rd_en_d_ps;
  
  frm_length_ps : process (rd_clk, rst_n) is
  begin  -- process frm_length_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      frm_length <= (others => '0');
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if rd_addr = x"01" then
        frm_length(15 downto 8) <= rd_data;
      elsif rd_addr = x"02" then
        frm_length(7 downto 0) <= rd_data;
      -- else
      --   frm_length <= frm_length;
      end if;
    end if;
  end process frm_length_ps;

  reg_addr_ps : process (rd_clk, rst_n) is
  begin  -- process reg_addr_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      reg_addr <= (others => '0');
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if rd_addr = x"11" then
        reg_addr(15 downto 8) <= rd_data;
      elsif rd_addr = x"12" then
        reg_addr(7 downto 0) <= rd_data;
      elsif rd_addr=x"18" or (rd_en_d = '1' and rd_en = '0')then  --地址为0x18或者rden信号下降,因为rddata有可能全读有可能只读0x11-0x17
        reg_addr<=(others => '0');
      end if;
    end if;
  end process reg_addr_ps;

  reg_data_ps : process (rd_clk, rst_n, rd_en_d, rd_en) is
  begin  -- process reg_data_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      reg_data <= (others => '0');
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if rd_addr = x"13" then
        reg_data(31 downto 24) <= rd_data;
      elsif rd_addr = x"14" then
        reg_data(23 downto 16) <= rd_data;
      elsif rd_addr = x"15" then
        reg_data(15 downto 8) <= rd_data;
      elsif rd_addr = x"16" then
        reg_data(7 downto 0) <= rd_data;
      elsif rd_addr=x"18" or (rd_en_d = '1' and rd_en = '0')then  --地址为0x18或者rden信号下降,因为rddata有可能全读有可能只读0x11-0x17
        reg_data<=(others => '0');
      end if;
    end if;
  end process reg_data_ps;

  reg_clr_ps : process (rd_clk, rst_n) is
  begin  -- process reg_clr
    if rst_n = '0' then                 -- asynchronous reset (active low)
     ram_start <= '0';
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if reg_clr_cnt = x"0F" then
        ram_start <= '0';
      elsif reg_addr = x"01" and reg_data = x"eeeeeeee" then
       ram_start <= '1';
      end if;
    -- else
    --   reg_clr <= '0';
    end if;
  end process reg_clr_ps;

  -- purpose: to control the period of the reg_clr
  -- type   : sequential
  -- inputs : rd_clk, rst_n
  -- outputs: 
  reg_clr_cnt_ps : process (rd_clk, rst_n) is
  begin  -- process reg_clr_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      reg_clr_cnt <= (others => '0');
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if ram_start = '1' then
        reg_clr_cnt <= reg_clr_cnt+1;
      elsif ram_start = '0' then
        reg_clr_cnt <= (others => '0');
      end if;
    end if;
  end process reg_clr_cnt_ps;

end Behavioral;

