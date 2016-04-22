--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:11:52 02/18/2016
-- Design Name:   
-- Module Name:   Y:/Documents/projects/ZJUprojects/ZJUproject/FFT_test_TB.vhd
-- Project Name:  ZJUproject
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: FFT_test
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
 
ENTITY FFT_test_TB IS
END FFT_test_TB;
 
ARCHITECTURE behavior OF FFT_test_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT FFT_test
    PORT(
         clk_in : IN  std_logic;
         enable : IN  std_logic;
         rst_n : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_in : std_logic := '0';
   signal enable : std_logic := '0';
   signal rst_n : std_logic := '0';

   -- Clock period definitions
   constant clk_in_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: FFT_test PORT MAP (
          clk_in => clk_in,
          enable => enable,
          rst_n => rst_n
        );

   -- Clock process definitions
   clk_in_process :process
   begin
		clk_in <= '0';
		wait for clk_in_period/2;
		clk_in <= '1';
		wait for clk_in_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
      rst_n<='0';
      wait for clk_in_period*10;
      rst_n<='1';
      -- insert stimulus here 
      wait for 100 ns;  -- 100ns;
      enable<='1';
      wait;
   end process;

END;
