--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:15:30 12/11/2015
-- Design Name:   
-- Module Name:   Y:/Documents/projects/ZJUprojects/ZJUproject/ZJUprojects_TB.vhd
-- Project Name:  ZJUproject
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ZJUprojects
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

entity ZJUprojects_TB is
end ZJUprojects_TB;

architecture behavior of ZJUprojects_TB is

  -- Component Declaration for the Unit Under Test (UUT)

  component ZJUprojects
    port(
      OSC_in_n        : in  std_logic;
      OSC_in_p        : in  std_logic;
      ADC_Mode        : out std_logic;
      ADC_sclk_OUT    : out std_logic;
      ADC_sldn_OUT    : out std_logic;
      ADC_sdata       : out std_logic_vector(0 downto 0);
      spi_clk         : out std_logic;
      spi_le          : out std_logic;
      spi_syn         : out std_logic;
      spi_mosi        : out std_logic;
      spi_miso        : in  std_logic;
      spi_powerdn     : inout std_logic;
      spi_revdata     : out std_logic_vector(31 downto 0);
      cfg_finish      : out std_logic;
      -------------------------------------------------------------------------
      test            : out std_logic_vector(0 downto 0);
      user_pushbutton : in  std_logic;  --glbclr_n
      -------------------------------------------------------------------------
      ADC_CLKOI_p     : in  std_logic;  -- ADC CLKOI 500MHz/250MHz
      ADC_CLKOI_n     : in  std_logic;
      ADC_CLKOQ_p     : in  std_logic;
      ADC_CLKOQ_n     : in  std_logic;
      ADC_DOIA_p      : in  std_logic_vector(7 downto 0);
      ADC_DOIA_n      : in  std_logic_vector(7 downto 0);
      ADC_DOIB_p      : in  std_logic_vector(7 downto 0);
      ADC_DOIB_n      : in  std_logic_vector(7 downto 0);
      ADC_DOQA_p      : in  std_logic_vector(7 downto 0);
      ADC_DOQA_n      : in  std_logic_vector(7 downto 0);
      ADC_DOQB_p      : in  std_logic_vector(7 downto 0);
      ADC_DOQB_n      : in  std_logic_vector(7 downto 0);
      DOIRI_p         : in  std_logic;
      DOIRI_n         : in  std_logic;
      DOIRQ_p         : in  std_logic;
      DOIRQ_n         : in  std_logic;
      GHz_in_p        : in  std_logic;
      GHz_in_n        : in  std_logic;
      SRCC1_p_trigin         : in std_logic;
      SRCC1_n_upload_sma_trigin  : in    std_logic;
      MRCC2_p         : out std_logic;
      MRCC2_n         : out std_logic_vector(0 downto 0);
      -------------------------------------------------------------------------
      -- ethernet_Rd_clk    : in     std_logic;
      -- ethernet_Rd_en     : in     std_logic;
      -- ethernet_Rd_Addr   : in     std_logic_vector(13 downto 0);
      PHY_RXD         : in  std_logic_vector(3 downto 0);
      PHY_RXC         : in  std_logic;
      PHY_RXDV        : in  std_logic;
      PHY_TXD_o       : out std_logic_vector(3 downto 0);
      PHY_GTXclk_quar : out std_logic;
      PHy_txen_quar   : out std_logic;
      phy_txer_o      : out std_logic;
      -- ethernet_Rd_data   : out    std_logic_vector(7 downto 0);
      -- ethernet_Frm_valid : out    std_logic;
      phy_rst_n_o     : out std_logic
      );
  end component;


  --Inputs


  --Outputs
  signal ADC_Mode           : std_logic;
  signal ADC_sclk_OUT       : std_logic;
  signal ADC_sldn_OUT       : std_logic;
  signal ADC_sdata          : std_logic_vector(0 downto 0);
  signal spi_clk            : std_logic;
  signal spi_le             : std_logic;
  signal spi_syn            : std_logic;
  signal spi_mosi           : std_logic;
  signal spi_miso           : std_logic;
  signal spi_powerdn        : std_logic;
  signal spi_revdata        : std_logic_vector(31 downto 0);
  signal cfg_finish         : std_logic;
  signal test               : std_logic_vector(0 downto 0);
  signal OSC_in_p           : std_logic;
  signal OSC_in_n           : std_logic;
  signal GHz_in_p           : std_logic                    := '1';
  signal GHz_in_n           : std_logic                    := '0';
  -----------------------------------------------------------------------------
  signal ADC_CLKOI_p        : std_logic;  -- ADC CLKOI 500MHz/250MHz
  signal ADC_CLKOI_n        : std_logic;
  signal ADC_CLKOQ_p        : std_logic;
  signal ADC_CLKOQ_n        : std_logic;
  signal ADC_DOIA_p         : std_logic_vector(7 downto 0);
  signal ADC_DOIA_n         : std_logic_vector(7 downto 0);
  signal ADC_DOIB_p         : std_logic_vector(7 downto 0);
  signal ADC_DOIB_n         : std_logic_vector(7 downto 0);
  signal ADC_DOQA_p         : std_logic_vector(7 downto 0);
  signal ADC_DOQA_n         : std_logic_vector(7 downto 0);
  signal ADC_DOQB_p         : std_logic_vector(7 downto 0);
  signal ADC_DOQB_n         : std_logic_vector(7 downto 0);
  signal DOIRI_p            : std_logic                    := '1';
  signal DOIRI_n            : std_logic                    := '0';
  signal DOIRQ_p            : std_logic                    := '1';
  signal DOIRQ_n            : std_logic                    := '0';
  -----------------------------------------------------------------------------
  signal CLK_500M           : std_logic;  -- to simulate the ADC_DOQ
  signal rst                : std_logic;
  signal SRCC1_p_trigin            : std_logic :='0';
  -- signal ethernet_Rd_clk    : std_logic:='0';
  -- signal ethernet_Rd_en     : std_logic:='0';
  -- signal ethernet_Rd_Addr   : std_logic_vector(13 downto 0):=x"fff"&"11";
  signal PHY_RXD            : std_logic_vector(3 downto 0) := x"0";
  signal PHY_RXC            : std_logic;
  signal PHY_RXDV           : std_logic                    := '0';
  signal PHY_TXD_o          : std_logic_vector(3 downto 0);
  signal PHY_GTXclk_quar    : std_logic;
  signal PHY_txen_quar      : std_logic;
  signal phy_txer_o         : std_logic;
  -- signal ethernet_Rd_data   : std_logic_vector(7 downto 0) := x"00";
  -- signal ethernet_Frm_valid : std_logic                    := '0';
  signal phy_rst_n_o        : std_logic;
  signal user_pushbutton    : std_logic;
  signal rd_data : std_ulogic_vector(7 downto 0) := x"00";
  -- Clock period definitions
  constant OSC_in_p_period    : time := 12.5 ns;
  constant OSC_in_n_period    : time := 12.5 ns;
  constant ADC_CLKOQ_p_period : time := 4 ns;
    constant ADC_CLKOi_p_period : time := 4 ns;
  constant CLK_500M_period    : time := 2 ns;
  constant phy_rxc_period     : time := 8 ns;
  signal MRCC2_p              : std_logic;
  signal MRCC2_n              : std_logic_vector(0 downto 0);
  signal SRCC1_n_upload_sma_trigin              : std_logic := '0'; 
