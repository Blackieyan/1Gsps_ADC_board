--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:44:14 09/01/2017
-- Design Name:   
-- Module Name:   C:/Current_Key_Projects/1Gsps_ADC_board_V4_algromth/simulation/Inst_DDS_Tb.vhd
-- Project Name:  ZJUproject
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: DDS_top
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

entity Inst_DDS_Tb is
end Inst_DDS_Tb;

architecture behavior of Inst_DDS_Tb is

  -- Component Declaration for the Unit Under Test (UUT)

  component DDS_top
    port(
      dds_clk         : in  std_logic;
      dds_sclr        : in  std_logic;
      dds_en          : in  std_logic;
      dds_phase_shift : in  std_logic_vector(24 downto 0);
      Pstprc_num_frs : in std_logic;
      -- pstprc_dps_en : in std_logic;
      cos_out         : out std_logic_vector(95 downto 0);
      sin_out         : out std_logic_vector(95 downto 0);
      dds_data_start  : in  std_logic_vector(14 downto 0);
      dds_data_len    : in  std_logic_vector(14 downto 0);
      cmd_smpl_depth  : in  std_logic_vector(15 downto 0)
      );
  end component;


  --Inputs
  signal dds_clk         : std_logic                     := '0';
  signal dds_sclr        : std_logic                     := '0';
  signal dds_en          : std_logic                     := '0';
  signal dds_phase_shift : std_logic_vector(24 downto 0) := (others => '0');
    signal dds_data_start : std_logic_vector(14 downto 0):= "000"&x"005";
  signal dds_data_len   : std_logic_vector(14 downto 0):= "000"&x"5DC";
  signal cmd_smpl_depth : std_logic_vector(15 downto 0):= x"07d0";
  signal Pstprc_num_frs : std_logic;
    
  --Outputs
  signal cos_out        : std_logic_vector(95 downto 0);
  signal sin_out        : std_logic_vector(95 downto 0);
  signal dds_ce : std_logic;

  -- Clock period definitions
  constant dds_clk_period : time := 10 ns;

begin

  -- Instantiate the Unit Under Test (UUT)
  DDS_top_1: entity work.DDS_top
    port map (
      dds_clk         => dds_clk,
      dds_sclr        => dds_sclr,
      dds_en          => dds_en,
      dds_phase_shift => dds_phase_shift,
      pstprc_num_frs => pstprc_num_frs,
      cos_out         => cos_out,
      sin_out         => sin_out,
      dds_data_start  => dds_data_start,
      dds_data_len    => dds_data_len,
      cmd_smpl_depth  => cmd_smpl_depth);
  -- uut : DDS_top port map (
  --   dds_clk         => dds_clk,
  --   dds_sclr        => dds_sclr,
  --   dds_en          => dds_en,
  --   dds_phase_shift => dds_phase_shift,
  --   cos_out         => cos_out,
  --   sin_out         => sin_out
  --   );

  -- Clock process definitions
  dds_clk_process : process
  begin
    dds_clk <= '0';
    wait for dds_clk_period/2;
    dds_clk <= '1';
    wait for dds_clk_period/2;
  end process;


  -- Stimulus process
  stim_proc : process
  begin
    dds_sclr        <= '1';  -- hold reset state for 100 ns.
    wait for 100 ns;
    dds_sclr        <= '0';
    wait for dds_clk_period*10;
    -- dds_ce<='1';
    dds_phase_shift <= '0'&x"150000";
    pstprc_num_frs <='1';
    wait for dds_clk_period*10;
    dds_en          <= '1';
    pstprc_num_frs<='0';
    -- insert stimulus here 
    wait for dds_clk_period*5000;
    dds_phase_shift <= '1'&x"100000";
    pstprc_num_frs<='1';
    wait for dds_clk_period*10;
    pstprc_num_frs<='0';
    wait;
  end process;

end;
