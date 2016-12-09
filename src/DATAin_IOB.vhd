----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:31:42 12/08/2016 
-- Design Name: 
-- Module Name:    DATAin_IOB - Behavioral 
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

entity DATAin_IOB is
  port(
    CLK_200M     : in  std_logic;
    ADC_CLKOI    : in  std_logic;
    ADC_CLKOQ    : in  std_logic;
    ADC_DOQB_p   : in  std_logic_vector(7 downto 0);
    ADC_DOQB_n   : in  std_logic_vector(7 downto 0);
    ADC_DOQA_p   : in  std_logic_vector(7 downto 0);
    ADC_DOQA_n   : in  std_logic_vector(7 downto 0);
    ADC_DOIB_p   : in  std_logic_vector(7 downto 0);
    ADC_DOIB_n   : in  std_logic_vector(7 downto 0);
    ADC_DOIA_p   : in  std_logic_vector(7 downto 0);
    ADC_DOIA_n   : in  std_logic_vector(7 downto 0);
    ---------------------------------------------------------------------------
    ADC_DOQB_2_d : out std_logic_vector(7 downto 0);
    ADC_DOQA_2_d : out std_logic_vector(7 downto 0);
    ADC_DOQB_1_d : out std_logic_vector(7 downto 0);
    ADC_DOQA_1_d : out std_logic_vector(7 downto 0);

    ADC_DOIB_2_d : out std_logic_vector(7 downto 0);
    ADC_DOIA_2_d : out std_logic_vector(7 downto 0);
    ADC_DOIB_1_d : out std_logic_vector(7 downto 0);
    ADC_DOIA_1_d : out std_logic_vector(7 downto 0)
    );
end DATAin_IOB;

architecture Behavioral of DATAin_IOB is
  
  signal ADC_DOQB : std_logic_vector(7 downto 0);
  signal ADC_DOQA : std_logic_vector(7 downto 0);
  signal ADC_DOIB : std_logic_vector(7 downto 0);
  signal ADC_DOIA : std_logic_vector(7 downto 0);
  signal ADC_doqa_delay : std_logic_vector(7 downto 0);
  signal ADC_doqb_delay : std_logic_vector(7 downto 0);
  signal ADC_doia_delay : std_logic_vector(7 downto 0);
  signal ADC_doib_delay : std_logic_vector(7 downto 0);
  signal ADC_DOIA_1 : std_logic_vector(7 downto 0);
  signal ADC_DOIA_2 : std_logic_vector(7 downto 0);
  signal ADC_DOIB_1 : std_logic_vector(7 downto 0);
  signal ADC_DOIB_2 : std_logic_vector(7 downto 0);
  signal ADC_DOQA_1 : std_logic_vector(7 downto 0);
  signal ADC_DOQA_2 : std_logic_vector(7 downto 0);
  signal ADC_DOQB_1 : std_logic_vector(7 downto 0);
  signal ADC_DOQB_2 : std_logic_vector(7 downto 0);
  
  component IDDR_inst
    port(
      CLK : in  std_logic;
      D   : in  std_logic_vector(7 downto 0);
      Q1  : out std_logic_vector(7 downto 0);
      Q2  : out std_logic_vector(7 downto 0)
      );
  end component;
-------------------------------------------------------------------------------
  component IBUFD_8bit
    port(
      I  : in  std_logic_vector(7 downto 0);
      IB : in  std_logic_vector(7 downto 0);
      O  : out std_logic_vector(7 downto 0)
      );
  end component;

-------------------------------------------------------------------------------
begin
  Inst_IBUFD_8bit1 : IBUFD_8bit port map(
    O  => ADC_DOQB,
    I  => ADC_DOQB_p,
    IB => ADC_DOQB_n
    );

  Inst_IBUFD_8bit2 : IBUFD_8bit port map(
    O  => ADC_DOQA,
    I  => ADC_DOQA_p,
    IB => ADC_DOQA_n
    );
  Inst_IBUFD_8bit3 : IBUFD_8bit port map(
    O  => ADC_DOIB,
    I  => ADC_DOIB_p,
    IB => ADC_DOIB_n
    );
  Inst_IBUFD_8bit4 : IBUFD_8bit port map(
    O  => ADC_DOIA,
    I  => ADC_DOIA_p,
    IB => ADC_DOIA_n
    );
  