begin

  -- Instantiate the Unit Under Test (UUT)

  Inst_ZJUprojects : ZJUprojects port map(
    OSC_in_n        => OSC_in_n,
    OSC_in_p        => OSC_in_p,
    GHz_in_n        => GHz_in_n,
    GHz_in_p        => GHz_in_p,
    ADC_Mode        => ADC_Mode,
    ADC_sclk_OUT    => ADC_sclk_OUT,
    ADC_sldn_OUT    => ADC_sldn_OUT,
    ADC_sdata       => ADC_sdata,
    spi_clk         => spi_clk,
    spi_mosi        => spi_mosi,
    spi_le          => spi_le,
    spi_syn         => spi_syn,
    spi_miso        => spi_miso,
    spi_powerdn     => spi_powerdn,
    spi_revdata     => spi_revdata,
    cfg_finish      => cfg_finish,
    test            => test,
    user_pushbutton => user_pushbutton,
    ADC_CLKOI_p     => ADC_CLKOI_p,
    ADC_CLKOI_n     => ADC_CLKOI_n,
    ADC_CLKOQ_p     => ADC_CLKOQ_p,
    ADC_CLKOQ_n     => ADC_CLKOQ_n,
    ADC_DOIA_p      => ADC_DOIA_p,
    ADC_DOIA_n      => ADC_DOIA_n,
    ADC_DOIB_p      => ADC_DOIB_p,
    ADC_DOIB_n      => ADC_DOIB_n,
    ADC_DOQA_p      => ADC_DOQA_p,
    ADC_DOQA_n      => ADC_DOQA_n,
    ADC_DOQB_p      => ADC_DOQB_p,
    ADC_DOQB_n      => ADC_DOQB_n,
    DOIRI_p         => DOIRI_p,
    DOIRI_n         => DOIRI_n,
    DOIRQ_p         => DOIRQ_p,
    DOIRQ_n         => DOIRQ_n,
    SRCC1_p_trigin         => SRCC1_p_trigin,
    SRCC1_n_upload_sma_trigin        => SRCC1_n_upload_sma_trigin,
    MRCC2_p         => MRCC2_p,
    MRCC2_n         => MRCC2_n,
    -- ethernet_Rd_clk    => ethernet_Rd_clk,
    -- ethernet_Rd_en     => ethernet_Rd_en,
    -- ethernet_Rd_Addr   => ethernet_Rd_Addr,
    PHY_RXD         => PHY_RXD,
    PHY_RXC         => PHY_RXC,
    PHY_RXDV        => PHY_RXDV,
    PHY_TXD_o       => PHY_TXD_o,
    PHY_GTXclk_quar => PHY_GTXclk_quar,
    PHy_txen_quar   => PHy_txen_quar,
    phy_txer_o      => phy_txer_o,
    -- ethernet_Rd_data   => ethernet_Rd_data,
    -- ethernet_Frm_valid => ethernet_Frm_valid,
    phy_rst_n_o     => phy_rst_n_o
    );
