----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:28:07 03/01/2016 
-- Design Name: 
-- Module Name:    usb2_interface - Behavioral 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity usb2_interface is
  port(
    clk_20M      : in    std_logic;
    USB_data    : inout std_logic_vector(15 downto 0);
    rst_n       : in    std_logic;
    DataEPFull  : in    std_logic;
    CmdEPEmpty  : in    std_logic;
    data_in_usb : in    std_logic_vector(15 downto 0);
    EPADDR      : out   std_logic_vector(1 downto 0);
    SLRD        : out   std_logic;
    SLOE        : out   std_logic;
    SLWR        : out   std_logic;
    PKTEND      : out   std_logic;
    IFCLk       : out   std_logic;
    usb_start   : out   std_logic;
    usb_clr     : out   std_logic;
	 dout : buffer std_logic_vector(15 downto 0);
	 clk_10M : in std_logic
    );
end usb2_interface;

architecture Behavioral of usb2_interface is

  signal glbclr          : std_logic;   --interface
  signal clr             : std_logic;
  signal Cmd             : std_logic_vector(15 downto 0);
  signal inData          : std_logic_vector(15 downto 0);
  signal BufferEmpty     : std_logic;
  signal CountEPFull     : std_logic;
  signal CountReady      : std_logic;
  signal Count_en        : std_logic;
  signal CountData       : std_logic_vector(15 downto 0);
  signal inData_notempty : std_logic;
  signal DAQen           : std_logic;
  signal Cmdpulse        : std_logic_vector(15 downto 0);
  signal outData         : std_logic_vector(15 downto 0);
  signal CmdOrData       : std_logic;
  signal inData_en       : std_logic;
  signal FifoReadEnable  : std_logic;
  signal Cmd_en          : std_logic;
-------------------------------------------------------------------------------
  signal CmdStrobe       : std_logic;   --analysis
  signal start           : std_logic;
  signal data_en         : std_logic;
  signal EP2_en          : std_logic;
-------------------------------------------------------------------------------
  -- signal empty           : std_logic;   --fifo
  signal rst             : std_logic;
  signal wr_clk          : std_logic;
  signal rd_clk          : std_logic;
  signal din             : std_logic_vector(15 downto 0);
  signal wr_en           : std_logic;
  signal rd_en           : std_logic;
--  signal dout            : std_logic_vector(15 downto 0);
  signal full            : std_logic;
  signal almost_full     : std_logic;
  signal empty           : std_logic;
  signal almost_empty    : std_logic;
  signal en_frequency    : std_logic;
  signal cmdData         : std_logic_vector(15 downto 0);
  signal clk_div_cnt :std_logic_vector(7 downto 0);
  constant Div_multi :std_logic_vector(3 downto 0) := "0010";
  signal usb_SCLK : std_logic;


  component USB_Interface
    port(
      CLK             : in  std_logic;
      CLR             : in  std_logic;
      Cmd             : in  std_logic_vector(15 downto 0);
      inData          : in  std_logic_vector(15 downto 0);
      DataEPFull      : in  std_logic;
      CmdEPEmpty      : in  std_logic;
      BufferEmpty     : in  std_logic;
      CountEPFull     : in  std_logic;
      CountReady      : in  std_logic;
      Count_en        : in  std_logic;
      CountData       : in  std_logic_vector(15 downto 0);
      inData_notempty : in  std_logic;
      DAQEn           : in  std_logic;
      Cmdpulse        : out std_logic_vector(15 downto 0);
      outData         : out std_logic_vector(15 downto 0);
      CmdOrData       : out std_logic;
      inData_en       : out std_logic;
      EPADDR          : out std_logic_vector(1 downto 0);
      SLRD            : out std_logic;
      SLOE            : out std_logic;
      SLWR            : out std_logic;
      en_frequency    : out std_logic;
      PKTEND          : out std_logic;
      FifoReadEnable  : out std_logic;
      Cmd_en          : out std_logic
      );
  end component;

  component Cmd_Analysis
    port(
      clk         : in  std_logic;
      Cmd_en      : in  std_logic;
      CmdStrobe   : in  std_logic;
      CmdData     : in  std_logic_vector(15 downto 0);
      GlobalClear : out std_logic;
      Start       : out std_logic;
      data_en     : out std_logic;
      EP2_en      : out std_logic
      );
  end component;

  component fifo_usb
    port (
      rst          : in  std_logic;
      wr_clk       : in  std_logic;
      rd_clk       : in  std_logic;
      din          : in  std_logic_vector(15 downto 0);
      wr_en        : in  std_logic;
      rd_en        : in  std_logic;
      dout         : out std_logic_vector(15 downto 0);
      full         : out std_logic;
      almost_full  : out std_logic;
      empty        : out std_logic;
      almost_empty : out std_logic
      );
  end component;
