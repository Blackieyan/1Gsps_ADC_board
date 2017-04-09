----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:40:03 12/09/2016 
-- Design Name: 
-- Module Name:    post_process - Behavioral 
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
Library UNIMACRO;
use UNIMACRO.vcomponents.all;
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

entity post_process is
  generic (
    mult_accum_s_width : integer := 24
    );
  port(
    clk                  : in std_logic;
    Q_data               : in std_logic_vector(63 downto 0);
    I_data               : in std_logic_vector(63 downto 0);
    DDS_phase_shift      : in std_logic_vector(15 downto 0);
    pstprc_en            : in std_logic;
    rst_n                : in std_logic;
    Pstprc_RAMx_rden_stp : in std_logic
    );
end post_process;

architecture Behavioral of post_process is

  type array_data_x_cos is array (7 downto 0) of std_logic_vector(mult_accum_s_width-1 downto 0);
  signal accm_Q_x_cos : array_data_x_cos;
  signal accm_I_x_cos : array_data_x_cos;
  signal accm_Q_x_sin : array_data_x_cos;
  signal accm_I_x_sin : array_data_x_cos;

  type array_base0_data_x_cos is array (3 downto 0) of std_logic_vector(mult_accum_s_width-1 downto 0);
  signal base0_Q_x_cos : array_base0_data_x_cos;
  signal base0_I_x_cos : array_base0_data_x_cos;
  signal base0_Q_x_sin : array_base0_data_x_cos;
  signal base0_I_x_sin : array_base0_data_x_cos;
  type array_bs0_QxCOS_CO is array (3 downto 0) of std_logic;
  signal bs0_QxCOS_CO : array_bs0_QxCOS_CO;
  signal bs0_IxCOS_CO : array_bs0_QxCOS_CO;
  signal bs0_QxSIN_CO : array_bs0_QxCOS_CO;
  signal bs0_IxSIN_CO : array_bs0_QxCOS_CO;
  
  type array_base1_data_x_cos is array (1 downto 0) of std_logic_vector(mult_accum_s_width-1 downto 0);
  signal base1_Q_x_cos : array_base1_data_x_cos;
  signal base1_I_x_cos : array_base1_data_x_cos;
  signal base1_Q_x_sin : array_base1_data_x_cos;
  signal base1_I_x_sin : array_base1_data_x_cos;
  type array_bs1_QxCOS_CO is array (1 downto 0) of std_logic;
  signal bs1_QxCOS_CO : array_bs1_QxCOS_CO;
  signal bs1_IxCOS_CO : array_bs1_QxCOS_CO;
  signal bs1_QxSIN_CO : array_bs1_QxCOS_CO;
  signal bs1_IxSIN_CO : array_bs1_QxCOS_CO;
  
  signal rs_Q_x_sin : std_logic_vector(23 downto 0);
  signal rs_Q_x_cos : std_logic_vector(23 downto 0);
  signal rs_I_x_sin : std_logic_vector(23 downto 0);
  signal rs_I_x_cos : std_logic_vector(23 downto 0);

  -- signal bs0_QxCOS_CO      : std_logic;
  -- signal bs0_QxCOS_CI      : std_logic;
  -- signal bs0_QxSIN_CO      : std_logic;
  -- signal bs0_QxSIN_CI      : std_logic;
  -- signal bs0_IxCOS_CO      : std_logic;
  -- signal bs0_IxCOS_CI      : std_logic;
  -- signal bs0_IxSIN_CO      : std_logic;
  -- signal bs0_IxSIN_CI      : std_logic;
  -- signal bs1_QxCOS_CO      : std_logic;
  -- signal bs1_QxCOS_CI      : std_logic;
  -- signal bs1_QxSIN_CO      : std_logic;
  -- signal bs1_QxSIN_CI      : std_logic;
  -- signal bs1_IxCOS_CO      : std_logic;
  -- signal bs1_IxCOS_CI      : std_logic;
  -- signal bs1_IxSIN_CO      : std_logic;
  -- signal bs1_IxSIN_CI      : std_logic;
  signal rs_QxCOS_CO : std_logic;
  signal rs_QxCOS_CI : std_logic;
  signal rs_IxCOS_CO : std_logic;
  signal rs_IxCOS_CI : std_logic;
  signal rs_QxSIN_CO : std_logic;
  signal rs_QxSIN_CI : std_logic;
  signal rs_IxSIN_CO : std_logic;
  signal rs_IxSIN_CI : std_logic;
  signal add_rst : std_logic;
  signal add_ce : std_logic;
  type array_Q_x_cos is array (7 downto 0) of std_logic_vector(17 downto 0);
  type array_I_x_sin is array (7 downto 0) of std_logic_vector(17 downto 0);
  type array_Q_x_sin is array (7 downto 0) of std_logic_vector(17 downto 0);




  signal IxCOS : std_logic_vector(19 downto 0);
  signal IxSIN : std_logic_vector(19 downto 0);
  signal QxCOS : std_logic_vector(19 downto 0);
  signal QxSIN : std_logic_vector(19 downto 0);

  signal dds_sclr : std_logic;
  signal dds_we   : std_logic;
  signal dds_cos  : std_logic_vector(7 downto 0);
  signal dds_sin  : std_logic_vector(7 downto 0);
  
  signal add_clk : std_logic;
  signal mult_accum_clk    : std_logic;
  signal mult_accum_ce     : std_logic;
  signal mult_accum_sclr   : std_logic;
  signal mult_accum_bypass : std_logic;
  -- signal accm_I_x_cos : std_logic_vector(17 downto 0);
  -- signal accm_Q_x_cos : std_logic_vector(17 downto 0);
  -- signal accm_I_x_sin : std_logic_vector(17 downto 0);
  -- signal accm_Q_x_sin : std_logic_vector(17 downto 0);

