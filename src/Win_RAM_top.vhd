----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:04:37 03/08/2017 
-- Design Name: 
-- Module Name:    Win_RAM_top - Behavioral 
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

entity Win_RAM_top is
  port(
    posedge_sample_trig   : in     std_logic;
    rst_adc_n             : in     std_logic;
    rst_data_proc_n       : in     std_logic;
    use_test_IQ_data      : in     std_logic;
    cmd_smpl_depth        : in     std_logic_vector(15 downto 0);
    ---------------------------------------------------------------------------
    Pstprc_RAMq_dina      : in     std_logic_vector(31 downto 0);
    Pstprc_RAMq_clka      : in     std_logic;
    Pstprc_RAMq_clkb      : in     std_logic;
    Pstprc_RAMq_doutb     : out    std_logic_vector(63 downto 0);
    Pstprc_RAMq_rden      : buffer std_logic;
    Pstprc_RAMq_rden_stp  : out    std_logic;
    ---------------------------------------------------------------------------
    Pstprc_RAMI_dina      : in     std_logic_vector(31 downto 0);
    Pstprc_RAMi_clka      : in     std_logic;
    Pstprc_RAMi_clkb      : in     std_logic;
    Pstprc_RAMI_doutb     : out    std_logic_vector(63 downto 0);
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    ini_pstprc_RAMx_addra : in     std_logic_vector(12 downto 0);
    ini_pstprc_RAMx_addrb : in     std_logic_vector(11 downto 0);
    Pstprc_RAMx_rden_ln   : in     std_logic_vector(11 downto 0)
    );
end Win_RAM_top;

architecture Behavioral of Win_RAM_top is

  -----------------------------------------------------------------------------

  signal Pstprc_RAMx_addra    : std_logic_vector(12 downto 0);
  signal Pstprc_RAMx_addrb    : std_logic_vector(11 downto 0);
  signal Pstprc_RAMx_ena      : std_logic;
  signal Pstprc_RAMx_enb      : std_logic;
  signal Pstprc_RAMx_wea      : std_logic_vector(0 downto 0);
  signal Pstprc_RAMx_rstb     : std_logic;
  signal clr_n_ram            : std_logic;
  signal Pstprc_RAMx_full     : std_logic;
  signal posedge_sample_trig_d1   : std_logic;
  signal posedge_sample_trig_d2   : std_logic;
  signal posedge_sample_trig_r   : std_logic;
  signal Pstprc_addra_rdy_i   : std_logic;
  signal Pstprc_addra_rdy_q   : std_logic;
  signal Pstprc_addra_rdy_lch   : std_logic;
  signal Pstprc_addra_ok      : std_logic;
  signal Pstprc_RAMx_rden_cnt : std_logic_vector(11 downto 0);
  signal pstprc_rami_rden_d   : std_logic;
  signal Pstprc_RAMq_rden_d   : std_logic;
  signal pstprc_ram_wren      : std_logic;
  signal pstprc_ram_wren_cnt  : std_logic_vector(12 downto 0);
  signal test_IQ_data         : std_logic_vector(31 downto 0);
  signal Pstprc_RAMq_dina_d   : std_logic_vector(31 downto 0);
  signal Pstprc_RAMi_dina_d   : std_logic_vector(31 downto 0);
  -----------------------------------------------------------------------------
  signal Gcnt                 : std_logic_vector(11 downto 0) := x"000";
  signal clk_div_cnt          : std_logic_vector(7 downto 0)  := x"00";
  signal GCLK                 : std_logic;
  signal Gclk_d               : std_logic;
  signal Gclk_d2              : std_logic;
  signal O_Gcnt               : std_logic_vector(7 downto 0)  := x"00";
  constant Div_multi          : std_logic_vector(3 downto 0)  := "1010";
  -----------------------------------------------------------------------------
  component Pstprc_RAM_Q
    port(
      Pstprc_ram_wren       : in     std_logic;
--      posedge_sample_trig   : in     std_logic;
      rst_data_proc_n            : in     std_logic;
      rst_adc_n             : in     std_logic;
		Pstprc_addra_ok             : in     std_logic;
		Pstprc_addra_rdy             : out     std_logic;
--      cmd_smpl_depth        : in     std_logic_vector(15 downto 0);
      Pstprc_RAMq_clka      : in     std_logic;
      Pstprc_RAMq_clkb      : in     std_logic;
      Pstprc_RAMq_addra     : in     std_logic_vector(12 downto 0);
      Pstprc_RAMq_dina      : in     std_logic_vector(31 downto 0);
      ini_pstprc_RAMx_addra : in     std_logic_vector(12 downto 0);
      ini_pstprc_RAMx_addrb : in     std_logic_vector(11 downto 0);
      Pstprc_RAMx_rden_ln   : in     std_logic_vector(11 downto 0);
      Pstprc_RAMq_doutb     : out    std_logic_vector(63 downto 0);
      Pstprc_RAMq_rden      : buffer std_logic;
      Pstprc_RAMq_rden_stp  : out    std_logic
      );
  end component;

