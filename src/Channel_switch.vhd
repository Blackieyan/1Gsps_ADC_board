----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:54:53 11/08/2016 
-- Design Name: 
-- Module Name:    Channel_switch - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;
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

entity Channel_switch is
  port (
    CLK_125M : in std_logic;
    Ram_Q_last : in std_logic;
    Ram_I_last : in std_logic;
    Ram_I_doutb : in std_logic_vector(7 downto 0);
    Ram_Q_doutb : in std_logic_vector(7 downto 0);
    Ram_Q_rden : out std_logic;
    Ram_I_rden : out std_logic;
    -- Ram_Q_sw : out std_logic;
    -- Ram_I_sw : out std_logic;
    Upld_finish : out std_logic;
    CH_flag : out std_logic_vector(7 downto 0);
    CH_stat_o: out std_logic_vector(1 downto 0);
    FIFO_upload_data : out std_logic_vector(7 downto 0);
    rst_n : in std_logic;
    Ram_rden : in std_logic;
    data_strobe : in std_logic;
    sw_RAM_last : out std_logic
   
    );
end Channel_switch;

architecture Behavioral of Channel_switch is
signal  Ram_Q_last_d : std_logic;
signal  Ram_I_last_d : std_logic;
signal  Ram_Q_last_d2 : std_logic;
signal  Ram_I_last_d2 : std_logic;
signal  Ram_Q_last_d3 : std_logic;
signal  Ram_I_last_d3 : std_logic;
signal  Ram_Q_last_d4 : std_logic;
signal  Ram_I_last_d4 : std_logic;
signal  Ram_Q_last_d5 : std_logic;
signal  Ram_I_last_d5 : std_logic;
signal psedge_ram_Q_last : std_logic;
signal psedge_ram_I_last : std_logic;
signal CH_stat : std_logic_vector(1 downto 0);
signal CH_stat_d : std_logic_vector(1 downto 0);
signal CH_stat_d2 : std_logic_vector(1 downto 0);
signal CH_stat_d3 : std_logic_vector(1 downto 0);
signal CH_stat_d4 : std_logic_vector(1 downto 0);
  
begin
  CH_stat_o<=CH_stat;
-- purpose: generate Channel_states
-- type   : sequential
-- inputs : CLK_125M, rst_n
-- outputs: 
-- CH_stat_ps: process (CLK_125M, rst_n) is
-- begin  -- process CH_stat_ps
--   if rst_n = '0' then                   -- asynchronous reset (active low)
--     CH_stat<="00";
--   elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
--     case Ram_I_last & Ram_Q_last is
--       when "00" =>
--         CH_stat<="00";
--       when "01" =>
--         CH_stat<="01";
--       when "11" =>
--         CH_stat<="11";
--       when others =>
--         CH_stat<="11";
--       when others => null;
-- --不想有太多的线进入判断模块所以用两bit的stat代替8bit的flag CH_stat<="11"的情况下等待外部触发
--     end case;
--   end if;
-- end process CH_stat_ps;
  -- CH_stat<=Ram_I_last & Ram_Q_last;
  -- CH_stat_d4<=Ram_I_last_d4 & Ram_Q_last_d4;
  sw_RAM_last<=psedge_ram_I_last or  psedge_ram_Q_last;  --让帧提前结束

  CH_stat_ps: process (CLK_125M, rst_n) is
  begin  -- process CH_stat_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      CH_stat<="11";
      CH_stat_d<="11";
      CH_stat_d2<="11";
      CH_stat_d3<="11";
      CH_stat_d4<="11";
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
     CH_stat<=Ram_I_last & Ram_Q_last;
     CH_stat_d<=CH_stat;
     CH_stat_d2<=CH_stat_d;
     CH_stat_d3<=CH_stat_d2;
     CH_stat_d4<=CH_stat_d3;
    end if;
  end process CH_stat_ps;
  
  Ram_last_d_ps: process (CLK_125M, rst_n) is
  begin  -- process Ram_last_d_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Ram_I_last_d<='1';
      Ram_Q_last_d<='1';
      Ram_I_last_d2<='1';
      Ram_Q_last_d2<='1';
      Ram_Q_last_d3<='1';
      Ram_I_last_d3<='1';
      Ram_Q_last_d4<='1';
      Ram_I_last_d4<='1';
      Ram_Q_last_d5<='1';
      Ram_Q_last_d5<='1';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      Ram_Q_last_d<=Ram_Q_last;
      Ram_I_last_d<=Ram_I_last;
      Ram_I_last_d2<=Ram_I_last_d;
      Ram_Q_last_d2<=Ram_Q_last_d;
      Ram_I_last_d3<=Ram_I_last_d2;
      Ram_Q_last_d3<=Ram_Q_last_d2;
      Ram_I_last_d4<=Ram_I_last_d3;
      Ram_Q_last_d4<=Ram_Q_last_d3;
      Ram_I_last_d5<=Ram_I_last_d4;
      Ram_Q_last_d5<=Ram_Q_last_d4;
    end if;
  end process Ram_last_d_ps;

  psedge_ram_last_ps: process (CLK_125M, rst_n) is
  begin  -- process psedge_ram_last_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      psedge_ram_Q_last<='0';
      psedge_ram_I_last<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      if Ram_Q_last_d = '1' and Ram_Q_last_d2 = '0' then
        psedge_ram_Q_last <= '1';
      else
        psedge_ram_Q_last <= '0';
      end if;
      if Ram_I_last_d = '1' and Ram_I_last_d2 = '0' then
        psedge_ram_I_last <= '1';
      else
        psedge_ram_I_last <= '0';
      end if;
    end if;
  end process psedge_ram_last_ps;
  


