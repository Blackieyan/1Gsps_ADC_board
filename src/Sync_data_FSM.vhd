----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:34:29 04/08/2018 
-- Design Name: 
-- Module Name:    Sync_data_FSM - Behavioral 
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

entity Sync_data_FSM is
  port(
    clk : in std_logic;
    rst_n : in std_logic;
    stat_rdy :in std_logic;
    sync_en : in std_logic;
    state0 : in std_logic_vector(1 downto 0);
    state1 : in std_logic_vector(1 downto 0);
    state2 : in std_logic_vector(1 downto 0);
    state3 : in std_logic_vector(1 downto 0);
    state4 : in std_logic_vector(1 downto 0);
    state5 : in std_logic_vector(1 downto 0);
    state6 : in std_logic_vector(1 downto 0);
    state7 : in std_logic_vector(1 downto 0);
    dout : out std_logic_vector(3 downto 0)
    );
end Sync_data_FSM;

architecture Behavioral of Sync_data_FSM is
  type state_type is (IDLE, F, B, SEVEN, THREE, DATA0, DATA1, DATA2, DATA3);
  signal current_state : state_type;
  signal next_state : state_type;


begin

  state_switch_ps: process (clk, rst_n) is
  begin  -- process state_switch_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      current_state<=IDLE;
    elsif clk'event and clk = '1' then  -- rising clock edge
      current_state<=next_state;
    end if;
  end process state_switch_ps;

-- purpose: 状态机跳变条件，组合逻辑
-- type   : combinational
-- inputs : current_state
-- outputs: 
STATE_CHANGE_ps: process (rst_n, current_state, stat_rdy, sync_en) is
begin  -- process STATE_CHANGE_ps
  case current_state is
    when IDLE =>
      if sync_en ='1' then
        next_state<= F;
      else
        next_state<=IDLE;
      end if;

    when F =>
      if stat_rdy = '1' then
        next_state<= DATA0;
      else
        next_state<= B;
      end if;

    when B =>
      if stat_rdy ='1' then
        next_state<=DATA0;
      else
        next_state<=SEVEN;
      end if;

    when SEVEN =>
      if stat_rdy='1' then
        next_state<=DATA0;
      else
        next_state<=THREE;
      end if;
--FB73都是同步过程，为了在上位机命令sync_en=0到来后任然保持一个完整的FB73同步输出，所以只在状态'3'对sync_en命令敏感

    when THREE =>
      if sync_en ='0' then
        next_state<=IDLE;
      elsif sync_en='1' then
        if stat_rdy ='1' then
          next_state<=DATA0;
        else
          next_state<= F;
        end if;
      end if;

    when DATA0 =>
      next_state<= DATA1;
    when DATA1 =>
      next_state<= DATA2;
    when DATA2 =>
      next_state<= DATA3;
    when DATA3 =>
      next_state<= F;
    when others => null;
  end case;
  end process STATE_CHANGE_ps;

-- purpose: 状态机输出，时序逻辑
-- type   : sequential
-- inputs : clk, rst_n
-- outputs: 
STATE_OUTPUT_ps: process (clk, rst_n) is
begin  -- process STATE_OUTPUT_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    dout<=x"f";
  elsif clk'event and clk = '1' then    -- rising clock edge
    case current_state is
      when IDLE =>
        dout<=x"f";
      when F =>
        dout<=x"F";
      when B =>
        dout<=x"B";
      when SEVEN =>
        dout<=x"7";
      when THREE =>
        dout<=x"3";
      when data0 =>
        dout<=state0(1)&state0(0)&state1(1)&state1(0);
      when data1 =>
        dout<=state2(1)&state2(0)&state3(1)&state3(0);
      when data2 =>
        dout<=state4(1)&state4(0)&state5(1)&state5(0);
      when data3 =>
        dout<=state6(1)&state6(0)&state7(1)&state7(0);
      when others => null;
    end case;
  end if;
end process STATE_OUTPUT_ps;


end Behavioral;

