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
  port(
    clk : in std_logic;
    FIFO_upload_data : in std_logic_vector(7 downto 0)
);
end post_process;

architecture Behavioral of post_process is
  
signal IxCOS : std_logic_vector(19 downto 0);
signal IxSIN : std_logic_vector(19 downto 0);
signal QxCOS : std_logic_vector(19 downto 0);
signal QxSIN : std_logic_vector(19 downto 0);

signal dds_sclr : std_logic;
signal dds_we : std_logic;
signal dds_phase_shift : std_logic_vector(15 downto 0);
signal dds_cos : std_logic_vector(15 downto 0);
signal dds_sin : std_logic_vector(15 downto 0);
-------------------------------------------------------------------------------
	COMPONENT DDS_top
	PORT(
		dds_clk : IN std_logic;
		dds_sclr : IN std_logic;
		dds_we : IN std_logic;
		dds_phase_shift : IN std_logic_vector(15 downto 0);          
		dds_cos : OUT std_logic_vector(15 downto 0);
		dds_sin : OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;
-------------------------------------------------------------------------------
begin
	Inst_DDS: DDS_top PORT MAP(
		dds_clk => clk,
		dds_sclr => dds_sclr,
		dds_we => dds_we,
		dds_phase_shift => dds_phase_shift,
		dds_cos => dds_cos,
		dds_sin => dds_sin
	);

end Behavioral;

