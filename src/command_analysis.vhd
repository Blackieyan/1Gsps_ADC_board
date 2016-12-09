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
    ram_start_o   : out std_logic;
     upload_trig_ethernet_o : out std_logic;
    rst_n : in  std_logic;
    ram_switch : out std_logic_vector(2 downto 0);
    TX_dst_MAC_addr : out std_logic_vector(47 downto 0);
    cmd_smpl_en_o : out std_logic;
    cmd_smpl_depth : out std_logic_vector(15 downto 0)
    );
end command_analysis;

architecture Behavioral of command_analysis is
  signal mac_dst  : std_logic_vector(47 downto 0);
  signal mac_src  : std_logic_vector(47 downto 0);  -- 为了反馈地址预留的信号
  signal reg_addr : std_logic_vector(15 downto 0);
  signal reg_data : std_logic_vector(47 downto 0);
  signal reg_clr_cnt : std_logic_vector(7 downto 0);
  signal upload_trig_ethernet_cnt : std_logic_vector(7 downto 0);
  signal rd_en_d : std_logic;
  signal cmd_smpl_en_cnt : std_logic_vector(7 downto 0);
  signal upload_trig_ethernet : std_logic;
  signal ram_start : std_logic;
  signal cmd_smpl_en : std_logic;
  
  -- signal reg_clr_cnt : std_logic_vector(7 downto 0);
begin
  
ram_start_o<=ram_start;
cmd_smpl_en_o<=cmd_smpl_en;
upload_trig_ethernet_o<=upload_trig_ethernet;

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
      elsif rd_addr=x"1A" or (rd_en_d = '1' and rd_en = '0')then  --地址为0x1A或者rden信号下降,因为rddata有可能全读有可能只读0x11-0x17
        if reg_addr<=x"0010" then         --控制命令，清零
        reg_addr<=(others => '0');
        elsif reg_addr>x"0010" then --配置命令，保持
          reg_addr<=reg_addr;
      end if;
    end if;
    end if;
  end process reg_addr_ps;

  reg_data_ps : process (rd_clk, rst_n, rd_en_d, rd_en) is
  begin  -- process reg_data_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      reg_data <= (others => '0');
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if rd_addr = x"13" then
        reg_data(47 downto 40) <= rd_data;
      elsif rd_addr = x"14" then
        reg_data(39 downto 32) <= rd_data;
      elsif rd_addr = x"15" then
        reg_data(31 downto 24) <= rd_data;
      elsif rd_addr = x"16" then
        reg_data(23 downto 16) <= rd_data;
      elsif rd_addr = x"17" then
        reg_data(15 downto 8) <= rd_data;
      elsif rd_addr = x"18" then
        reg_data(7 downto 0) <= rd_data;
      elsif rd_addr=x"1A" or (rd_en_d = '1' and rd_en = '0')then  --地址为0x1a或者rden信号下降,因为rddata有可能全读有可能只读0x11-0x17,这是为了更容易接受上位机下发的MAC地址更改命令。地址更改命令为48位数据
        if reg_addr<=x"0010" then         --控制命令，清零
        reg_data<=(others => '0');
        elsif reg_addr>x"0010" then       --配置命令,保持
          reg_data<=reg_data;
        end if;
      end if;
    end if;
  end process reg_data_ps;
-------------------------------------------------------------------------------
  reg_clr_ps : process (rd_clk, rst_n) is
  begin  -- process reg_clr
    if rst_n = '0' then                 -- asynchronous reset (active low)
     ram_start <= '0';
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if reg_clr_cnt = x"0F" then
        ram_start <= '0';
      elsif reg_addr = x"0001" and reg_data = x"eeeeeeeeeeee" then
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
-------------------------------------------------------------------------------
  ram_switch_ps: process (rd_clk, rst_n) is
  begin  -- process ram_switch_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      ram_switch<=(others => '0');
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if reg_addr=x"0101" and reg_data = x"111111111111" then
        ram_switch <= "001";
      elsif reg_addr=x"0101" and reg_data =x"222222222222" then
        ram_switch<="010";
      elsif reg_addr=x"0101" and reg_data = x"333333333333"  then
        ram_switch<="100";              --fft channel
      end if;
    end if;
  end process ram_switch_ps;