ram_rden_ps: process (CLK_125M, rst_n, ram_rden, CH_stat_d4) is
begin  -- process ram_rden_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    Ram_I_rden<=ram_rden;
    Ram_Q_rden<='0';
  -- elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
    -- elsif data_strobe ='0' then
   elsif ram_rden='1' then
      case CH_stat_d4 is                --必须>=d4不然会使得ram_i_rden在帧内拉高，导致i通道帧开始读的地址不从0开始
        when "00" =>
          Ram_Q_rden<=ram_rden;
          Ram_I_rden<='0';
        when "01" =>
          Ram_Q_rden<='0';
          Ram_I_rden<=ram_rden;
        when "11" =>
          Ram_Q_rden<=ram_rden;
          Ram_I_rden<='0';
        when others =>
          Ram_Q_rden<=ram_rden;
          Ram_I_rden<='0';
      end case;
    else
      Ram_I_rden<='0';
      Ram_Q_rden<='0';
    -- end if;
    -- else
    --   Ram_I_rden<=Ram_I_rden;
    --   Ram_Q_rden<=Ram_Q_rden;
    -- end if;
  end if;
end process ram_rden_ps;     --为了底层例化的mux不再由太多的选择状态所有没有写两个rden都为0的状态。这个模块相当于再打一拍，为了稳定。
  -- purpose: use if statement to practice last module
  -- type   : sequential
  -- inputs : CLK_125M, rst_n
  -- outputs: 
  -- Ram_rden_if_ps: process (CLK_125M, rst_n) is
  -- begin  -- process Ram_rden_if_ps
  --   if rst_n = '0' then                 -- asynchronous reset (active low)
  --   Ram_I_rden<=ram_rden;
  --   Ram_Q_rden<='0';
  --   elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
  --     if data_strobe='0' then
  --       if CH_stat="00" then
  --         Ram_Q_rden<=ram_rden;
  --         Ram_I_rden<='0';
  --       elsif CH_stat="01" then
  --         Ram_Q_rden<='0';
  --         Ram_I_rden<=ram_rden;
  --       elsif CH_stat="11" then
  --         Ram_Q_rden<=ram_rden;
  --         Ram_I_rden<='0';         
  --       end if;
  --     end if;
  --   end if;
  -- end process Ram_rden_if_ps;

CH_flag_ps: process (CLK_125M, rst_n) is  --CH_flag比真正的ram_last翻转晚了2拍
begin  -- process CH_flag_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    CH_flag<=x"01";
  elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
    case CH_stat is
      when "00" =>
        CH_flag<=x"01";                 --Q channel 
      when "01" =>
        CH_flag<=x"10";                 --I channel
      when others =>
        CH_flag<=x"01";
    end case;
  end if;
end process CH_flag_ps;

-- purpose: switch the data channel
-- type   : sequential
-- inputs : CLK_125M, rst_n
-- outputs: 
FIFO_upload_data_ps: process (CLK_125M, rst_n, CH_stat_d4, Ram_Q_doutb, Ram_I_doutb) is
begin  -- process FIFO_upload_data_ps
  -- if CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
    -- if data_strobe ='0' then
    case CH_stat_d4 is
      when "00" =>
        FIFO_upload_data<=Ram_Q_doutb;
      when "01" =>
        FIFO_upload_data<=Ram_I_doutb;
      when others =>
        FIFO_upload_data<=Ram_Q_doutb;
    end case;
    -- end if;
  -- end if;
end process FIFO_upload_data_ps;

upld_finish_ps: process (CLK_125M, rst_n) is
begin  -- process upld_finish_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    upld_finish<='1';
  elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
    if CH_stat ="11" then
      upld_finish<='1';
    else
      upld_finish<='0';
    end if;
  end if;
end process upld_finish_ps;

end Behavioral;
