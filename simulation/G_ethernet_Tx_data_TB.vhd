--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:27:00 03/09/2016
-- Design Name:   
-- Module Name:   Y:/Documents/projects/ZJUprojects/ZJUproject/ethernet/ethernet/G_ethernet_Tx_data_TB.vhd
-- Project Name:  ethernet
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: G_ethernet_Tx_data
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

entity G_ethernet_Tx_data_TB is
end G_ethernet_Tx_data_TB;

architecture behavior of G_ethernet_Tx_data_TB is

  -- Component Declaration for the Unit Under Test (UUT)

  component G_ethernet_Tx_data
  port (
    clk_125m :in std_logic;
    clk_125m_quar : in std_logic;
    rst_n_gb_i      : in  std_logic;
    PHY_TXD_o       : out std_logic_vector(3 downto 0);
    PHY_GTXclk_quar : out std_logic;
    phy_txen_quar   : out std_logic;
    phy_txer_o      : out std_logic;
    user_pushbutton : in  std_logic;
    rst_n_o         : out std_logic;    --for test,generate from Gcnt
    fifo_upload_data : in std_logic_vector(7 downto 0)
    );
  end component;


  --Inputs
  signal clk_125m : std_logic;
  signal clk_125m_quar : std_logic;
  -- signal Osc_in_p         : std_logic                    := '0';
  -- signal Osc_in_n         : std_logic                    := '0';
  signal rst_n_gb_i       : std_logic                    := '0';
  signal rst_n_o : std_logic;
  signal user_pushbutton  : std_logic                    := '0';
  signal fifo_upload_data : std_logic_vector(7 downto 0) := "00000000";
  --Outputs
  signal PHY_TXD_o       : std_logic_vector(3 downto 0);
  signal PHY_GTXclk_quar : std_logic;
  signal phy_txen_quar   : std_logic;
  signal phy_txer_o      : std_logic;
  -- signal rst_n_o         : std_logic;
  -- signal SRCC1_p         : std_logic;
  -- signal SRCC1_n         : std_logic;
  -- signal MRCC2_p         : std_logic;
  -- signal MRCC2_n         : std_logic;

  -- No clocks detected in port list. Replace <clock> below with 
  -- appropriate port name 

  constant osc_in_p_period : time := 8 ns;

begin

  -- Instantiate the Unit Under Test (UUT)
  uut : G_ethernet_Tx_data port map (
    -- Osc_in_p        => Osc_in_p,
    -- Osc_in_n        => Osc_in_n,
    clk_125m_quar => clk_125m_quar,
    clk_125m => clk_125m,
    rst_n_gb_i      => rst_n_gb_i,
    PHY_TXD_o       => PHY_TXD_o,
    PHY_GTXclk_quar => PHY_GTXclk_quar,
    phy_txen_quar   => phy_txen_quar,
    phy_txer_o      => phy_txer_o,
    user_pushbutton => user_pushbutton,
    rst_n_o         => rst_n_o,
    -- SRCC1_p => SRCC1_p,
    -- SRCC1_n =>SRCC1_n,
    -- MRCC2_p =>MRCC2_p,
    -- MRCC2_n => MRCC2_n,
    fifo_upload_data =>fifo_upload_data
    );

  -- Clock process definitions
  clk_125m_process : process
  begin
    clk_125m <= '0';
   clk_125m_quar<= '1';
    wait for osc_in_p_period/2;
    clk_125m <= '1';
    clk_125m_quar <= '0';
    wait for osc_in_p_period/2;
  end process;


  -- Stimulus process
  stim_proc : process
  begin
    user_pushbutton <= '1';
    wait for 100 ns;
    -- 100ns;
    user_pushbutton <= '0';             -- hold reset state for 100 ns.
    wait for 500 ns;
    user_pushbutton <= '1';
    wait for osc_in_p_period*10;

    -- insert stimulus here 

    wait;
  end process;

end;