-------------------------------------------------------------------------------
--上位机可以通过trig来读取ram内部的内容。设计成为：上位机的trig到来控制tx_module工作，tx_module将ram内部的数剧传输出来（通过ram_full来控制，判断ram_full的计数器可以灵活控制想要读取的ram的深度，初步设计为ram写满了ram_full）
  upload_trig_ethernet_ps : process (rd_clk, rst_n) is
  begin  -- process reg_clr
    if rst_n = '0' then                 -- asynchronous reset (active low)
     upload_trig_ethernet <= '0';
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if upload_trig_ethernet_cnt = x"0F" then  --0f是 upload_trig_ethernet的长度，控制命令只能持续一定时间然后消失。配置命令会一直存在直到被覆盖。
        upload_trig_ethernet <= '0';
      elsif reg_addr = x"0002" and reg_data = x"eeeeeeeeeeee" then
       upload_trig_ethernet <= '1';
      end if;
    -- else
    --   reg_clr <= '0';
    end if;
  end process upload_trig_ethernet_ps;

  -- purpose: to control the period of the rd_trig_ethernet
  -- type   : sequential
  -- inputs : rd_clk, rst_n
  -- outputs: 
  upload_trig_ethernet_cnt_ps : process (rd_clk, rst_n) is
  begin  -- process reg_clr_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      upload_trig_ethernet_cnt <= (others => '0');
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if  upload_trig_ethernet = '1' then
       upload_trig_ethernet_cnt <=  upload_trig_ethernet_cnt+1;
      elsif  upload_trig_ethernet = '0' then
         upload_trig_ethernet_cnt <= (others => '0');
      end if;
    end if;
  end process upload_trig_ethernet_cnt_ps;
  -----------------------------------------------------------------------------
  cmd_smpl_en_ps: process (rd_clk, rst_n) is
  begin  -- process cmd_sample_en_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      cmd_smpl_en<='0';
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if cmd_smpl_en_cnt=x"0f" then
        cmd_smpl_en<='0';
      elsif reg_addr =x"0003" and reg_data =x"eeeeeeeeeeee" then
        cmd_smpl_en<='1';
      end if;
    end if;
  end process cmd_smpl_en_ps;

  cmd_smpl_en_cnt_ps: process (rd_clk, rst_n) is
  begin  -- process cmd_smpl_en_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      cmd_smpl_en_cnt<=(others => '0');
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if cmd_smpl_en ='1' then
      cmd_smpl_en_cnt<=cmd_smpl_en_cnt+1;
      elsif cmd_smpl_en ='0' then
        cmd_smpl_en_cnt<=(others => '0');
      end if;
    end if;
  end process cmd_smpl_en_cnt_ps;
  --cmd_smple_en是上位机用来解锁trigin的enable信号，长度由计数器决定。目前设置是固定数2000.
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  --配置命令
  -- purpose: to assign new destination MAC address in case that the PC changes.
  -- type   : sequential
  -- inputs : rd_clk, rst_n
  -- outputs: TX_dst_MAC_addr
  TX_dst_MAC_address_ps: process (rd_clk, rst_n) is
  begin  -- process TX_dst_MAC_address_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      TX_dst_MAC_addr<=x"ffffffffffff";
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if reg_addr = x"0011"  then
        TX_dst_MAC_addr<=reg_data;
      end if;
    end if;
  end process TX_dst_MAC_address_ps;

------------------------------------------------------------------------------
-- purpose: to configure the ram sampling depth as a register
-- type   : sequential
-- inputs : rd_clk, rst_n
-- outputs: 
cmd_smpl_depth_ps: process (rd_clk, rst_n) is
begin  -- process ram_smpl_depth_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_smpl_depth<=x"07d0";
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
    if reg_addr =x"0012" then
      cmd_smpl_depth<=reg_data(47 downto 32);
    end if;
  end if;
end process cmd_smpl_depth_ps;
end Behavioral;
