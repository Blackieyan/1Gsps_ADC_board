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
  generic(
  dds_phase_width : integer := 24
    );
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
	 	 	 weight_ram_addr : out STD_LOGIC_vector(15 downto 0);
	 	 	 weight_ram_data : out STD_LOGIC_vector(11 downto 0);
	 	 	 host_set_ram_switch : out STD_LOGIC;
	 	 	 weight_ram_data_en : out STD_LOGIC;
	 	 	 weight_ram_sel : out STD_LOGIC_vector(31 downto 0);
	 	 	 host_reset : out STD_LOGIC;
	 	 	 host_rd_mode : out STD_LOGIC;
	 host_rd_status : out STD_LOGIC;
	 host_rd_enable : out STD_LOGIC;
	 host_rd_start_addr : out STD_LOGIC_VECTOR(18 DOWNTO 0);
	 host_rd_length : out STD_LOGIC_VECTOR(18 DOWNTO 0);
	 host_rd_seg_len : out STD_LOGIC_VECTOR(15 DOWNTO 0);
	 is_counter			    : out    std_logic;
	 wait_cnt_set         : out    std_logic_vector(23 downto 0);
    self_adpt_en   : out std_logic;
    ram_start_o   : out std_logic;
    use_test_IQ_data   : out std_logic;
     upload_trig_ethernet_o : out std_logic;
    rst_n : in  std_logic;
    cmd_pstprc_IQ_sw : out std_logic_vector(1 downto 0);
    TX_dst_MAC_addr : out std_logic_vector(47 downto 0);
    clear_frame_cnt : out std_logic;
    cmd_smpl_en_o : out std_logic;
    cmd_smpl_depth : out std_logic_vector(15 downto 0);
    cmd_smpl_trig_cnt : out std_logic_vector(23 downto 0);
    Cmd_demowinln : out std_logic_vector(14 downto 0);
    Cmd_demowinstart : out std_logic_vector(14 downto 0);
    cmd_ADC_gain_adj : out std_logic_vector(18 downto 0);
    cmd_ADC_reconfig : buffer std_logic;
    cmd_pstprc_num_en : out std_logic;
    cmd_Pstprc_num : out std_logic_vector(3 downto 0);
    cmd_Pstprc_DPS : out std_logic_vector(dds_phase_width downto 0);
    cmd_Estmr_A : out std_logic_vector(31 downto 0);
    cmd_Estmr_B : out std_logic_vector(31 downto 0);
    cmd_Estmr_C : out std_logic_vector(63 downto 0);
    cmd_Estmr_sync_en : out std_logic;
    cmd_Estmr_num : out std_logic_vector(3 downto 0);
    cmd_Estmr_num_en : out std_logic
    -- cmd_Pstprc_DPS_en : out std_logic
    );
end command_analysis;

architecture Behavioral of command_analysis is
  signal mac_dst  : std_logic_vector(47 downto 0);
  signal mac_src  : std_logic_vector(47 downto 0);  
  signal reg_addr : std_logic_vector(15 downto 0);
  signal reg_data : std_logic_vector(47 downto 0);
  signal adc_reconfig_cnt : std_logic_vector(7 downto 0);
  signal reg_clr_cnt : std_logic_vector(7 downto 0);
  signal upload_trig_ethernet_cnt : std_logic_vector(7 downto 0);
  signal rd_en_d : std_logic;
  signal cmd_smpl_en_cnt : std_logic_vector(7 downto 0);
  signal weight_ram_sel_int : std_logic_vector(4 downto 0);
  signal weight_ram_addr_int : std_logic_vector(15 downto 0);
  signal weight_ram_len : std_logic_vector(15 downto 0);
  signal upload_trig_ethernet : std_logic;
  signal ram_start : std_logic;
  signal cmd_smpl_en : std_logic;
  signal ram_data_en_int : std_logic;
  signal weight_ram_data_active : std_logic;
  -- signal cmd_Pstprc_DPS_d : std_logic_vector(15 downto 0);

  
  -- signal reg_clr_cnt : std_logic_vector(7 downto 0);
begin
  