-------------------------------------------------------------------------------


begin

  -----------------------------------------------------------------------------
  Inst_USB_Interface : USB_Interface port map(
    CLK             => clk_20m,
    CLR             => glbclr,
    Cmd             => cmd,
    inData          => indata,
    Cmdpulse        => cmdpulse,
    outData         => outdata,
    DataEPFull      => dataepfull,
    CmdEPEmpty      => cmdepempty,
    CmdOrData       => cmdordata,
    BufferEmpty     => bufferempty,
    CountEPFull     => countepfull,
    CountReady      => countready,
    Count_en        => count_en,
    CountData       => countdata,
    inData_notempty => indata_notempty,
    inData_en       => inData_en,
    EPADDR          => epaddr,
    SLRD            => slrd,
    SLOE            => sloe,
    SLWR            => slwr,
    DAQEn           => daqen,
    en_frequency    => en_frequency,
    PKTEND          => pktend,
    FifoReadEnable  => FifoReadEnable,
    Cmd_en          => Cmd_en
    );

  Inst_Cmd_Analysis : Cmd_Analysis port map(
    clk         => clk_20m,
    Cmd_en      => Cmd_en,
    CmdStrobe   => CmdStrobe,
    CmdData     => CmdData,
    GlobalClear => Glbclr,
    Start       => Start,
    data_en     => data_en,
    EP2_en      => EP2_en
    );

  Inst_fifo_usb : fifo_usb
    port map (
      rst          => not rst_n,
      wr_clk       => clk_10m,
      rd_clk       => clk_20m,
      din          => data_in_usb,
      wr_en        => not full,
      rd_en        => FifoReadEnable,
      dout         => dout,
      full         => full,
      almost_full  => almost_full,
      empty        => empty,
      almost_empty => almost_empty
      );
-------------------------------------------------------------------------------
  cmddata         <= cmdpulse;
  cmdstrobe       <= cmdordata;
  IFCLK           <= not clk_20m;
  usb_clr         <= glbclr;
  BufferEmpty     <= empty;
  countready       <= '0';
  count_en        <= '0';
  DAQEN           <= '1';
  indata_notempty <= not empty;
  indata<=dout;
--  glbclr<=rst_n;
  -----------------------------------------------------------------------------
  -- purpose: select module
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: 
  CmdorData_ps : process (clk_20m, rst_n) is
  begin  -- process CmdorData
    if clk_20m'event and clk_20m = '1' then     -- rising clock edge
      if CmdOrData = '1' then
        cmd <= USB_data;
      elsif cmdordata = '0' then
        USB_data <= outdata;
      end if;
    end if;
  end process CmdorData_ps;
-----------------------------------------------------------------------------
  set_clk_div_cnt : process (CLK_10m, rst_n) is
  begin  -- process set_clk_div_cnt
    if rst_n = '0' then                 -- asynchronous reset (active
      clk_div_cnt <= x"00";
    elsif CLK_10m'event and CLK_10m = '1' then          -- rising clock edge
      if clk_div_cnt <= Div_multi then
        clk_div_cnt <= clk_div_cnt+1;
      else
        clk_div_cnt <= x"00";
      end if;
    end if;
  end process set_clk_div_cnt;

  set_usb_sclk : process (CLK_10m, rst_n) is
  begin  -- process set_ADC_sclk
    if rst_n = '0' then                   -- asynchronous reset (active low)
      usb_SCLK <= '0';
    elsif CLK_10m'event and CLK_10m = '1' then  -- rising clock edge
      if clk_div_cnt <= Div_multi(3 downto 1) then
        usb_SCLK <= '0';
      else
        usb_SCLK <= '1';
      end if;
    end if;
  end process set_usb_sclk;
end Behavioral;

