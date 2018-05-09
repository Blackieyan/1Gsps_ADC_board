----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:44:12 03/28/2018 
-- Design Name: 
-- Module Name:    Estimator - Behavioral 
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
use IEEE.STD_LOGIC_1164.all;
-- use IEEE.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Estimator is
  port(
    clk            : in  std_logic;     --clk250M
    rst_n          : in  std_logic;
    A              : in  std_logic_vector(31 downto 0);
    B              : in  std_logic_vector(31 downto 0);
    C              : in  std_logic_vector(63 downto 0);
    en             : in  std_logic;
    I              : in  std_logic_vector(31 downto 0);
    Q              : in  std_logic_vector(31 downto 0);
    Pstprc_add_stp : in  std_logic;
    state          : out std_logic_vector(1 downto 0);
    stat_rdy       : out std_logic
    );
end Estimator;

architecture Behavioral of Estimator is

  signal pstprc_add_stp_d  : std_logic;
  signal pstprc_add_stp_d2 : std_logic;
  signal mult_ce           : std_logic;
  signal add_ce            : std_logic;
  signal Estmr_Q           : std_logic_vector(31 downto 0);
  signal Estmr_I           : std_logic_vector(31 downto 0);
  signal sum               : std_logic_vector(63 downto 0);
  signal mult_rst          : std_logic;
  signal add_rst : std_logic;
  signal A_x_EstmrI : std_logic_vector(63 downto 0);
  signal B_x_EstmrQ : std_logic_vector(63 downto 0);
  signal stat_prerdy : std_logic;
  signal stat_prerdy_cnt : std_logic_vector(3 downto 0);
  component multiplier
    port (
      clk  : in  std_logic;
      a    : in  std_logic_vector(31 downto 0);
      b    : in  std_logic_vector(31 downto 0);
      ce   : in  std_logic;
      sclr : in  std_logic;
      p    : out std_logic_vector(63 downto 0)
      );
  end component;

  component adder64
    port (
      a    : in  std_logic_vector(62 downto 0);
      b    : in  std_logic_vector(62 downto 0);
      clk  : in  std_logic;
      ce   : in  std_logic;
      add : in std_logic;
      sclr : in  std_logic;
      s    : out std_logic_vector(63 downto 0)
      );
  end component;
-------------------------------------------------------------------------------
begin
  -- purpose: 跨时钟域打两拍处理
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: 
  pstprc_add_stp_d_ps : process (clk, rst_n) is
  begin  -- process pstprc_add_stp_d_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      pstprc_add_stp_d  <= '0';
      pstprc_add_stp_d2 <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
        pstprc_add_stp_d2 <= pstprc_add_stp_d;
        pstprc_add_stp_d  <= pstprc_add_stp;
        mult_ce           <= pstprc_add_stp_d2;
        add_ce            <= mult_ce;
      end if;
  end process pstprc_add_stp_d_ps;

-- purpose: position the Estmr_I and Estmr_Q
-- type   : sequential
-- inputs : clk, rst_n
  Estmr_I_ps : process (clk, rst_n) is
  begin  -- process Estmr_I_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Estmr_I <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if Pstprc_add_stp_d2 = '1' then
      Estmr_I <= I;
    else
      Estmr_I <= Estmr_I;
    end if;
  end if;
end process Estmr_I_ps;


-- purpose: position the Estmr_I and Estmr_Q
-- type   : sequential
-- inputs : clk, rst_n
Estmr_Q_ps : process (clk, rst_n) is
begin  -- process Estmr_Q_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    Estmr_Q <= (others => '0');
  elsif clk'event and clk = '1' then    -- rising clock edge
    if Pstprc_add_stp_d2 = '1' then
      Estmr_Q <= Q;
  else
    Estmr_Q <= Estmr_Q;
  end if;
end if;
end process Estmr_Q_ps;


A_x_EstmrI_inst : multiplier
  port map (
    clk  => clk,
    a    => Estmr_I,
    b    => A,
    ce   => mult_ce,
    sclr => mult_rst,
    p    => A_x_EstmrI
    );