ram_start_o<=ram_start;
cmd_smpl_en_o<=cmd_smpl_en;
upload_trig_ethernet_o<=upload_trig_ethernet;
-- cmd_Pstprc_DPS_en <= Pstprc_DPS_en;
  
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
      elsif rd_en_d = '1' and rd_en = '0' then  
        reg_addr<=(others => '0');
      elsif reg_addr>x"0010" then
        reg_addr<=reg_addr;
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
      elsif rd_addr=x"1A" or (rd_en_d = '1' and rd_en = '0')then 
        if reg_addr<=x"0010" then       
        reg_data<=(others => '0');
        elsif reg_addr>x"0010" then       
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
        if rd_addr=x"19" then
       ram_start <= '1';
        end if;
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
     cmd_pstprc_IQ_sw <= "01";
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if rd_addr=x"19" then
        if reg_addr=x"0101" and reg_data = x"111111111111" then
          cmd_pstprc_IQ_sw <= "01";
        elsif reg_addr=x"0101" and reg_data =x"222222222222" then
          cmd_pstprc_IQ_sw <="10";
      -- elsif reg_addr=x"0101" and reg_data = x"333333333333"  then
      --   ram_switch<="100";              --fft channel
        end if;
      end if;
    end if;
  end process ram_switch_ps;

-------------------------------------------------------------------------------

  upload_trig_ethernet_ps : process (rd_clk, rst_n) is
  begin  -- process reg_clr
    if rst_n = '0' then                 -- asynchronous reset (active low)
     upload_trig_ethernet <= '0';
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if upload_trig_ethernet_cnt = x"0F" then  
        upload_trig_ethernet <= '0';
      elsif reg_addr = x"0002" and reg_data = x"eeeeeeeeeeee" then
        if rd_addr=x"19" then
          upload_trig_ethernet <= '1';
        end if;
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
        if rd_addr=x"19" then
          cmd_smpl_en<='1';
        end if;
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
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------

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
        if rd_addr=x"19" then
        TX_dst_MAC_addr<=reg_data;
        end if;
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
-------------------------------------------------------------------------------
cmd_trig_cnt_ps: process (rd_clk, rst_n) is
begin  -- process ram_smpl_depth_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_smpl_trig_cnt<=x"0007D0";         -- reponse to trig 2000 times default 
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
    if reg_addr =x"0013" then
      if rd_addr=x"19" then
        cmd_smpl_trig_cnt<=reg_data(47 downto 24);
      end if;
    end if;
  end if;
end process cmd_trig_cnt_ps;

cmd_demowinln_ps: process (rd_clk, rst_n) is
begin  -- process ram_smpl_depth_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_demowinln<="000"&x"109";         -- reponse to trig 2000 times default 
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
    if reg_addr =x"0014" then
      if rd_addr=x"19" then
        cmd_demowinln<=reg_data(46 downto 32);
      end if;
    end if;
  end if;
end process cmd_demowinln_ps;

cmd_demowinstart_ps: process (rd_clk, rst_n) is
begin  -- process ram_smpl_depth_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_demowinstart<="000"&x"030";         -- reponse to trig 2000 times default 
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
    if reg_addr =x"0015" then
      if rd_addr=x"19" then
        cmd_demowinstart<=reg_data(46 downto 32);
      end if;
    end if;
  end if;
end process cmd_demowinstart_ps;

Pstprc_DPS_ps: process (rd_clk, rst_n) is
begin  -- process Pstprc_DPS_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_Pstprc_DPS <= '0'&x"150000";
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
    if reg_addr =x"0016" then
      if rd_addr=x"19" then
        cmd_Pstprc_DPS<=reg_data(47 downto 23);
      end if;
    end if;
  end if;
end process Pstprc_DPS_ps;

pstprc_num_ps: process (rd_clk, rst_n) is
begin  -- process pstprc_num_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_Pstprc_num<=(others => '0');
    cmd_pstprc_num_en<='0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"0018" then
      if rd_addr=x"19" then
        cmd_Pstprc_num<=reg_data(47 downto 44);
        cmd_pstprc_num_en<='1';
      else
        cmd_pstprc_num_en<='0';
      end if;
    end if;
  end if;