-------------------------------------------------------------------------------
  ADC_doqa_inst : for i in 0 to 7 generate
  begin
    specify_one : if i = 5 generate
    begin
      IODELAYE1_inst : IODELAYE1
        generic map (
          CINVCTRL_SEL          => false,  -- Enable dynamic clock inversion (TRUE/FALSE)
          DELAY_SRC             => "I",  -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
          HIGH_PERFORMANCE_MODE => false,  -- Reduced jitter (TRUE), Reduced power (FALSE)
          IDELAY_TYPE           => "FIXED",  -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          IDELAY_VALUE          => 0,   -- Input delay tap setting (0-31)
          ODELAY_TYPE           => "FIXED",  -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          ODELAY_VALUE          => 0,   -- Output delay tap setting (0-31)
          REFCLK_FREQUENCY      => 200.0,  -- IDELAYCTRL clock input frequency in MHz
          SIGNAL_PATTERN        => "DATA"  -- "DATA" or "CLOCK" input signal
          )
        port map (
          CNTVALUEOUT => open,          -- 5-bit output: Counter value output
          DATAOUT     => ADC_doqa_delay(i),  -- 1-bit output: Delayed data output
          C           => '0',           -- 1-bit input: Clock input
          CE          => '0',  -- 1-bit input: Active high enable increment/decrement input
          CINVCTRL    => '0',  -- 1-bit input: Dynamic clock inversion input
          CLKIN       => '0',           -- 1-bit input: Clock delay input
          CNTVALUEIN  => "00000",       -- 5-bit input: Counter value input
          DATAIN      => '0',  -- 1-bit input: Internal delay data input
          IDATAIN     => ADC_doqa(i),   -- 1-bit input: Data input from the I/O
          INC         => '0',  -- 1-bit input: Increment / Decrement tap delay input
          ODATAIN     => '0',           -- 1-bit input: Output delay data input
          RST         => '0',  -- 1-bit input: Active-high reset tap-delay input
          T           => '0'            -- 1-bit input: 3-state input
          );
    end generate specify_one;

    universal : if i /= 5 generate
      IODELAYE1_inst : IODELAYE1
        generic map (
          CINVCTRL_SEL          => false,  -- Enable dynamic clock inversion (TRUE/FALSE)
          DELAY_SRC             => "I",  -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
          HIGH_PERFORMANCE_MODE => false,  -- Reduced jitter (TRUE), Reduced power (FALSE)
          IDELAY_TYPE           => "FIXED",  -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          IDELAY_VALUE          => 0,   -- Input delay tap setting (0-31)
          ODELAY_TYPE           => "FIXED",  -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          ODELAY_VALUE          => 0,   -- Output delay tap setting (0-31)
          REFCLK_FREQUENCY      => 200.0,  -- IDELAYCTRL clock input frequency in MHz
          SIGNAL_PATTERN        => "DATA"  -- "DATA" or "CLOCK" input signal
          )
        port map (
          CNTVALUEOUT => open,          -- 5-bit output: Counter value output
          DATAOUT     => ADC_doqa_delay(i),  -- 1-bit output: Delayed data output
          C           => '0',           -- 1-bit input: Clock input
          CE          => '0',  -- 1-bit input: Active high enable increment/decrement input
          CINVCTRL    => '0',  -- 1-bit input: Dynamic clock inversion input
          CLKIN       => '0',           -- 1-bit input: Clock delay input
          CNTVALUEIN  => "00000",       -- 5-bit input: Counter value input
          DATAIN      => '0',  -- 1-bit input: Internal delay data input
          IDATAIN     => ADC_doqa(i),   -- 1-bit input: Data input from the I/O
          INC         => '0',  -- 1-bit input: Increment / Decrement tap delay input
          ODATAIN     => '0',           -- 1-bit input: Output delay data input
          RST         => '0',  -- 1-bit input: Active-high reset tap-delay input
          T           => '0'            -- 1-bit input: 3-state input
          );
    end generate universal;
  end generate;