-------------------------------------------------------------------------------
  -- Clock process definitions
  spi_clk_process : process
  begin
    OSC_in_p <= '0';
    OSC_in_n <= '1';
    wait for OSC_in_p_period/2;
    OSC_in_p <= '1';
    OSC_in_n <= '0';
    wait for OSC_in_p_period/2;
  end process;

  CLK_OQ_process : process
  begin
    ADC_CLKOQ_p <= '0';
    ADC_CLKOQ_n <= '1';
    wait for ADC_CLKOQ_p_period/2;
    ADC_CLKOQ_p <= '1';
    ADC_CLKOQ_n <= '0';
    wait for ADC_CLKOQ_p_period/2;
  end process;  -- CLKOQ_p;

    CLK_Oi_process : process
  begin
    ADC_CLKOi_p <= '0';
    ADC_CLKOi_n <= '1';
    wait for ADC_CLKOi_p_period/2;
    ADC_CLKOi_p <= '1';
    ADC_CLKOi_n <= '0';
    wait for ADC_CLKOi_p_period/2;
  end process;  -- CLKOi_p;

  CLK_500M_process : process
  begin
    CLK_500M <= '0';
    wait for CLK_500M_period/2;
    CLK_500M <= '1';
    wait for CLK_500M_period/2;
  end process;  -- CLK_500M;

  phy_rxc_process : process
  begin
    phy_rxc <= '0';
    wait for phy_rxc_period/2;
    phy_rxc <= '1';
    wait for phy_rxc_period/2;
  end process;  -- rxc;
-------------------------------------------------------------------------------
-- purpose: set a counter to simulate DOQA
-- type   : sequential
-- inputs : CLK_500M, rst
-- outputs: DOQA
  sim_DOQA : process (CLK_500M, rst, user_pushbutton) is
  begin  -- process sim_DOQA
    if user_pushbutton = '0' then       -- asynchronous reset (active low)
      ADC_DOQA_p <= (others => '0');
    elsif CLK_500M'event and CLK_500M = '1' then  -- rising clock edge
      ADC_DOQA_p <= ADC_DOQA_p+2;
    end if;
  end process sim_DOQA;
  ADC_DOQA_n <= not ADC_DOQA_p;

  -- purpose: set a counter to simulate DOQB