end process pstprc_num_ps;
-------------------------------------------------------------------------------
-- Estmr_sync_en_ps: process (rd_clk, rst_n) is
-- begin  -- process Estmr_sync_en_ps
--   if rst_n = '0' then                   -- asynchronous reset (active low)
--     cmd_Estmr_sync_en<="0";
--   elsif rd_clk'event and rd_clk = '1' then    -- rising clock edge
--     if reg_addr =x"0019" then
--       if rd_addr=x"19" then
--         cmd_Estmr_sync_en<=reg_data(47);
--       end if;
--     end if;
--   end if;
-- end process Estmr_sync_en_ps;

Estmr_sync_en_ps: process (rd_clk, rst_n) is
begin  -- process Estmr_sync_en_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_Estmr_sync_en<='1';
  elsif rd_clk'event and rd_clk = '1' then    -- rising clock edge\
    if rd_addr=x"19" then
      if reg_addr =x"0019" and reg_data(47 downto 44) = "0000" then
        cmd_Estmr_sync_en<='0';
      elsif reg_addr =x"0019" and reg_data(47 downto 44)="1111" then
        cmd_Estmr_sync_en<='1';
      end if;
    end if;
  end if;
end process Estmr_sync_en_ps;

Estmr_A_ps: process (rd_clk, rst_n) is
begin  -- process Estmr_A_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_Estmr_A <= (others => '0');
    cmd_Estmr_C(15 downto 0)<=(others => '0'); 
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"001A" then
        if rd_addr=x"19" then
          cmd_Estmr_A<=reg_data(47 downto 16);
          cmd_Estmr_C(15 downto 0)<=reg_data(15 downto 0);
        end if;
      end if;
  end if;
end process Estmr_A_ps;

Estmr_B_ps: process (rd_clk, rst_n) is
begin  -- process Estmr_B_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_Estmr_B <= (others => '0');
    cmd_Estmr_C(31 downto 16)<=(others => '0'); 
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"001B" then
        if rd_addr=x"19" then
          cmd_Estmr_B<=reg_data(47 downto 16);
          cmd_Estmr_C(31 downto 16)<=reg_data(15 downto 0);
        end if;
      end if;
  end if;
end process Estmr_B_ps;

Estmr_C_ps: process (rd_clk, rst_n) is
begin  -- process Estmr_C_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_Estmr_C(63 downto 32)<=(others => '0'); 
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"001C" then
        if rd_addr=x"19" then
          cmd_Estmr_C(63 downto 32)<=reg_data(47 downto 16);
        end if;
      end if;
  end if;
end process Estmr_C_ps;

Estmr_num_ps: process (rd_clk, rst_n) is
begin  -- process pstprc_num_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    cmd_Estmr_num<=(others => '0');
    cmd_Estmr_num_en<='0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"001D" then
        if rd_addr=x"19" then
          cmd_Estmr_num<=reg_data(47 downto 44);
          cmd_Estmr_num_en<='1';
        else
          cmd_Estmr_num_en<='0';
        end if;
      end if;
  end if;
end process Estmr_num_ps;

self_adpt_ps: process (rd_clk, rst_n) is
begin  -- process pstprc_num_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    self_adpt_en <='0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"001E" then
        if rd_addr=x"19" then
          self_adpt_en<= reg_data(24);
        else
          self_adpt_en<='0';
        end if;
		else
			self_adpt_en<='0';
      end if;
  end if;
end process self_adpt_ps;

wait_cnt_ps: process (rd_clk, rst_n) is
begin  -- process pstprc_num_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
	 wait_cnt_set <= x"0186A0"; --100000 8ms
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"001F" then
        if rd_addr=x"19" then
          wait_cnt_set<= reg_data(47 downto 24);
        end if;
      end if;
  end if;
end process wait_cnt_ps;

demode_test_ps: process (rd_clk, rst_n) is
begin  -- process pstprc_num_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    is_counter <='0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"0020" then
        if rd_addr=x"19" then
          is_counter<= reg_data(24);
        end if;
      end if;
  end if;
