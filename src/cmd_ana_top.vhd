----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:34:32 12/08/2016 
-- Design Name: 
-- Module Name:    cmd_ana_top - Behavioral 
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

entity cmd_ana_top is
  generic(
    dds_phase_width : integer := 24
    );
  port(
    rd_clk               : in     std_logic;
    frm_length           : out    std_logic_vector(15 downto 0);
    frm_type             : out    std_logic_vector(15 downto 0);
    ram_start            : out    std_logic;
    upload_trig_ethernet : out    std_logic;
    rst_n                : in     std_logic;
	 clear_frame_cnt      : out    std_logic;
	 is_counter			    : out    std_logic;
	 wait_cnt_set         : out    std_logic_vector(23 downto 0);
    ram_switch           : out    std_logic_vector(2 downto 0);
    TX_dst_MAC_addr      : out    std_logic_vector(47 downto 0);
    self_adpt_en          : out    std_logic;
	 	 host_rd_mode : out STD_LOGIC;
	 host_rd_status : out STD_LOGIC;
	 host_rd_enable : out STD_LOGIC;
	 host_rd_start_addr : out STD_LOGIC_VECTOR(18 DOWNTO 0);
	 host_rd_seg_cnt : out STD_LOGIC_VECTOR(15 DOWNTO 0);
	 host_rd_seg_len : out STD_LOGIC_VECTOR(15 DOWNTO 0);
    cmd_smpl_en          : out    std_logic;
    cmd_smpl_depth       : out    std_logic_vector(15 downto 0);
    cmd_smpl_trig_cnt    : out    std_logic_vector(23 downto 0);
    cmd_pstprc_IQ_sw     : out    std_logic_vector(1 downto 0);
    ethernet_Rd_en       : out    std_logic;
    ethernet_Rd_Addr     : out    std_logic_vector(13 downto 0);
    ethernet_frm_valid   : in     std_logic;
    ethernet_rd_data     : in     std_logic_vector(7 downto 0);
    Cmd_demowinln        : out    std_logic_vector(14 downto 0);
    Cmd_demowinstart     : out    std_logic_vector(14 downto 0);
    cmd_ADC_gain_adj     : out    std_logic_vector(18 downto 0);
    cmd_adc_reconfig     : buffer std_logic;
    cmd_pstprc_num_en    : out    std_logic;
    cmd_Pstprc_num       : out    std_logic_vector(3 downto 0);
    cmd_Pstprc_DPS       : out    std_logic_vector(dds_phase_width downto 0);
    cmd_Estmr_A          : out    std_logic_vector(31 downto 0);
    cmd_Estmr_B          : out    std_logic_vector(31 downto 0);
    cmd_Estmr_C          : out    std_logic_vector(63 downto 0);
    cmd_Estmr_sync_en    : out    std_logic;
    cmd_Estmr_num        : out    std_logic_vector(3 downto 0);
    cmd_Estmr_num_en     : out    std_logic
   -- cmd_Pstprc_DPS_en : out std_logic
    );
end cmd_ana_top;
architecture Behavioral of cmd_ana_top is

  signal frm_valid_d     : std_logic;
  signal rd_en           : std_logic;
  signal rd_addr         : std_logic_vector(13 downto 0);
  signal rd_data         : std_logic_vector(7 downto 0);
  signal cmd_ana_rd_data : std_logic_vector(7 downto 0);
  signal cmd_ana_rd_addr : std_logic_vector(13 downto 0);
  signal cmd_ana_rd_en   : std_logic;


  component command_analysis is
    port (
      rd_data                : in     std_logic_vector(7 downto 0);
      rd_clk                 : in     std_logic;
      rd_addr                : in     std_logic_vector(13 downto 0);
      rd_en                  : in     std_logic;
      frm_length             : out    std_logic_vector(15 downto 0);
      frm_type               : out    std_logic_vector(15 downto 0);
      ram_start_o            : out    std_logic;
      upload_trig_ethernet_o : out    std_logic;
      rst_n                  : in     std_logic;
	   is_counter			    : out    std_logic;
	   wait_cnt_set         : out    std_logic_vector(23 downto 0);
      cmd_pstprc_IQ_sw       : out    std_logic_vector(1 downto 0);
      TX_dst_MAC_addr        : out    std_logic_vector(47 downto 0);
      clear_frame_cnt        : out    std_logic;
      self_adpt_en          : out    std_logic;
			 	 host_rd_mode : out STD_LOGIC;
		 host_rd_status : out STD_LOGIC;
		 host_rd_enable : out STD_LOGIC;
		 host_rd_start_addr : out STD_LOGIC_VECTOR(18 DOWNTO 0);
		 host_rd_seg_cnt : out STD_LOGIC_VECTOR(15 DOWNTO 0);
		 host_rd_seg_len : out STD_LOGIC_VECTOR(15 DOWNTO 0);
      cmd_smpl_en_o          : out    std_logic;
      cmd_smpl_depth         : out    std_logic_vector(15 downto 0);
      cmd_smpl_trig_cnt      : out    std_logic_vector(23 downto 0);
      Cmd_demowinln          : out    std_logic_vector(14 downto 0);
      Cmd_demowinstart       : out    std_logic_vector(14 downto 0);
      cmd_ADC_gain_adj       : out    std_logic_vector(18 downto 0);
      cmd_ADC_reconfig       : buffer std_logic;
      cmd_pstprc_num_en      : out    std_logic;
      cmd_Pstprc_num         : out    std_logic_vector(3 downto 0);
      cmd_Pstprc_DPS         : out    std_logic_vector(dds_phase_width downto 0);
      cmd_Estmr_A            : out    std_logic_vector(31 downto 0);
      cmd_Estmr_B            : out    std_logic_vector(31 downto 0);
      cmd_Estmr_C            : out    std_logic_vector(63 downto 0);
      cmd_Estmr_sync_en      : out    std_logic;
      cmd_Estmr_num          : out    std_logic_vector(3 downto 0);
      cmd_Estmr_num_en       : out    std_logic);
  end component command_analysis;

