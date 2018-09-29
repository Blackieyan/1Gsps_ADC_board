----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:16:48 08/10/2018 
-- Design Name: 
-- Module Name:    async_rst_sync_release - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity async_rst_sync_release is
  port(
    clk : in std_logic;
    async_rst_n_in : in std_logic;
    sync_rst_n_out : out std_logic
);
end async_rst_sync_release;

architecture Behavioral of async_rst_sync_release is
  signal rst_n_buffer : std_logic;
  
begin
-- purpose: async reset
-- type   : sequential
-- inputs : clk, async_rst_n_in
-- outputs: 
process (clk, async_rst_n_in) is
begin  -- process
  if async_rst_n_in = '0' then          -- asynchronous reset (active
    sync_rst_n_out<='0';
    rst_n_buffer<='0';
  elsif clk'event and clk = '1' then    -- rising clock edge
    rst_n_buffer <= '1';
    sync_rst_n_out<=rst_n_buffer;
  end if;
end process;

end Behavioral;