end process demode_test_ps;

clear_frame_cnt_ps: process (rd_clk, rst_n) is
begin  -- 地址33 清除帧编号
  if rst_n = '0' then                   -- asynchronous reset (active low)
    clear_frame_cnt <='0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"0021" then
        if rd_addr=x"19" then
          clear_frame_cnt<= '1';
        else
          clear_frame_cnt<= '0';
        end if;
      else
        clear_frame_cnt<= '0';
      end if;
  end if;
end process clear_frame_cnt_ps;

host_rd_mode_ps: process (rd_clk, rst_n) is
begin  -- 地址34 上位机读模式
  if rst_n = '0' then                   -- asynchronous reset (active low)
    host_rd_mode <='1';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"0022" then
        if rd_addr=x"19" then
          host_rd_mode<= reg_data(24);
        end if;
      end if;
  end if;
end process host_rd_mode_ps;

host_rd_seg_len_ps: process (rd_clk, rst_n) is
begin  -- 地址35 上位机读数据参数设置
  if rst_n = '0' then                   -- asynchronous reset (active low)
    host_rd_seg_len <= (others =>'0');
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"0023" then
        if rd_addr=x"19" then
          host_rd_seg_len<= reg_data(15 downto 0);
        end if;
      end if;
  end if;
end process host_rd_seg_len_ps;

host_rd_start_ps: process (rd_clk, rst_n) is
begin  -- 地址36 上位机读数据启动一次
  if rst_n = '0' then                   -- asynchronous reset (active low)
    host_rd_start_addr  <= (others =>'0');
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
    if reg_addr =x"0024" then
      if rd_addr=x"19" then
        host_rd_start_addr <= reg_data(18 downto 0);
      end if;
    end if;
  end if;
end process host_rd_start_ps;
-- ADC_gain_adj_ps: process (rd_clk, rst_n) is
-- begin  -- process ADC_gain_adj_ps
--   if rst_n = '0' then                   -- asynchronous reset (active low)
--     cmd_ADC_gain_adj <= "0010000000000000000";
--   elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
--     if reg_addr = x"0017" then
--       cmd_ADC_gain_adj<="001"&reg_data(47 downto 32);
--     end if;
--   end if;
-- end process ADC_gain_adj_ps;

-- cmd_ADC_reconfig_ps: process (rd_clk, rst_n) is
-- begin  -- process cmd_ADC_reconfig_ps
--   if rst_n = '0' then                   -- asynchronous reset (active low)
--     cmd_ADC_reconfig<='0';
--   elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
--     if adc_reconfig_cnt<=x"10" then
--       cmd_ADC_reconfig<='0';
--     elsif reg_addr=x"0017" then
--       cmd_ADC_reconfig<='1';
--     end if;
--   end if;
-- end process cmd_ADC_reconfig_ps;

-- reconfig_ps: process (rd_clk, rst_n) is
-- begin  -- process reconfig_ps
--   if rst_n = '0' then                   -- asynchronous reset (active low)
--     adc_reconfig_cnt<=(others => '0');
--   elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
--     if cmd_ADC_reconfig<='1' then
--       adc_reconfig_cnt<=adc_reconfig_cnt+1;
--     elsif cmd_ADC_reconfig<='0' then
--       adc_reconfig_cnt<=(others => '0');
--     end if;
--   end if;
-- end process reconfig_ps;
host_rd_ps: process (rd_clk, rst_n) is
begin  -- 地址37 上位机读模式
  if rst_n = '0' then                   -- asynchronous reset (active low)
    host_rd_status <='0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"0025" then
        if rd_addr=x"19" then
          host_rd_status<= reg_data(24);
        end if;
      else
        host_rd_status<='0';
      end if;
  end if;
end process host_rd_ps;

host_rd_length_ps: process (rd_clk, rst_n) is
begin  -- 地址38 上位机读数据参数设置
  if rst_n = '0' then                   -- asynchronous reset (active low)
    host_rd_length <= (others =>'0');
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
      if reg_addr =x"0026" then
        if rd_addr=x"19" then
          host_rd_length <= reg_data(18 downto 0);
        end if;
      end if;
  end if;