-------------------------------------------------------------------------------
  ADC_doqb_inst : for i in 0 to 7 generate
  begin
    specify_one : if i = 5 generate
    begin
      IODELAYE1_inst : IODELAYE1
        generic map (
          CINVCTRL_SEL          => false,  -- Enable dynamic clock inversion (TRUE/FALSE)
          DELAY_SRC             => "I",  -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
          HIGH_PERFORMANCE_MODE => false,  -- Reduced jitter (TRUE), Reduced power (FALSE)
          IDELAY_TYPE           => "FIXED",  -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          IDELAY_VALUE          => 0,   -- Input delay tap setting (0-31)
          ODELAY_TYPE           => "FIXED",  -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          ODELAY_VALUE          => 0,   -- Output delay tap setting (0-31)
          REFCLK_FREQUENCY      => 200.0,  -- IDELAYCTRL clock input frequency in MHz
          SIGNAL_PATTERN        => "DATA"  -- "DATA" or "CLOCK" input signal
          )
        port map (
          CNTVALUEOUT => open,          -- 5-bit output: Counter value output
          DATAOUT     => ADC_doqb_delay(i),  -- 1-bit output: Delayed data output
          C           => '0',           -- 1-bit input: Clock input
          CE          => '0',  -- 1-bit input: Active high enable increment/decrement input
          CINVCTRL    => '0',  -- 1-bit input: Dynamic clock inversion input
          CLKIN       => '0',           -- 1-bit input: Clock delay input
          CNTVALUEIN  => "00000",       -- 5-bit input: Counter value input
          DATAIN      => '0',  -- 1-bit input: Internal delay data input
          IDATAIN     => ADC_doqb(i),   -- 1-bit input: Data input from the I/O
          INC         => '0',  -- 1-bit input: Increment / Decrement tap delay input
          ODATAIN     => '0',           -- 1-bit input: Output delay data input
          RST         => '0',  -- 1-bit input: Active-high reset tap-delay input
          T           => '0'            -- 1-bit input: 3-state input
          );
    end generate specify_one;

    universal : if i /= 5 generate
      IODELAYE1_inst : IODELAYE1
        generic map (
          CINVCTRL_SEL          => false,  -- Enable dynamic clock inversion (TRUE/FALSE)
          DELAY_SRC             => "I",  -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
          HIGH_PERFORMANCE_MODE => false,  -- Reduced jitter (TRUE), Reduced power (FALSE)
          IDELAY_TYPE           => "FIXED",  -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          IDELAY_VALUE          => 0,   -- Input delay tap setting (0-31)
          ODELAY_TYPE           => "FIXED",  -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          ODELAY_VALUE          => 0,   -- Output delay tap setting (0-31)
          REFCLK_FREQUENCY      => 200.0,  -- IDELAYCTRL clock input frequency in MHz
          SIGNAL_PATTERN        => "DATA"  -- "DATA" or "CLOCK" input signal
          )
        port map (
          CNTVALUEOUT => open,          -- 5-bit output: Counter value output
          DATAOUT     => ADC_doqb_delay(i),  -- 1-bit output: Delayed data output
          C           => '0',           -- 1-bit input: Clock input
          CE          => '0',  -- 1-bit input: Active high enable increment/decrement input
          CINVCTRL    => '0',  -- 1-bit input: Dynamic clock inversion input
          CLKIN       => '0',           -- 1-bit input: Clock delay input
          CNTVALUEIN  => "00000",       -- 5-bit input: Counter value input
          DATAIN      => '0',  -- 1-bit input: Internal delay data input
          IDATAIN     => ADC_doqb(i),   -- 1-bit input: Data input from the I/O
          INC         => '0',  -- 1-bit input: Increment / Decrement tap delay input
          ODATAIN     => '0',           -- 1-bit input: Output delay data input
          RST         => '0',  -- 1-bit input: Active-high reset tap-delay input
          T           => '0'            -- 1-bit input: 3-state input
          );
    end generate universal;
  end generate;
