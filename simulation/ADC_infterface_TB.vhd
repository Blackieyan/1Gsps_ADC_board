--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:21:39 11/02/2015
-- Design Name:   
-- Module Name:   Y:/Documents/projects/ZJUprojects/VHDL/ZJUproject/ADC_infterface_TB.vhd
-- Project Name:  ZJUproject
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ADC_interface
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY ADC_infterface_TB IS
END ADC_infterface_TB;
 
ARCHITECTURE behavior OF ADC_infterface_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ADC_interface
    PORT(
         ADC_Mode : OUT  std_logic;
         ADC_sclk_OUT : OUT  std_logic;
         ADC_sldn_OUT : OUT  std_logic;
         ADC_sdata : OUT  std_logic_vector(0 downto 0);
         clk1 : IN  std_logic;
         clk2 : in std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk1 : std_logic;
    signal clk2 : std_logic;

 	--Outputs
   signal ADC_Mode : std_logic;
   signal ADC_sclk_OUT : std_logic;
   signal ADC_sldn_OUT : std_logic;
   signal ADC_sdata : std_logic_vector(0 downto 0);
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   constant clk1_period : time := 10 ns;
       constant clk2_period : time := 100 ns;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ADC_interface PORT MAP (
          ADC_Mode => ADC_Mode,
          ADC_sclk_OUT => ADC_sclk_OUT,
          ADC_sldn_OUT => ADC_sldn_OUT,
          ADC_sdata => ADC_sdata,
          clk1 => clk1,
          clk2 => clk2
        );

   -- Clock process definitions
   OSC_in_process :process
   begin
                clk2 <= '0';
		wait for clk2_period/2;
                clk2 <='1';
		wait for clk2_period/2;
   end process;

   clk1_process :process
   begin
                clk1 <= '0';
		wait for clk1_period/2;
                clk1 <='1';
		wait for clk1_period/2;
   end process;

   -- Stimulus process
   -- stim_proc: process
   -- begin		
   --    -- hold reset state for 100 ns.
   --    wait for 100 ns;	

   --    wait for OSC_in_period*10;

   --    -- insert stimulus here 

   --    wait;
   -- end process;

END;