end process host_rd_length_ps;

host_rd_enable_ps: process (rd_clk, rst_n) is
begin  -- 地址39 上位机读数据启动一次
  if rst_n = '0' then                   -- asynchronous reset (active low)
    host_rd_enable 		<= '0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
    if reg_addr =x"0027" then
      if rd_addr=x"19" then
        host_rd_enable	  <= '1';
      end if;
    else
      host_rd_enable<= '0';
    end if;
  end if;
end process host_rd_enable_ps;

use_test_IQ_data_ps: process (rd_clk, rst_n) is
begin  -- 地址40 上位机使用计数器测试IQ解模
  if rst_n = '0' then                   -- asynchronous reset (active low)
    use_test_IQ_data 		<= '0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
    if reg_addr =x"0028" then
      if rd_addr=x"19" then
        use_test_IQ_data	  <= reg_data(24);
      end if;
    end if;
  end if;
end process use_test_IQ_data_ps;

host_reset_ps: process (rd_clk) is
begin  -- 地址41 上位机复位使能
  if rd_clk'event and rd_clk = '1' then  -- rising clock edg
    if reg_addr =x"0029" then
      if rd_addr=x"19" then
        host_reset	  <= '0'; --低复位有效
      end if;
	 else
		host_reset <= '1';
    end if;
  end if;
end process host_reset_ps;

--加权RAM写入的整体设计
--1. 需要一条整体的数据切换指令，即切换原有的DDS生成数据模式和新增的上位机直写加权数据模式
--2. 加权数据写入时可能会分成好几帧数据，所以最好在每一帧数据中都指定RAM的选择，RAM的起始地址, 该帧数据中的加权数据个数
--    因为网络帧由于有效数据小于最小帧长使得会读到冗余数据
--3. 每一帧中的加权数据从rd_addr = X"18"开始，直到该帧结束都是会写入RAM的有效数据，上位机要注意这一点
--4. 加权数据每两个字节拼成一个数据，上位机要注意这一点
--5. 加权数据reg标识 x"2B"

---加权数据写入RAM中的数据
--原有的DDS模式和新增的加权DDS模式之间的切换
--默认为原有DDS数据模式



-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
host_set_ram_switch_ps: process (rd_clk, rst_n) is
begin  -- 地址42 
  if rst_n = '0' then                   -- asynchronous reset (active low)
    host_set_ram_switch 		<= '0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
    if reg_addr =x"002A" then
      if rd_addr=x"19" then
        host_set_ram_switch	  <= reg_data(0); --低复位有效
      end if;
    end if;
  end if;
end process host_set_ram_switch_ps;

-------------------------------------------------------------------------------


--加权RAM的选择
--共8个通道，每个通道有4个加权数据，所以是32个RAM，需要32个选择信号
weight_ram_data_sel_ps: process (rd_clk, rst_n) is
begin  -- 地址43
  if rst_n = '0' then                   -- asynchronous reset (active low)
    weight_ram_sel_int 		<= (others=>'0');
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
    if reg_addr =x"002B" then
      if rd_addr=x"14" then
        weight_ram_sel_int	  <= rd_data(4 downto 0); 
      end if;
    end if;
  end if;
end process weight_ram_data_sel_ps;

weight_ram_addr <= weight_ram_addr_int;
weight_ram_addr_ps: process (rd_clk, rst_n) is
begin  -- 地址43 
  if rst_n = '0' then                   -- asynchronous reset (active low)
    weight_ram_addr_int 		<= (others=>'0');
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
    if reg_addr=x"002B" then
      if rd_addr=x"16" then
         weight_ram_addr_int(7 downto 0)   <= rd_data;
		elsif(rd_addr=x"15") then
			weight_ram_addr_int(15 downto 8)  <= rd_data;
		elsif(ram_data_en_int = '1') then
			weight_ram_addr_int			  <= weight_ram_addr_int + '1';
      end if;
    end if;
  end if;
end process weight_ram_addr_ps; ---加权数据写入RAM中的偏移地址