-------------------------------------------------------------------------------
  ADC_doia_inst : for i in 0 to 7 generate
  begin
    specify_one : if i = 5 generate
    begin
      IODELAYE1_inst : IODELAYE1
        generic map (
          CINVCTRL_SEL          => false,  -- Enable dynamic clock inversion (TRUE/FALSE)
          DELAY_SRC             => "I",  -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
          HIGH_PERFORMANCE_MODE => false,  -- Reduced jitter (TRUE), Reduced power (FALSE)
          IDELAY_TYPE           => "FIXED",  -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          IDELAY_VALUE          => 0,   -- Input delay tap setting (0-31)
          ODELAY_TYPE           => "FIXED",  -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          ODELAY_VALUE          => 0,   -- Output delay tap setting (0-31)
          REFCLK_FREQUENCY      => 200.0,  -- IDELAYCTRL clock input frequency in MHz
          SIGNAL_PATTERN        => "DATA"  -- "DATA" or "CLOCK" input signal
          )
        port map (
          CNTVALUEOUT => open,          -- 5-bit output: Counter value output
          DATAOUT     => ADC_doia_delay(i),  -- 1-bit output: Delayed data output
          C           => '0',           -- 1-bit input: Clock input
          CE          => '0',  -- 1-bit input: Active high enable increment/decrement input
          CINVCTRL    => '0',  -- 1-bit input: Dynamic clock inversion input
          CLKIN       => '0',           -- 1-bit input: Clock delay input
          CNTVALUEIN  => "00000",       -- 5-bit input: Counter value input
          DATAIN      => '0',  -- 1-bit input: Internal delay data input
          IDATAIN     => ADC_doia(i),   -- 1-bit input: Data input from the I/O
          INC         => '0',  -- 1-bit input: Increment / Decrement tap delay input
          ODATAIN     => '0',           -- 1-bit input: Output delay data input
          RST         => '0',  -- 1-bit input: Active-high reset tap-delay input
          T           => '0'            -- 1-bit input: 3-state input
          );
    end generate specify_one;

    universal : if i /= 5 generate
      IODELAYE1_inst : IODELAYE1
        generic map (
          CINVCTRL_SEL          => false,  -- Enable dynamic clock inversion (TRUE/FALSE)
          DELAY_SRC             => "I",  -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
          HIGH_PERFORMANCE_MODE => false,  -- Reduced jitter (TRUE), Reduced power (FALSE)
          IDELAY_TYPE           => "FIXED",  -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          IDELAY_VALUE          => 0,   -- Input delay tap setting (0-31)
          ODELAY_TYPE           => "FIXED",  -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          ODELAY_VALUE          => 0,   -- Output delay tap setting (0-31)
          REFCLK_FREQUENCY      => 200.0,  -- IDELAYCTRL clock input frequency in MHz
          SIGNAL_PATTERN        => "DATA"  -- "DATA" or "CLOCK" input signal
          )
        port map (
          CNTVALUEOUT => open,          -- 5-bit output: Counter value output
          DATAOUT     => ADC_doia_delay(i),  -- 1-bit output: Delayed data output
          C           => '0',           -- 1-bit input: Clock input
          CE          => '0',  -- 1-bit input: Active high enable increment/decrement input
          CINVCTRL    => '0',  -- 1-bit input: Dynamic clock inversion input
          CLKIN       => '0',           -- 1-bit input: Clock delay input
          CNTVALUEIN  => "00000",       -- 5-bit input: Counter value input
          DATAIN      => '0',  -- 1-bit input: Internal delay data input
          IDATAIN     => ADC_doia(i),   -- 1-bit input: Data input from the I/O
          INC         => '0',  -- 1-bit input: Increment / Decrement tap delay input
          ODATAIN     => '0',           -- 1-bit input: Output delay data input
          RST         => '0',  -- 1-bit input: Active-high reset tap-delay input
          T           => '0'            -- 1-bit input: 3-state input
          );
    end generate universal;
  end generate;

