----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:14:00 12/07/2016 
-- Design Name: 
-- Module Name:    RAM_top - Behavioral 
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

entity RAM_top is
  port (
    clk_125M            : in  std_logic;
    -- ram_wren            : buffer  std_logic;
    posedge_sample_trig : in  std_logic;
    rst_data_n          : in  std_logic;
    rst_adc_n           : in  std_logic;
    cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
    ---------------------------------------------------------------------------
    ram_Q_dina          : in  std_logic_vector(31 downto 0);
    ram_Q_clka          : in  std_logic;
    ram_Q_clkb          : in  std_logic;
    ram_Q_rden          : in  std_logic;
    ram_Q_doutb         : out std_logic_vector(7 downto 0);
    ram_Q_last          : out std_logic;
    ram_Q_full          : out std_logic;
    ---------------------------------------------------------------------------
    ram_I_dina          : in  std_logic_vector(31 downto 0);
    ram_I_clka          : in  std_logic;
    ram_I_clkb          : in  std_logic;
    ram_I_rden          : in  std_logic;
    ram_I_doutb         : out std_logic_vector(7 downto 0);
    ram_I_last          : out std_logic;
    ram_I_full          : out std_logic
   ---------------------------------------------------------------------------
    );
end RAM_top;

architecture Behavioral of RAM_top is
  signal clr_n_ram    : std_logic;
-------------------------------------------------------------------------------
  signal Gcnt         : std_logic_vector(11 downto 0) := x"000";
  signal clk_div_cnt  : std_logic_vector(7 downto 0)  := x"00";
  signal GCLK         : std_logic;
  signal Gclk_d       : std_logic;
  signal Gclk_d2      : std_logic;
  signal O_Gcnt       : std_logic_vector(7 downto 0)  := x"00";
  constant Div_multi  : std_logic_vector(3 downto 0)  := "1010";
  signal ram_wren     : std_logic;
  signal ram_wren_cnt : std_logic_vector(11 downto 0);
  signal ram_I_dina_d : std_logic_vector(31 downto 0);
  signal ram_Q_dina_d : std_logic_vector(31 downto 0);
  component RAM_I
    port(
      rst_data_n          : in  std_logic;
      rst_adc_n           : in  std_logic;
      ram_wren            : in  std_logic;
      posedge_sample_trig : in  std_logic;
      cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
      ram_I_dina          : in  std_logic_vector(31 downto 0);
      ram_I_clka          : in  std_logic;
      ram_I_clkb          : in  std_logic;
      ram_I_rden          : in  std_logic;
      ram_I_doutb         : out std_logic_vector(7 downto 0);
      ram_I_last          : out std_logic;
      ram_I_full_o        : out std_logic
      );
  end component;
  component RAM_Q
    port(
      ram_wren            : in  std_logic;
      posedge_sample_trig : in  std_logic;
      rst_data_n          : in  std_logic;
      rst_adc_n           : in  std_logic;
      cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
      ram_Q_dina          : in  std_logic_vector(31 downto 0);
      ram_Q_clka          : in  std_logic;
      ram_Q_clkb          : in  std_logic;
      ram_Q_rden          : in  std_logic;
      ram_Q_doutb         : out std_logic_vector(7 downto 0);
      ram_Q_last          : out std_logic;
      ram_Q_full_o        : out std_logic
      );
  end component;