begin

  cmd_ana_rd_data  <= ethernet_rd_data;
  ethernet_Rd_Addr <= rd_addr;
  ethernet_Rd_en   <= rd_en;            --for up
  cmd_ana_rd_addr  <= rd_addr;          -- for down
  cmd_ana_rd_en    <= rd_en;

  command_analysis_1 : entity work.command_analysis
    port map (
      rd_data                => cmd_ana_rd_data,
      rd_clk                 => rd_clk,
      rd_addr                => cmd_ana_rd_addr,
      rd_en                  => cmd_ana_rd_en,
      frm_length             => frm_length,
      frm_type               => frm_type,
      ram_start_o            => ram_start,
      upload_trig_ethernet_o => upload_trig_ethernet,
      rst_n                  => rst_n,
      wait_cnt_set           => wait_cnt_set,
      is_counter             => is_counter,
      clear_frame_cnt             => clear_frame_cnt,
			 host_rd_mode      => host_rd_mode,
	 host_rd_status    => host_rd_status,
	 host_rd_enable    => host_rd_enable,
	 host_rd_start_addr=> host_rd_start_addr,
	 host_rd_seg_cnt   => host_rd_seg_cnt,
	 host_rd_seg_len   => host_rd_seg_len,
      cmd_pstprc_IQ_sw       => cmd_pstprc_IQ_sw,
      TX_dst_MAC_addr        => TX_dst_MAC_addr,
      self_adpt_en          => self_adpt_en,
      cmd_smpl_en_o          => cmd_smpl_en,
      cmd_smpl_depth         => cmd_smpl_depth,
      cmd_smpl_trig_cnt      => cmd_smpl_trig_cnt,
      Cmd_demowinln          => Cmd_demowinln,
      Cmd_demowinstart       => Cmd_demowinstart,
      cmd_ADC_gain_adj       => cmd_ADC_gain_adj,
      cmd_ADC_reconfig       => cmd_ADC_reconfig,
      cmd_pstprc_num_en      => cmd_pstprc_num_en,
      cmd_Pstprc_num         => cmd_Pstprc_num,
      cmd_Pstprc_DPS         => cmd_Pstprc_DPS,
      cmd_Estmr_A            => cmd_Estmr_A,
      cmd_Estmr_B            => cmd_Estmr_B,
      cmd_Estmr_C            => cmd_Estmr_C,
      cmd_Estmr_sync_en      => cmd_Estmr_sync_en,
      cmd_Estmr_num          => cmd_Estmr_num,
      cmd_Estmr_num_en       => cmd_Estmr_num_en);
  -----------------------------------------------------------------------------
  Rd_en_ps : process (rd_clk, rst_n, ethernet_frm_valid, frm_valid_d) is
  begin  -- process Rd_en_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Rd_en <= '0';
    elsif rd_clk'event and rd_clk = '1' then
      if frm_valid_d = '0' and ethernet_frm_valid = '1' then  -- rising clock edge
        Rd_en <= '1';
      elsif Rd_Addr >= x"42" then
        -- elsif ethernet_Rd_Addr>=x"16" then
        Rd_en <= '0';
      end if;
    end if;
  end process Rd_en_ps;

  Rd_Addr_ps : process (rd_clk, rst_n) is
  begin  -- process Rd_Addr_ps
    if rst_n = '0' then                 -- asynchronous reset (  active low)
      Rd_Addr <= (others => '0');
    elsif rd_clk'event and rd_clk = '1' then  -- rising clock edge
      if Rd_Addr <= x"42" and Rd_en = '1'then
        Rd_Addr <= Rd_Addr + 1;
      elsif Rd_en = '0' or Rd_Addr > x"41" then
        Rd_Addr <= (others => '0');
      end if;
    end if;
  end process Rd_Addr_ps;

  frm_valid_d_ps : process (rd_clk, rst_n) is
  begin  -- process frm_vali_dd
    if rd_clk'event and rd_clk = '1' then  -- rising clock edge
      frm_valid_d <= ethernet_frm_valid;
    end if;
  end process frm_valid_d_ps;
-------------------------------------------------------------------------------
end Behavioral;