-------------------------------------------------------------------------------
  ADC_doib_inst : for i in 0 to 7 generate
  begin
    specify_one : if i = 5 generate
    begin
      IODELAYE1_inst : IODELAYE1
        generic map (
          CINVCTRL_SEL          => false,  -- Enable dynamic clock inversion (TRUE/FALSE)
          DELAY_SRC             => "I",  -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
          HIGH_PERFORMANCE_MODE => false,  -- Reduced jitter (TRUE), Reduced power (FALSE)
          IDELAY_TYPE           => "FIXED",  -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          IDELAY_VALUE          => 0,   -- Input delay tap setting (0-31)
          ODELAY_TYPE           => "FIXED",  -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          ODELAY_VALUE          => 0,   -- Output delay tap setting (0-31)
          REFCLK_FREQUENCY      => 200.0,  -- IDELAYCTRL clock input frequency in MHz
          SIGNAL_PATTERN        => "DATA"  -- "DATA" or "CLOCK" input signal
          )
        port map (
          CNTVALUEOUT => open,          -- 5-bit output: Counter value output
          DATAOUT     => ADC_doib_delay(i),  -- 1-bit output: Delayed data output
          C           => '0',           -- 1-bit input: Clock input
          CE          => '0',  -- 1-bit input: Active high enable increment/decrement input
          CINVCTRL    => '0',  -- 1-bit input: Dynamic clock inversion input
          CLKIN       => '0',           -- 1-bit input: Clock delay input
          CNTVALUEIN  => "00000",       -- 5-bit input: Counter value input
          DATAIN      => '0',  -- 1-bit input: Internal delay data input
          IDATAIN     => ADC_doib(i),   -- 1-bit input: Data input from the I/O
          INC         => '0',  -- 1-bit input: Increment / Decrement tap delay input
          ODATAIN     => '0',           -- 1-bit input: Output delay data input
          RST         => '0',  -- 1-bit input: Active-high reset tap-delay input
          T           => '0'            -- 1-bit input: 3-state input
          );
    end generate specify_one;

    universal : if i /= 5 generate
      IODELAYE1_inst : IODELAYE1
        generic map (
          CINVCTRL_SEL          => false,  -- Enable dynamic clock inversion (TRUE/FALSE)
          DELAY_SRC             => "I",  -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
          HIGH_PERFORMANCE_MODE => false,  -- Reduced jitter (TRUE), Reduced power (FALSE)
          IDELAY_TYPE           => "FIXED",  -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          IDELAY_VALUE          => 0,   -- Input delay tap setting (0-31)
          ODELAY_TYPE           => "FIXED",  -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
          ODELAY_VALUE          => 0,   -- Output delay tap setting (0-31)
          REFCLK_FREQUENCY      => 200.0,  -- IDELAYCTRL clock input frequency in MHz
          SIGNAL_PATTERN        => "DATA"  -- "DATA" or "CLOCK" input signal
          )
        port map (
          CNTVALUEOUT => open,          -- 5-bit output: Counter value output
          DATAOUT     => ADC_doib_delay(i),  -- 1-bit output: Delayed data output
          C           => '0',           -- 1-bit input: Clock input
          CE          => '0',  -- 1-bit input: Active high enable increment/decrement input
          CINVCTRL    => '0',  -- 1-bit input: Dynamic clock inversion input
          CLKIN       => '0',           -- 1-bit input: Clock delay input
          CNTVALUEIN  => "00000",       -- 5-bit input: Counter value input
          DATAIN      => '0',  -- 1-bit input: Internal delay data input
          IDATAIN     => ADC_doib(i),   -- 1-bit input: Data input from the I/O
          INC         => '0',  -- 1-bit input: Increment / Decrement tap delay input
          ODATAIN     => '0',           -- 1-bit input: Output delay data input
          RST         => '0',  -- 1-bit input: Active-high reset tap-delay input
          T           => '0'            -- 1-bit input: 3-state input
          );
    end generate universal;
  end generate;

  IDELAYCTRL_inst : IDELAYCTRL
    port map (
      RDY    => open,  -- 1-bit output indicates validity of the REFCLK
      REFCLK => CLK_200M,               -- 1-bit reference clock input
      RST    => '0'                     -- 1-bit reset input
      );
-------------------------------------------------------------------------------
  Inst_IDDR_inst1 : IDDR_inst port map(
    CLK => ADC_CLKOI,
    Q1  => ADC_DOIA_1,
    Q2  => ADC_DOIA_2,
    D   => ADC_DOIA_delay
    );
  Inst_IDDR_inst2 : IDDR_inst port map(
    CLK => ADC_CLKOI,
    Q1  => ADC_DOIB_1,
    Q2  => ADC_DOIB_2,
    D   => ADC_DOIB_delay
    );
  Inst_IDDR_inst3 : IDDR_inst port map(
    CLK => ADC_CLKOQ,
    Q1  => ADC_DOQA_1,
    Q2  => ADC_DOQA_2,
    D   => ADC_DOQA_delay
    );
  Inst_IDDR_inst4 : IDDR_inst port map(
    CLK => ADC_CLKOQ,
    Q1  => ADC_DOQB_1,
    Q2  => ADC_DOQB_2,
    D   => ADC_DOQB_delay
    );