begin

  Inst_RAM_I : RAM_I port map(
    rst_adc_n           => rst_adc_n,
    rst_data_n          => rst_data_n,
    ram_wren            => ram_wren,
    posedge_sample_trig => posedge_sample_trig,
    cmd_smpl_depth      => cmd_smpl_depth,
    ram_I_dina          => ram_I_dina_d,
    ram_I_clka          => ram_I_clka,
    ram_I_clkb          => ram_I_clkb,
    ram_I_rden          => ram_I_rden,
    ram_I_doutb         => ram_I_doutb,
    ram_I_last          => ram_I_last,
    ram_I_full_o        => ram_I_full
    );

  Inst_RAM_Q : RAM_Q port map(
    ram_wren            => ram_wren,
    posedge_sample_trig => posedge_sample_trig,
    rst_adc_n           => rst_adc_n,
    rst_data_n          => rst_data_n,
    cmd_smpl_depth      => cmd_smpl_depth,
    ram_Q_dina          => ram_Q_dina_d,
    ram_Q_clka          => ram_Q_clka,
    ram_Q_clkb          => ram_Q_clkb,
    ram_Q_rden          => ram_Q_rden,
    ram_Q_doutb         => ram_Q_doutb,
    ram_Q_last          => ram_Q_last,
    ram_Q_full_o        => ram_Q_full
    );
  -----------------------------------------------------------------------------
  set_clk_div_cnt : process (ram_Q_clka) is
  begin  -- process set_clk_div_cnt
    -- if rst_n = '0' then                           -- asynchronous reset (active
    --   clk_div_cnt <= x"00";
    if ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
      if clk_div_cnt <= Div_multi then
        clk_div_cnt <= clk_div_cnt+1;
      else
        clk_div_cnt <= x"00";
      end if;
    end if;
  end process set_clk_div_cnt;

  set_ADC_sclk : process (ram_Q_clka) is
  begin  -- process set_ADC_sclk
    if ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
      if clk_div_cnt <= Div_multi(3 downto 1) then
        GCLK <= '0';
      else
        GCLK <= '1';
      end if;
    end if;
  end process set_ADC_sclk;

  Gclk_d_ps : process (ram_Q_clka, rst_adc_n) is
  begin  -- process Gclk_ps
    if rst_adc_n = '0' then
      gclk_d <= '0';
  elsif ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
      GCLK_d <= GCLK;
    end if;
  end process Gclk_d_ps;

  Gclk_d2_ps : process (ram_Q_clka, rst_adc_n) is
  begin  -- process Gclk_d2_ps
    if rst_adc_n = '0' then
      gclk_d2 <= '0';
  elsif ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
      Gclk_d2 <= GCLK_d;
    end if;
end process Gclk_d2_ps;

Gcnt_ps : process (ram_Q_clka, GCLK_d, GCLK_d2, rst_adc_n) is
begin
  if rst_adc_n = '0' then
    gcnt <= (others => '0');
  elsif ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
    if Gclk_d2 = '0' and Gclk_d = '1' then
      -- elsif GCLK'event and GCLK = '1' then
-- if Gcnt <= x"ffffffff" then
      Gcnt <= Gcnt+1;
    end if;
  end if;
-- end if; 
end process Gcnt_ps;



O_Gcnt_ps : process (ram_Q_clka, rst_adc_n, GCLK_d, GCLK_d2) is
begin  -- process O_Gcnt_ps
  if rst_adc_n = '0' then
    O_Gcnt <= (others => '0');
  elsif ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
    if Gclk_d2 = '0' and Gclk_d = '1' then
      -- elsif GCLK'event and GCLK = '1' then
      if Gcnt = x"ffff" and O_Gcnt <= x"F5" then
        O_Gcnt <= O_Gcnt+1;
      else
        O_Gcnt <= (others => '0');
      end if;
    end if;
  end if;
end process O_Gcnt_ps;
-------------------------------------------------------------------------------  
ram_wren_ps : process (ram_Q_clka, rst_adc_n) is
begin  -- process ram_wren_ps
  if rst_adc_n = '0' then               -- asynchronous reset (active low)
    ram_wren <= '0';
  elsif ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
    if ram_wren_cnt = x"3e1" then
      ram_wren <= '0';
    elsif posedge_sample_trig = '1' then
      ram_wren <= '1';
    end if;
  end if;
end process ram_wren_ps;

ram_wren_cnt_ps : process (ram_Q_clka, rst_adc_n) is
begin  -- process ram_wren_cnt_ps
  if rst_adc_n = '0' then               -- asynchronous reset (active low)
    ram_wren_cnt <= (others => '0');
  elsif ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
    if ram_wren = '0' then
      ram_wren_cnt <= (others => '0');
    elsif ram_wren = '1' then
      if Gclk_d2 = '0' and Gclk_d = '1' then
        ram_wren_cnt <= ram_wren_cnt+1;
      end if;
    end if;
  end if;
end process ram_wren_cnt_ps;
-----------------------------------------------------------------------------
ram_I_dina_d_ts : process (ram_Q_clka, rst_adc_n) is
begin  -- process ram_I_dina_d_ts
  if rst_adc_n = '0' then               -- asynchronous reset (active low)
    ram_I_dina_d <= (others => '0');
  elsif ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
    ram_I_dina_d <= ram_I_dina;
  end if;
end process ram_I_dina_d_ts;

ram_Q_dina_d_ts : process (ram_Q_clka, rst_adc_n) is
begin  -- process ram_I_dina_d_ts
  if rst_adc_n = '0' then               -- asynchronous reset (active low)
    ram_Q_dina_d <= (others => '0');
  elsif ram_Q_clka'event and ram_Q_clka = '1' then  -- rising clock edge
    ram_Q_dina_d <= ram_Q_dina;
  end if;
end process ram_Q_dina_d_ts;
-----------------------------------------------------------------------------
end Behavioral;