-- 当前网络帧中的数据个数
weight_ram_len_ps: process (rd_clk, rst_n) is
begin  -- 地址43 
  if rst_n = '0' then                   -- asynchronous reset (active low)
    weight_ram_len 		<= (others=>'0');
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
    if reg_addr =x"002B" then
      if rd_addr=x"18" then
         weight_ram_len(7 downto 0)   <= rd_data;
		elsif(rd_addr=x"17") then
			weight_ram_len(15 downto 8)  <= rd_data;
		elsif(ram_data_en_int = '1') then
			weight_ram_len			  <= weight_ram_len - '1';
      end if;
    end if;
  end if;
end process weight_ram_len_ps;


---加权数据写RAM有效标志
weight_ram_data_en_ps: process (rd_clk, rst_n) is
begin  -- 地址43 
  if rst_n = '0' then                   -- asynchronous reset (active low)
    weight_ram_data_active 		<= '0';
  elsif rd_clk'event and rd_clk = '1' then  -- rising clock edg
    if reg_addr =x"002B" then
      if rd_addr=x"18" then
        weight_ram_data_active	  <= '1'; 
      end if;
    elsif(rd_en = '0') then
      weight_ram_data_active	  <= '0';
    end if;
  end if;
end process weight_ram_data_en_ps;
-------------------------------------------------------------------------------


---已经过chipscope调试
weight_ram_data_en <= ram_data_en_int;
weight_ram_data_ps: process (rd_clk) is
begin  --
  if rd_clk'event and rd_clk = '1' then  -- rising clock edg
	 if(rd_addr(0) = '1') then
		weight_ram_data(11 downto 8)   <= rd_data(3 downto 0);
		ram_data_en_int			   <= '0';
	 else
		weight_ram_data(7 downto 0)  <= rd_data(7 downto 0);
		if(weight_ram_len > 0) then
			ram_data_en_int			   <= weight_ram_data_active;
		else
			ram_data_en_int			   <= '0';
		end if;
	 end if;
  end if;
end process weight_ram_data_ps;
-------------------------------------------------------------------------------
process(weight_ram_sel_int)
begin
	case weight_ram_sel_int is
		when "00000" => weight_ram_sel <= x"00000001";
		when "00001" => weight_ram_sel <= x"00000002";
		when "00010" => weight_ram_sel <= x"00000004";
		when "00011" => weight_ram_sel <= x"00000008";
		when "00100" => weight_ram_sel <= x"00000010";
		when "00101" => weight_ram_sel <= x"00000020";
		when "00110" => weight_ram_sel <= x"00000040";
		when "00111" => weight_ram_sel <= x"00000080";
		when "01000" => weight_ram_sel <= x"00000100";
		when "01001" => weight_ram_sel <= x"00000200";
		when "01010" => weight_ram_sel <= x"00000400";
		when "01011" => weight_ram_sel <= x"00000800";
		when "01100" => weight_ram_sel <= x"00001000";
		when "01101" => weight_ram_sel <= x"00002000";
		when "01110" => weight_ram_sel <= x"00004000";
		when "01111" => weight_ram_sel <= x"00008000";
		when "10000" => weight_ram_sel <= x"00010000";
		when "10001" => weight_ram_sel <= x"00020000";
		when "10010" => weight_ram_sel <= x"00040000";
		when "10011" => weight_ram_sel <= x"00080000";
		when "10100" => weight_ram_sel <= x"00100000";
		when "10101" => weight_ram_sel <= x"00200000";
		when "10110" => weight_ram_sel <= x"00400000";
		when "10111" => weight_ram_sel <= x"00800000";
		when "11000" => weight_ram_sel <= x"01000000";
		when "11001" => weight_ram_sel <= x"02000000";
		when "11010" => weight_ram_sel <= x"04000000";
		when "11011" => weight_ram_sel <= x"08000000";
		when "11100" => weight_ram_sel <= x"10000000";
		when "11101" => weight_ram_sel <= x"20000000";
		when "11110" => weight_ram_sel <= x"40000000";
		when "11111" => weight_ram_sel <= x"80000000";
		when others => weight_ram_sel <= x"00000000";
	end case;
end process;

end Behavioral;