-------------------------------------------------------------------------------
  component DDS_top
    port(
      dds_clk         : in  std_logic;
      dds_sclr        : in  std_logic;
      dds_we          : in  std_logic;
      dds_phase_shift : in  std_logic_vector(15 downto 0);
      dds_cos         : out std_logic_vector(7 downto 0);
      dds_sin         : out std_logic_vector(7 downto 0)
      );
  end component;

  component multi_accum_top
    port(
      mult_accum_clk    : in  std_logic;
      mult_accum_ce     : in  std_logic;
      mult_accum_sclr   : in  std_logic;
      mult_accum_bypass : in  std_logic;
      Q_data            : in  std_logic_vector(7 downto 0);
      I_data            : in  std_logic_vector(7 downto 0);
      dds_sin           : in  std_logic_vector(7 downto 0);
      dds_cos           : in  std_logic_vector(7 downto 0);
      accm_I_x_cos      : out std_logic_vector(mult_accum_s_width-1 downto 0);
      accm_I_x_sin      : out std_logic_vector(mult_accum_s_width-1 downto 0);
      accm_Q_x_cos      : out std_logic_vector(mult_accum_s_width-1 downto 0);
      accm_Q_x_sin      : out std_logic_vector(mult_accum_s_width-1 downto 0)
      );
  end component;

-------------------------------------------------------------------------------
begin
  Inst_DDS : DDS_top port map(
    dds_clk         => clk,
    dds_sclr        => dds_sclr,
    dds_we          => dds_we,
    dds_phase_shift => dds_phase_shift,
    dds_cos         => dds_cos,
    dds_sin         => dds_sin
    );

  multi_accum_inst : for i in 0 to 7 generate
  begin
    Inst_multi_accum_top : multi_accum_top port map(
      mult_accum_clk    => mult_accum_clk,
      mult_accum_ce     => mult_accum_ce,
      mult_accum_sclr   => mult_accum_sclr,
      mult_accum_bypass => mult_accum_bypass,
      Q_data            => Q_data(8*i+7 downto 8*i),
      I_data            => I_data(8*i+7 downto 8*i),
      dds_sin           => dds_sin,
      dds_cos           => dds_cos,
      accm_Q_x_cos      => accm_Q_x_cos(i),
      accm_I_x_sin      => accm_I_x_sin(i),
      accm_I_x_cos      => accm_I_x_cos(i),
      accm_Q_x_sin      => accm_Q_x_sin(i)
      );
  end generate multi_accum_inst;