-- type   : sequential
-- inputs : CLK_500M, rst
-- outputs: DOQB
  sim_DOQB : process (CLK_500M, rst, user_pushbutton) is
  begin  -- process sim_DOQB
    if user_pushbutton = '0' then       -- asynchronous reset (active low)
      ADC_DOQB_p <= x"01";
    elsif CLK_500M'event and CLK_500M = '1' then  -- rising clock edge
      ADC_DOQB_p <= ADC_DOQB_p+2;
    end if;
  end process sim_DOQB;
  ADC_DOQB_n <= not ADC_DOQB_p;
  -----------------------------------------------------------------------------
  -- purpose: set a counter to simulate DOIA
-- type   : sequential
-- inputs : CLK_500M, rst
-- outputs: DOIA
  -- sim_DOIA : process (CLK_500M, rst, user_pushbutton) is
  -- begin  -- process sim_DOIA
  --   if user_pushbutton = '0' then       -- asynchronous reset (active low)
  --     ADC_DOIA_p <= (others => '0');
  --   elsif CLK_500M'event and CLK_500M = '1' then  -- rising clock edge
  --     ADC_DOIA_p <= ADC_DOIA_p+2;
  --   end if;
  -- end process sim_DOIA;
  -- ADC_DOIA_n <= not ADC_DOIA_p;

  -- purpose: set a counter to simulate DOIB
