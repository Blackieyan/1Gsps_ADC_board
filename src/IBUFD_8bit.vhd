----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:06:12 01/08/2016 
-- Design Name: 
-- Module Name:    IBUFD_8bit - Behavioral 
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
use UNISIM.vcomponents.all;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity IBUFD_8bit is
  generic (
    width : integer := 8
    );
  port (
    O  : out std_logic_vector(width-1 downto 0);
    I  : in  std_logic_vector(width-1 downto 0);
    IB : in  std_logic_vector(width-1 downto 0)
    );
end IBUFD_8bit;

architecture Behavioral of IBUFD_8bit is

begin
  gen_i : for j in 0 to 7 generate
  begin
    IBUFDS_inst : IBUFDS
      generic map (
        DIFF_TERM    => false,          -- Differential Termination 
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => O(j),                     -- Buffer output
        I  => I(j),  -- Diff_p buffer input (connect directly to top-level port)
        IB => IB(j)  -- Diff_n buffer input (connect directly to top-level port)
        );
  end generate gen_i;

end Behavioral;

