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
  signal upload_trig_ethernet : std_logic;
  signal ram_start : std_logic;
  signal cmd_smpl_en : std_logic;
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
      elsif rd_addr=x"1A" or (rd_en_d = '1' and rd_en = '0')then  --µØÖ·Îª0x1A»òÕßrdenÐÅºÅÏÂ½µ,ÒòÎªrddataÓÐ¿ÉÄÜÈ«¶ÁÓÐ¿ÉÄÜÖ»¶Á0x11-0x17
        if reg_addr<=x"0010" then         --¿ØÖÆÃüÁî£¬ÇåÁã
        reg_addr<=(others => '0');
        elsif reg_addr>x"0010" then --ÅäÖÃÃüÁî£¬±£³Ö
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
      elsif rd_addr=x"1A" or (rd_en_d = '1' and rd_en = '0')then  --µØÖ·Îª0x1a»òÕßrdenÐÅºÅÏÂ½µ,ÒòÎªrddataÓÐ¿ÉÄÜÈ«¶ÁÓÐ¿ÉÄÜÖ»¶Á0x11-0x17,ÕâÊÇÎªÁË¸üÈÝÒ×½ÓÊÜÉÏÎ»»úÏÂ·¢µÄMACµØÖ·¸ü¸ÄÃüÁî¡£µØÖ·¸ü¸ÄÃüÁîÎª48Î»Êý¾Ý
        if reg_addr<=x"0010" then         --¿ØÖÆÃüÁî£¬ÇåÁã
        reg_data<=(others => '0');
        elsif reg_addr>x"0010" then       --ÅäÖÃÃüÁî,±£³Ö
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
--ÉÏÎ»»ú¿ÉÒÔÍ¨¹ýtrigÀ´¶ÁÈ¡ramÄÚ²¿µÄÄÚÈÝ¡£Éè¼Æ³ÉÎª£ºÉÏÎ»»úµÄtrigµ½À´¿ØÖÆtx_module¹¤×÷£¬tx_module½«ramÄÚ²¿µÄÊý¾ç´«Êä³öÀ´£¨Í¨¹ýram_fullÀ´¿ØÖÆ£¬ÅÐ¶Ïram_fullµÄ¼ÆÊýÆ÷¿ÉÒÔÁé»î¿ØÖÆÏëÒª¶ÁÈ¡µÄramµÄÉî¶È£¬³õ²½Éè¼ÆÎªramÐ´ÂúÁËram_full£©
  upload_trig_ethernet_ps : process (rd_clk, rst_n) is
  begin  -- process reg_clr
    if rst_n = '0' then                 -- asynchronous reset (active low)
     upload_trig_ethernet <= '0';
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if upload_trig_ethernet_cnt = x"0F" then  --0fÊÇ upload_trig_ethernetµÄ³¤¶È£¬¿ØÖÆÃüÁîÖ»ÄÜ³ÖÐøÒ»¶¨Ê±¼äÈ»ºóÏûÊ§¡£ÅäÖÃÃüÁî»áÒ»Ö±´æÔÚÖ±µ½±»¸²¸Ç¡£
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
  --cmd_smple_enÊÇÉÏÎ»»úÓÃÀ´½âËøtriginµÄenableÐÅºÅ£¬³¤¶ÈÓÉ¼ÆÊýÆ÷¾ö¶¨¡£Ä¿Ç°ÉèÖÃÊÇ¹Ì¶¨Êý2000.
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  --ÅäÖÃÃüÁî
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
begin  -- ��ַ33 ���֡���
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
begin  -- ��ַ34 ��λ����ģʽ
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
begin  -- ��ַ35 ��λ�������ݲ�������
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
begin  -- ��ַ36 ��λ������������һ��
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
begin  -- ��ַ34 ��λ����ģʽ
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
begin  -- ��ַ35 ��λ�������ݲ�������
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
begin  -- ��ַ36 ��λ������������һ��
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
begin  -- ��ַ36 ��λ������������һ��
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
end Behavioral;