-- type   : sequential
-- inputs : CLK_500M, rst
-- outputs: DOIB
  -- sim_DOIB : process (CLK_500M, rst, user_pushbutton) is
  -- begin  -- process sim_DOIB
  --   if user_pushbutton = '0' then       -- asynchronous reset (active low)
  --     ADC_DOIB_p <= x"01";
  --   elsif CLK_500M'event and CLK_500M = '1' then  -- rising clock edge
  --     ADC_DOIB_p <= ADC_DOIB_p+2;
  --   end if;
  -- end process sim_DOIB;
  -- ADC_DOIB_n <= not ADC_DOIB_p;
  -----------------------------------------------------------------------------
  -- Stimulus process
  stim_proc : process
  begin
    user_pushbutton <= '0';             -- hold reset state for 100 ns.
    wait for 5000 ns;
    user_pushbutton <= '1';
    wait for OSC_in_p_period*10;

    -- insert stimulus here
    wait for 4 ns;                      --new add
    phy_rxdv <= '1';
    phy_rxd  <= x"f";
    wait for 16 ns;
    phy_rxd  <= x"5";
    wait for 60 ns;
    phy_rxd  <= x"d";
    wait for 4 ns;
    phy_rxd  <= x"0";
    wait for 48 ns;
    --mac dst
    phy_rxd  <= x"0";
    wait for 4 ns;
    phy_rxd  <= x"6";
    wait for 4 ns;
    phy_rxd  <= x"4";
    wait for 4 ns;
    phy_rxd  <= x"A";
    wait for 4 ns;
    phy_rxd  <= x"c";
    wait for 4 ns;
    phy_rxd  <= x"4";
    wait for 4 ns;
    phy_rxd  <= x"1";
    wait for 4 ns;
    phy_rxd  <= x"3";
    wait for 4 ns;
    phy_rxd  <= x"3";
    wait for 4 ns;
    phy_rxd  <= x"7";
    wait for 4 ns;
    phy_rxd  <= x"0";
    wait for 4 ns;
    phy_rxd  <= x"4";
    wait for 4 ns;
    --mac src
    phy_rxd  <= x"a";
    wait for 4 ns;
    phy_rxd  <= x"a";
    wait for 4 ns;
    phy_rxd  <= x"5";
    wait for 4 ns;
    phy_rxd  <= x"5";
    wait for 4 ns;
    --type
    phy_rxd  <= x"0";
    wait for 4 ns;
    phy_rxd  <= x"0";
    wait for 4 ns;
    phy_rxd  <= x"1";
    wait for 4 ns;
    phy_rxd  <= x"0";
    wait for 4 ns;
    --reg addr
    phy_rxd  <= x"e";
    wait for 48 ns;
        phy_rxd  <= x"0";
    wait for 304 ns;
    -- blank 40 byte
    phy_rxd  <= x"0";
    wait for 4 ns;
    phy_rxd  <= x"a";
    wait for 4 ns;
    phy_rxd  <= x"5";
    wait for 4 ns;
    phy_rxd  <= x"c";
    wait for 4 ns;
    phy_rxd  <= x"9";
    wait for 4 ns;
    phy_rxd  <= x"9";
    wait for 4 ns;
    phy_rxd  <= x"2";
    wait for 4 ns;
    phy_rxd  <= x"2";
    wait for 4 ns;                      --crc from chipscope
    phy_rxdv <= '0';
    --reg data
    -- phy_rxd  <= x"0";
    -- wait for 304 ns;
    -- -- blank 40 byte
    -- phy_rxd  <= x"2";
    -- wait for 4 ns;
    -- phy_rxd  <= x"9";
    -- wait for 4 ns;
    -- phy_rxd  <= x"3";
    -- wait for 4 ns;
    -- phy_rxd  <= x"9";
    -- wait for 4 ns;
    -- phy_rxd  <= x"c";
    -- wait for 4 ns;
    -- phy_rxd  <= x"4";
    -- wait for 4 ns;
    -- phy_rxd  <= x"1";
    -- wait for 4 ns;
    -- phy_rxd  <= x"0";
    -- wait for 4 ns;                      --crc from chipscope
    -- phy_rxdv <= '0';
    wait for 1000us;

    phy_rxdv <= '1';
    phy_rxd  <= x"f";
    wait for 16 ns;
    phy_rxd  <= x"5";
    wait for 60 ns;
    phy_rxd  <= x"d";
    wait for 4 ns;
    phy_rxd  <= x"0";
    wait for 48 ns;
    --mac dst
    phy_rxd  <= x"0";
    wait for 4 ns;
    phy_rxd  <= x"6";
    wait for 4 ns;
    phy_rxd  <= x"4";
    wait for 4 ns;
    phy_rxd  <= x"A";
    wait for 4 ns;
    phy_rxd  <= x"c";
    wait for 4 ns;
    phy_rxd  <= x"4";
    wait for 4 ns;
    phy_rxd  <= x"1";
    wait for 4 ns;
    phy_rxd  <= x"3";
    wait for 4 ns;
    phy_rxd  <= x"3";
    wait for 4 ns;
    phy_rxd  <= x"7";
    wait for 4 ns;
    phy_rxd  <= x"0";
    wait for 4 ns;
    phy_rxd  <= x"4";
    wait for 4 ns;
    --mac src
    phy_rxd  <= x"a";
    wait for 4 ns;
    phy_rxd  <= x"a";
    wait for 4 ns;
    phy_rxd  <= x"5";
    wait for 4 ns;
    phy_rxd  <= x"5";
    wait for 4 ns;
    --type
    phy_rxd  <= x"0";
    wait for 8 ns;
    phy_rxd  <= x"2";
    wait for 4 ns;
    phy_rxd  <= x"0";
    wait for 4 ns;
    --reg addr
    phy_rxd  <= x"e";
    wait for 48 ns;
    --reg data
    phy_rxd  <= x"0";
    wait for 304 ns;
    -- blank 40 byte
    phy_rxd  <= x"5";
    wait for 4 ns;
    phy_rxd  <= x"3";
    wait for 4 ns;
    phy_rxd  <= x"B";
    wait for 4 ns;
    phy_rxd  <= x"B";
    wait for 4 ns;
    phy_rxd  <= x"2";
    wait for 4 ns;
    phy_rxd  <= x"5";
    wait for 4 ns;
    phy_rxd  <= x"D";
    wait for 4 ns;
    phy_rxd  <= x"1";
    wait for 4 ns;                      --crc from chipscope
    phy_rxdv <= '0';
  end process;

end;