--  component Pstprc_RAM_I
--    port(
--      Pstprc_ram_wren       : in  std_logic;
--      posedge_sample_trig   : in  std_logic;
--      rst_data_proc_n            : in  std_logic;
--      rst_adc_n             : in  std_logic;
--      cmd_smpl_depth        : in  std_logic_vector(15 downto 0);
--      Pstprc_RAMi_clka      : in  std_logic;
--      Pstprc_RAMi_clkb      : in  std_logic;
--      Pstprc_RAMi_dina      : in  std_logic_vector(31 downto 0);
--      ini_pstprc_RAMx_addra : in  std_logic_vector(12 downto 0);
--      ini_pstprc_RAMx_addrb : in  std_logic_vector(11 downto 0);
--      Pstprc_RAMx_rden_ln   : in  std_logic_vector(11 downto 0);
--      Pstprc_RAMi_doutb     : out std_logic_vector(63 downto 0)
--      );
--  end component;
-----------------------------------------------------------------------------
begin


  Inst_Pstprc_RAM_Q : Pstprc_RAM_Q port map(
    Pstprc_ram_wren       => Pstprc_ram_wren,
--    posedge_sample_trig   => posedge_sample_trig,
    rst_adc_n             => rst_adc_n,
    rst_data_proc_n       => rst_data_proc_n,
    Pstprc_addra_ok       => Pstprc_addra_ok,
    Pstprc_addra_rdy       => Pstprc_addra_rdy_q,
    Pstprc_RAMq_addra     => Pstprc_RAMx_addra,
    Pstprc_RAMq_clka      => Pstprc_RAMq_clka,
    Pstprc_RAMq_clkb      => Pstprc_RAMq_clkb,
    Pstprc_RAMq_dina      => Pstprc_RAMq_dina_d,
    Pstprc_RAMq_doutb     => Pstprc_RAMq_doutb,
    ini_pstprc_RAMx_addra => ini_pstprc_RAMx_addra,
    ini_pstprc_RAMx_addrb => ini_pstprc_RAMx_addrb,
    Pstprc_RAMx_rden_ln   => Pstprc_RAMx_rden_ln,
    Pstprc_RAMq_rden      => Pstprc_RAMq_rden,
    Pstprc_RAMq_rden_stp  => Pstprc_RAMq_rden_stp
    );


  Inst_Pstprc_RAM_I : Pstprc_RAM_Q port map(
    Pstprc_ram_wren       => Pstprc_ram_wren,
--    posedge_sample_trig   => posedge_sample_trig,
    rst_adc_n             => rst_adc_n,
    Pstprc_addra_ok       => Pstprc_addra_ok,
    Pstprc_addra_rdy       => Pstprc_addra_rdy_i,
    rst_data_proc_n       => rst_data_proc_n,
    Pstprc_RAMq_addra     => Pstprc_RAMx_addra,
    Pstprc_RAMq_clka      => Pstprc_RAMi_clka,
    Pstprc_RAMq_clkb      => Pstprc_RAMi_clkb,
    Pstprc_RAMq_dina      => Pstprc_RAMi_dina_d,
    Pstprc_RAMq_doutb     => Pstprc_RAMi_doutb,
    ini_pstprc_RAMx_addra => ini_pstprc_RAMx_addra,
    ini_pstprc_RAMx_addrb => ini_pstprc_RAMx_addrb,
    Pstprc_RAMx_rden_ln   => Pstprc_RAMx_rden_ln,
    Pstprc_RAMq_rden_stp  => open,
    Pstprc_RAMq_rden  => open
    );
  test_IQ_data(1  downto  0) <= "00";
  test_IQ_data(9  downto  8) <= "01";
  test_IQ_data(17 downto 16) <= "10";
  test_IQ_data(25 downto 24) <= "11";
  test_IQ_data(7  downto  2) <= pstprc_ram_wren_cnt(5 downto 0);
  test_IQ_data(15 downto 10) <= pstprc_ram_wren_cnt(5 downto 0);
  test_IQ_data(23 downto 18) <= pstprc_ram_wren_cnt(5 downto 0);
  test_IQ_data(31 downto 26) <= pstprc_ram_wren_cnt(5 downto 0);
  
  
  pstprc_RAMi_dina_ts : process (Pstprc_RAMq_clka, rst_adc_n) is
  begin  -- process pstprc_RAMi_dina
    if rst_adc_n = '0' then             -- asynchronous reset (active low)
      pstprc_RAMi_dina_d <= (others => '0');
    elsif Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
		if(use_test_IQ_data = '1') then
			pstprc_RAMi_dina_d <= test_IQ_data;
		else
			pstprc_RAMi_dina_d <= pstprc_RAMi_dina;
		end if;
    end if;
  end process pstprc_RAMi_dina_ts;

  pstprc_RAMq_dina_ts : process (Pstprc_RAMq_clka, rst_adc_n) is
  begin  -- process pstprc_Ramq_dina
    if rst_adc_n = '0' then             -- asynchronous reset (active low)
      pstprc_Ramq_dina_d <= (others => '0');
    elsif Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
      if(use_test_IQ_data = '1') then
			pstprc_Ramq_dina_d <= test_IQ_data;
		else
			pstprc_Ramq_dina_d <= pstprc_Ramq_dina;
		end if;
    end if;
  end process pstprc_Ramq_dina_ts;
