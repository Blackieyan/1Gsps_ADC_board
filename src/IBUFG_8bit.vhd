library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.all;
use UNISIM.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity IBUFDS_8bit_inst is
  generic(
    ddr_num : integer := 8
    );

  port(
    IB  : in std_logic_vector(ddr_num-1 downto 0);
    I  : in std_logic_vector(ddr_num-1 downto 0);
    O   : out  std_logic_vector(ddr_num-1 downto 0)
    );
end IBUFDS_8bit_inst;

architecture Behavioral of IDDR_inst is

begin
signal O : std_logic_vector(ddr_num-1 downto 0);
  gen_i : for i in 0 to 7 generate

    IBUFDS_8bit_inst : IBUFDS
   generic map (
      DIFF_TERM => FALSE, -- Differential Termination 
      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
      IOSTANDARD => "DEFAULT")
   port map (
      O => O(i),  -- Buffer output
      I => I(i),  -- Diff_p buffer input (connect directly to top-level port)
      IB => IB(i) -- Diff_n buffer input (connect directly to top-level port)
   );
  end generate;
  end Behavioral;