-------------------------------------------------------------------------------
  ADD_QxCOS_bs0_inst : for i in 0 to 3 generate  --QxCOS
  begin
    ADDSUB_MACRO_QxCOS_inst : ADDSUB_MACRO
      generic map (
        DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
        LATENCY => 1,                   -- Desired clock cycle latency, 0-2
        WIDTH   => 24)                  -- Input / Output bus width, 1-48
      port map (
        CARRYOUT => bs0_QxCOS_CO(i),       -- 1-bit carry-out output signal
        RESULT   => base0_Q_x_cos(i),  -- Add/sub result output, width defined by WIDTH generic
        A        => accm_Q_x_cos(2*i),  -- Input A bus, width defined by WIDTH generic
        ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
        B        => accm_Q_x_cos(2*i+1),  -- Input B bus, width defined by WIDTH generic
        CARRYIN  => '0',       -- 1-bit carry-in input
        CE       => ADD_CE,             -- 1-bit clock enable input
        CLK      => ADD_CLK,                -- 1-bit clock input
        RST      => ADD_RST             -- 1-bit active high synchronous reset
        );
  end generate ADD_QxCOS_bs0_inst;

  ADD_QxCOS_bs1_inst : for j in 0 to 1 generate
  begin
    ADDSUB_MACRO_QxCOS_inst : ADDSUB_MACRO
      generic map (
        DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
        LATENCY => 1,                   -- Desired clock cycle latency, 0-2
        WIDTH   => 24)                  -- Input / Output bus width, 1-48
      port map (
        CARRYOUT => bs1_QxCOS_CO(j),       -- 1-bit carry-out output signal
        RESULT   => base1_Q_x_cos(j),  -- Add/sub result output, width defined by WIDTH generic
        A        => base0_Q_x_cos(2*j),  -- Input A bus, width defined by WIDTH generic
        ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
        B        => base0_Q_x_cos(2*j+1),  -- Input B bus, width defined by WIDTH generic
        CARRYIN  => '0',       -- 1-bit carry-in input
        CE       => ADD_CE,             -- 1-bit clock enable input
        CLK      => ADD_CLK,                -- 1-bit clock input
        RST      => ADD_RST             -- 1-bit active high synchronous reset
        );
  end generate ADD_QxCOS_bs1_inst;

  ADDSUB_QxCOS_RS_inst : ADDSUB_MACRO
    generic map (
      DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
      LATENCY => 1,                     -- Desired clock cycle latency, 0-2
      WIDTH   => 24)                    -- Input / Output bus width, 1-48
    port map (
      CARRYOUT => rs_QxCOS_CO,          -- 1-bit carry-out output signal
      RESULT   => rs_Q_x_cos,  -- Add/sub result output, width defined by WIDTH generic
      A        => base1_Q_x_cos(0),  -- Input A bus, width defined by WIDTH generic
      ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
      B        => base1_Q_x_cos(1),  -- Input B bus, width defined by WIDTH generic
      CARRYIN  =>'0',          -- 1-bit carry-in input
      CE       => ADD_CE,               -- 1-bit clock enable input
      CLK      => ADD_CLK,                  -- 1-bit clock input
      RST      => ADD_RST               -- 1-bit active high synchronous reset
      );
  ------------------------------------------------------------------------------
  ADD_QxSIN_bs0_inst : for i in 0 to 3 generate  --QxSIN
  begin
    ADDSUB_MACRO_QxSIN_inst : ADDSUB_MACRO
      generic map (
        DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
        LATENCY => 1,                   -- Desired clock cycle latency, 0-2
        WIDTH   => 24)                  -- Input / Output bus width, 1-48
      port map (
        CARRYOUT => bs0_QxSIN_CO(i),       -- 1-bit carry-out output signal
        RESULT   => base0_Q_x_sin(i),  -- Add/sub result output, width defined by WIDTH generic
        A        => accm_Q_x_sin(2*i),  -- Input A bus, width defined by WIDTH generic
        ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
        B        => accm_Q_x_sin(2*i+1),  -- Input B bus, width defined by WIDTH generic
        CARRYIN  => '0',       -- 1-bit carry-in input
        CE       => ADD_CE,             -- 1-bit clock enable input
        CLK      => ADD_CLK,                -- 1-bit clock input
        RST      => ADD_RST             -- 1-bit active high synchronous reset
        );
  end generate ADD_QxSIN_bs0_inst;

  ADD_QxSIN_bs1_inst : for j in 0 to 1 generate
  begin
    ADDSUB_MACRO_inst : ADDSUB_MACRO
      generic map (
        DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
        LATENCY => 1,                   -- Desired clock cycle latency, 0-2
        WIDTH   => 24)                  -- Input / Output bus width, 1-48
      port map (
        CARRYOUT => bs1_QxSIN_CO(j),       -- 1-bit carry-out output signal
        RESULT   => base1_Q_x_SIN(j),  -- Add/sub result output, width defined by WIDTH generic
        A        => base0_Q_x_sin(j),  -- Input A bus, width defined by WIDTH generic
        ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
        B        => base0_Q_x_sin(2*j+1),  -- Input B bus, width defined by WIDTH generic
        CARRYIN  => '0',       -- 1-bit carry-in input
        CE       => ADD_CE,             -- 1-bit clock enable input
        CLK      => ADD_CLK,                -- 1-bit clock input
        RST      => ADD_RST             -- 1-bit active high synchronous reset
        );
  end generate ADD_QxSIN_bs1_inst;

  ADDSUB_MACRO_inst : ADDSUB_MACRO
    generic map (
      DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
      LATENCY => 1,                     -- Desired clock cycle latency, 0-2
      WIDTH   => 24)                    -- Input / Output bus width, 1-48
    port map (
      CARRYOUT => rs_QxSIN_CO,          -- 1-bit carry-out output signal
      RESULT   => rs_Q_x_sin,  -- Add/sub result output, width defined by WIDTH generic
      A        => base1_Q_x_sin(0),  -- Input A bus, width defined by WIDTH generic
      ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
      B        => base1_Q_x_sin(1),  -- Input B bus, width defined by WIDTH generic
      CARRYIN  =>'0',          -- 1-bit carry-in input
      CE       => ADD_CE,               -- 1-bit clock enable input
      CLK      => ADD_CLK,                  -- 1-bit clock input
      RST      => ADD_RST               -- 1-bit active high synchronous reset
      );
  -----------------------------------------------------------------------------
  ADD_IxCOS_bs0_inst : for i in 0 to 3 generate  --IxCOS
  begin
    ADDSUB_MACRO_inst : ADDSUB_MACRO
      generic map (
        DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
        LATENCY => 1,                   -- Desired clock cycle latency, 0-2
        WIDTH   => 24)                  -- Input / Output bus width, 1-48
      port map (
        CARRYOUT => bs0_IxCOS_CO(i),       -- 1-bit carry-out output signal
        RESULT   => base0_I_x_cos(i),  -- Add/sub result output, width defined by WIDTH generic
        A        => accm_I_x_cos(2*i),  -- Input A bus, width defined by WIDTH generic
        ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
        B        => accm_I_x_cos(2*i+1),  -- Input B bus, width defined by WIDTH generic
        CARRYIN  => '0',       -- 1-bit carry-in input
        CE       => ADD_CE,             -- 1-bit clock enable input
        CLK      => ADD_CLK,                -- 1-bit clock input
        RST      => ADD_RST             -- 1-bit active high synchronous reset
        );
  end generate ADD_IxCOS_bs0_inst;

  ADD_IxCOS_bs1_inst : for j in 0 to 1 generate
  begin
    ADDSUB_MACRO_inst : ADDSUB_MACRO
      generic map (
        DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
        LATENCY => 1,                   -- Desired clock cycle latency, 0-2
        WIDTH   => 24)                  -- Input / Output bus width, 1-48
      port map (
        CARRYOUT => bs1_IxCOS_CO(j),       -- 1-bit carry-out output signal
        RESULT   => base1_I_x_cos(j),  -- Add/sub result output, width defined by WIDTH generic
        A        => base0_I_x_cos(2*j),  -- Input A bus, width defined by WIDTH generic
        ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
        B        => base0_I_x_cos(2*j+1),  -- Input B bus, width defined by WIDTH generic
        CARRYIN  =>'0',       -- 1-bit carry-in input
        CE       => ADD_CE,             -- 1-bit clock enable input
        CLK      => ADD_CLK,                -- 1-bit clock input
        RST      => ADD_RST             -- 1-bit active high synchronous reset
        );
  end generate ADD_IxCOS_bs1_inst;

  ADDSUB_IxCOS_RS_inst : ADDSUB_MACRO
    generic map (
      DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
      LATENCY => 1,                     -- Desired clock cycle latency, 0-2
      WIDTH   => 24)                    -- Input / Output bus width, 1-48
    port map (
      CARRYOUT => rs_IxCOS_CO,         -- 1-bit carry-out output signal
      RESULT   => rs_I_x_cos,  -- Add/sub result output, width defined by WIDTH generic
      A        => base1_I_x_cos(0),  -- Input A bus, width defined by WIDTH generic
      ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
      B        => base1_I_x_cos(1),  -- Input B bus, width defined by WIDTH generic
      CARRYIN  =>'0',         -- 1-bit carry-in input
      CE       => ADD_CE,               -- 1-bit clock enable input
      CLK      => ADD_CLK,                  -- 1-bit clock input
      RST      => ADD_RST               -- 1-bit active high synchronous reset
      );
  -----------------------------------------------------------------------------
  ADD_IxSIN_bs0_inst : for i in 0 to 3 generate  --IxSIN
  begin
    ADDSUB_MACRO_inst : ADDSUB_MACRO
      generic map (
        DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
        LATENCY => 1,                   -- Desired clock cycle latency, 0-2
        WIDTH   => 24)                  -- Input / Output bus width, 1-48
      port map (
        CARRYOUT => bs0_IxSIN_CO(i),       -- 1-bit carry-out output signal
        RESULT   => base0_I_x_sin(i),  -- Add/sub result output, width defined by WIDTH generic
        A        => accm_I_x_sin(2*i),  -- Input A bus, width defined by WIDTH generic
        ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
        B        => accm_I_x_sin(2*i+1),  -- Input B bus, width defined by WIDTH generic
        CARRYIN  => '0',       -- 1-bit carry-in input
        CE       => ADD_CE,             -- 1-bit clock enable input
        CLK      => ADD_CLK,                -- 1-bit clock input
        RST      => ADD_RST             -- 1-bit active high synchronous reset
        );
  end generate ADD_IxSIN_bs0_inst;

  ADD_IxSIN_bs1_inst : for j in 0 to 1 generate
  begin
    ADDSUB_MACRO_inst : ADDSUB_MACRO
      generic map (
        DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
        LATENCY => 1,                   -- Desired clock cycle latency, 0-2
        WIDTH   => 24)                  -- Input / Output bus width, 1-48
      port map (
        CARRYOUT => bs1_IxSIN_CO(j),       -- 1-bit carry-out output signal
        RESULT   => base1_I_x_sin(j),  -- Add/sub result output, width defined by WIDTH generic
        A        => base0_I_x_sin(2*j),  -- Input A bus, width defined by WIDTH generic
        ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
        B        => base0_I_x_sin(2*j+1),  -- Input B bus, width defined by WIDTH generic
        CARRYIN  => '0',       -- 1-bit carry-in input
        CE       => ADD_CE,             -- 1-bit clock enable input
        CLK      => ADD_CLK,                -- 1-bit clock input
        RST      => ADD_RST             -- 1-bit active high synchronous reset
        );
  end generate ADD_IxSIN_bs1_inst;

  ADDSUB_IxSIN_RS_inst : ADDSUB_MACRO
    generic map (
      DEVICE  => "VIRTEX6",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
      LATENCY => 1,                     -- Desired clock cycle latency, 0-2
      WIDTH   => 24)                    -- Input / Output bus width, 1-48
    port map (
      CARRYOUT => rs_IxSIN_CO,          -- 1-bit carry-out output signal
      RESULT   => rs_I_x_SIN,  -- Add/sub result output, width defined by WIDTH generic
      A        => base1_I_x_SIN(0),  -- Input A bus, width defined by WIDTH generic
      ADD_SUB  => '1',  -- 1-bit add/sub input, high selects add, low selects subtract
      B        => base1_I_x_SIN(1),  -- Input B bus, width defined by WIDTH generic
      CARRYIN  => '0',          -- 1-bit carry-in input
      CE       => ADD_CE,               -- 1-bit clock enable input
      CLK      => ADD_CLK,                  -- 1-bit clock input
      RST      => ADD_RST               -- 1-bit active high synchronous reset
      );
  
  mult_accum_clk    <= clk;
  mult_accum_ce     <= pstprc_en;
  mult_accum_sclr   <= not rst_n;
  mult_accum_bypass <= '0';

  ADD_RST  <= not rst_n;
  dds_sclr <= not rst_n;
  dds_we   <= pstprc_en;
  add_ce   <= pstprc_en;                -- not accuracy control
  ADD_clk <= clk;
  
end Behavioral;