-------------------------------------------------------------------------------  
--  set_clk_div_cnt : process (Pstprc_RAMq_clka) is
--  begin  -- process set_clk_div_cnt
--    -- if rst_n = '0' then                           -- asynchronous reset (active
--    --   clk_div_cnt <= x"00";
--    if Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
--      if clk_div_cnt <= Div_multi then
--        clk_div_cnt <= clk_div_cnt+1;
--      else
--        clk_div_cnt <= x"00";
--      end if;
--    end if;
--  end process set_clk_div_cnt;
--
--  set_ADC_sclk : process (Pstprc_RAMq_clka) is
--  begin  -- process set_ADC_sclk
--    if Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
--      if clk_div_cnt <= Div_multi(3 downto 1) then
--        GCLK <= '0';
--      else
--        GCLK <= '1';
--      end if;
--    end if;
--  end process set_ADC_sclk;
--
--  Gclk_d_ps : process (Pstprc_RAMq_clka, rst_adc_n) is
--  begin  -- process Gclk_ps
--    if rst_adc_n = '0' then
--      gclk_d <= '0';
--  elsif Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
--      GCLK_d <= GCLK;
--    end if;
--  end process Gclk_d_ps;
--
--  Gclk_d2_ps : process (Pstprc_RAMq_clka, rst_adc_n) is
--  begin  -- process Gclk_d2_ps
--    if rst_adc_n = '0' then
--      gclk_d2 <= '0';
--  elsif Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
--      Gclk_d2 <= GCLK_d;
--    end if;
--end process Gclk_d2_ps;
--
--Gcnt_ps : process (Pstprc_RAMq_clka, GCLK_d, GCLK_d2, rst_adc_n) is
--begin
--  if rst_adc_n = '0' then
--    gcnt <= (others => '0');
--  elsif Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
--    if Gclk_d2 = '0' and Gclk_d = '1' then
--      -- elsif GCLK'event and GCLK = '1' then
---- if Gcnt <= x"ffffffff" then
--      Gcnt <= Gcnt+1;
--    end if;
--  end if;
---- end if; 
--end process Gcnt_ps;
--
--
--
--O_Gcnt_ps : process (Pstprc_RAMq_clka, rst_adc_n, GCLK_d, GCLK_d2) is
--begin  -- process O_Gcnt_ps
--  if rst_adc_n = '0' then
--    O_Gcnt <= (others => '0');
--  elsif Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
--    if Gclk_d2 = '0' and Gclk_d = '1' then
--      -- elsif GCLK'event and GCLK = '1' then
--      if Gcnt = x"ffff" and O_Gcnt <= x"F5" then
--        O_Gcnt <= O_Gcnt+1;
--      else
--        O_Gcnt <= (others => '0');
--      end if;
--    end if;
--  end if;
--end process O_Gcnt_ps;

process (Pstprc_RAMq_clka) is begin
	if Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then
		posedge_sample_trig_d1 <= posedge_sample_trig;
		posedge_sample_trig_d2 <= posedge_sample_trig_d1;
	end if;
end process;
posedge_sample_trig_r <= not posedge_sample_trig_d2 and posedge_sample_trig_d1;

Pstprc_RAMx_addra <= pstprc_ram_wren_cnt;
pstprc_ram_wren_ps : process (Pstprc_RAMq_clka, rst_adc_n) is
begin  -- process pstprc_ram_wren_ps
  if rst_adc_n = '0' then               -- asynchronous reset (active low)
    pstprc_ram_wren <= '0';
  elsif Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
	 --cmd_smpl_depth是以采样点为单位, 写入是以4个采样点为单位，所以计数判断要考虑这个关系
    if posedge_sample_trig_r = '1' then
      pstprc_ram_wren <= '1';
    elsif pstprc_ram_wren_cnt = cmd_smpl_depth(14 downto 2) then
      pstprc_ram_wren <= '0';
    end if;
  end if;
end process pstprc_ram_wren_ps;

pstprc_ram_wren_cnt_ps : process (Pstprc_RAMq_clka, rst_adc_n) is
begin  -- process pstprc_ram_wren_cnt_ps
  if rst_adc_n = '0' then               -- asynchronous reset (active low)
    pstprc_ram_wren_cnt <= (others => '1');
  elsif Pstprc_RAMq_clka'event and Pstprc_RAMq_clka = '1' then  -- rising clock edge
    if pstprc_ram_wren = '0' then
        pstprc_ram_wren_cnt <= (others => '0');
    else
        pstprc_ram_wren_cnt <= pstprc_ram_wren_cnt+1;
    end if;
  end if;
end process pstprc_ram_wren_cnt_ps;

----ram 读取控制，由于原有逻辑是通过判断250MHz时钟域的数据ready信号，有可能造成跨时钟域的处理不一致，为了保持一致，只处理其中一路信号，处理后的信号再送回两个模块做读取判断，这样能保持一致
--注意 此处有跨时钟域处理
  process (Pstprc_RAMi_clka) is
  begin  -- process SRCC1_p_trigin_d_ps
    if Pstprc_RAMi_clka'event and Pstprc_RAMi_clka = '1' then  -- rising clock edge
       if(Pstprc_addra_rdy_q = '1' and Pstprc_addra_rdy_i = '1') then
			Pstprc_addra_rdy_lch	<= '1';
		 elsif Pstprc_addra_ok = '1' then
		   Pstprc_addra_rdy_lch	<= '0';
		 end if;
    end if;
  end process;  --period for 125MHz
 process (Pstprc_RAMi_clkb) is
  begin  -- process SRCC1_p_trigin_d_ps
    if Pstprc_RAMi_clkb'event and Pstprc_RAMi_clkb = '1' then  -- rising clock edge
       Pstprc_addra_ok	<= Pstprc_addra_rdy_lch;
    end if;
  end process;

end Behavioral;