-------------------------------------------------------------------------------
  DFF_doqA_1_inst1 : for i in 0 to 7 generate
  begin
    FDCE_inst : FDCE
      generic map (
        INIT => '0')   -- Initial value of register ('0' or '1')  
      port map (
        Q   => ADC_DOQA_1_d(i),         -- Data output
        C   => ADC_clkoq,               -- Clock input
        CE  => '1',                     -- Clock enable input
        CLR => '0',                     -- Asynchronous clear input
        D   => ADC_DOQA_1(i)            -- Data input
        );
  end generate DFF_doqA_1_inst1;

  DFF_doqA_2_inst2 : for i in 0 to 7 generate
  begin
    FDCE_inst : FDCE
      generic map (
        INIT => '0')             -- Initial value of register ('0' or '1')  
      port map (
        Q   => ADC_DOQA_2_d(i),         -- Data output
        C   => ADC_clkoq,               -- Clock input
        CE  => '1',                     -- Clock enable input
        CLR => '0',                     -- Asynchronous clear input
        D   => ADC_DOQA_2(i)            -- Data input
        );
  end generate DFF_doqA_2_inst2;

  DFF_doqB_1_inst3 : for i in 0 to 7 generate
  begin
    FDCE_inst : FDCE
      generic map (
        INIT => '0')             -- Initial value of register ('0' or '1')  
      port map (
        Q   => ADC_DOQB_1_d(i),         -- Data output
        C   => ADC_clkoq,               -- Clock input
        CE  => '1',                     -- Clock enable input
        CLR => '0',                     -- Asynchronous clear input
        D   => ADC_DOQB_1(i)            -- Data input
        );
  end generate DFF_doqB_1_inst3;

  DFF_doqB_2_inst4 : for i in 0 to 7 generate
  begin
    FDCE_inst : FDCE
      generic map (
        INIT => '0')             -- Initial value of register ('0' or '1')  
      port map (
        Q   => ADC_DOQB_2_d(i),         -- Data output
        C   => ADC_clkoq,               -- Clock input
        CE  => '1',                     -- Clock enable input
        CLR => '0',                     -- Asynchronous clear input
        D   => ADC_DOQB_2(i)            -- Data input
        );
  end generate DFF_doqB_2_inst4;
  -----------------------------------------------------------------------------
  DFF_doiA_1_inst1 : for i in 0 to 7 generate
  begin
    FDCE_inst : FDCE
      generic map (
        INIT => '0')             -- Initial value of register ('0' or '1')  
      port map (
        Q   => ADC_DOiA_1_d(i),         -- Data output
        C   => ADC_clkoi,               -- Clock input
        CE  => '1',                     -- Clock enable input
        CLR => '0',                     -- Asynchronous clear input
        D   => ADC_DOiA_1(i)            -- Data input
        );
  end generate DFF_doiA_1_inst1;

  DFF_doiA_2_inst2 : for i in 0 to 7 generate
  begin
    FDCE_inst : FDCE
      generic map (
        INIT => '0')             -- Initial value of register ('0' or '1')  
      port map (
        Q   => ADC_DOiA_2_d(i),         -- Data output
        C   => ADC_clkoi,               -- Clock input
        CE  => '1',                     -- Clock enable input
        CLR => '0',                     -- Asynchronous clear input
        D   => ADC_DOiA_2(i)            -- Data input
        );
  end generate DFF_doiA_2_inst2;

  DFF_doiB_1_inst3 : for i in 0 to 7 generate
  begin
    FDCE_inst : FDCE
      generic map (
        INIT => '0')             -- Initial value of register ('0' or '1')  
      port map (
        Q   => ADC_DOiB_1_d(i),         -- Data output
        C   => ADC_clkoi,               -- Clock input
        CE  => '1',                     -- Clock enable input
        CLR => '0',                     -- Asynchronous clear input
        D   => ADC_DOiB_1(i)            -- Data input
        );
  end generate DFF_doiB_1_inst3;

  DFF_doiB_2_inst4 : for i in 0 to 7 generate
  begin
    FDCE_inst : FDCE
      generic map (
        INIT => '0')             -- Initial value of register ('0' or '1')  
      port map (
        Q   => ADC_DOiB_2_d(i),         -- Data output
        C   => ADC_clkoi,               -- Clock input
        CE  => '1',                     -- Clock enable input
        CLR => '0',                     -- Asynchronous clear input
        D   => ADC_DOiB_2(i)            -- Data input
        );
  end generate DFF_doiB_2_inst4;
------------------------------------------------------------------------------ 
end Behavioral;