B_x_EstmrQ_inst : multiplier
  port map (
    clk  => clk,
    a    => Estmr_Q,
    b    => B,
    ce   => mult_ce,
    sclr => mult_rst,
    p    => B_x_EstmrQ
    );

A_x_EstmrI_add_B_x_EstmrQ_inst : adder64
  port map (
    a    => B_x_EstmrQ(63 downto 1),
    b    => A_x_EstmrI(63 downto 1),
    clk  => clk,
    add  => '1',
    ce   => ADD_CE,
    sclr => ADD_RST,
    s    => sum);                       --2 clk delay


-- EQ_COMPARE_MACRO_inst : EQ_COMPARE_MACRO
-- generic map (
--    DEVICE => "VIRTEX6",         -- Target Device: "VIRTEX5", "VIRTEX6" 
--    LATENCY => 1,                -- Desired clock cycle latency, 0-2
--    MASK => X"000000000000",     -- Select bits to be masked, must set 
--                                 -- SEL_MASK = "MASK" 
--    SEL_MASK => "MASK",          -- "MASK" = use MASK generic,
--                                 -- "DYNAMIC_PATTERN = use DYNAMIC_PATTERN input bus
--    SEL_PATTERN => "DYNAMIC_PATTERN", -- "DYNAMIC_PATTERN" = use DYNAMIC_PATTERN input bus
--                                      -- "STATIC_PATTERN" = use STATIC_PATTERN generic
--    STATIC_PATTERN => X"000000000000", -- Specify static pattern, 
--                                       -- must set SEL_PATTERN = "STATIC_PATTERN
--    WIDTH => 48)            -- Comparator output bus width, 1-48
-- port map (
--    Q => Q,        -- 1-bit output indicating a match 
--    CE => CE,      -- 1-bit active high input clock enable input
--    CLK => CLK,    -- 1-bit positive edge clock input
--    DATA_IN => sum(65 downto 18), -- Input Data Bus, width determined by WIDTH generic
--    DYNAMIC_PATTERN, => DYNAMIC_PATTERN, -- Input Dynamic Match/Mask Bus, width determined by WIDTH generic
--    RST => RST       -- 1-bit input active high reset
-- );

-- purpose: compare between C and sum
-- type   : sequential
-- inputs : clk, rst_n
-- outputs: state
comparator_ps : process (clk, rst_n) is
begin  -- process comparator_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    state <= "11";
  elsif clk'event and clk = '1' then    -- rising clock edge
    if stat_prerdy ='1' then
      if signed(sum) <= signed(C) then
        state <= "00";
      else
        state <= "01";
      end if;
    else
      state<="11";
    end if;
  end if;
end process comparator_ps;

stat_prerdy_ps: process (clk, rst_n) is
begin  -- process stat_prerdy_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    stat_prerdy<='0';
  elsif clk'event and clk = '1' then    -- rising clock edge
    if stat_prerdy_cnt=x"4" then
      stat_prerdy<='0';
    elsif Pstprc_add_stp_d='0' and Pstprc_add_stp_d2 ='1' then
      stat_prerdy<='1';
    end if;
  end if;
end process stat_prerdy_ps;

stat_prerdy_cnt_ps: process (clk, rst_n) is
begin  -- process stat_prerdy_cnt_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    stat_prerdy_cnt<=(others => '0');
  elsif clk'event and clk = '1' then    -- rising clock edge
    if stat_prerdy ='1' then
      stat_prerdy_cnt<=stat_prerdy_cnt+1;
    elsif stat_prerdy='0' then
      stat_prerdy_cnt<=(others => '0');
    end if;
  end if;
end process stat_prerdy_cnt_ps;

stat_rdy_ps: process (clk, rst_n) is
begin  -- process stat_rdy_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    stat_rdy<='0';
  elsif clk'event and clk = '1' then    -- rising clock edge
    stat_rdy<=stat_prerdy;
  end if;
end process stat_rdy_ps;

  mult_rst<=not rst_n;
  add_rst<=not rst_n;
  
  end Behavioral;

