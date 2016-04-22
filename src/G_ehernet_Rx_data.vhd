----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:31:38 03/18/2016 
-- Design Name: 
-- Module Name:    G_ehernet_Rx_data - Behavioral 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity G_ehernet_Rx_data is
  port(
    rst_n : in std_logic;
    Rd_clk : in std_logic;
    Rd_en : in std_logic;
    Rd_Addr : in std_logic_vector(13 downto 0);
    PHY_RXD : in std_logic_vector(3 downto 0);
    PHY_RXC : in std_logic;
    PHY_RXDV : in std_logic;
    Rd_data : out std_logic_vector(7 downto 0);
    Frm_valid : out std_logic);
--    buf_wr_en : out std_logic);
end G_ehernet_Rx_data;

architecture Behavioral of G_ehernet_Rx_data is
constant MAC_addr : std_logic_vector(47 downto 0):=x"ffffffffffff";--°å×ÓµÄmacµØÖ·
-- signal PHY_RXC_g : std_logic;
---- signal Frm_valid : std_logic;
-- signal frm_valid_d : std_logic;
 
 
	COMPONENT Mac_RX2
	PORT(
		reset : IN std_logic;
		MAC_addr : IN std_logic_vector(47 downto 0);
		Rd_Clk : IN std_logic;
		Rd_en : IN std_logic;
		Rd_Addr : IN std_logic_vector(13 downto 0);
		PHY_RXD : IN std_logic_vector(3 downto 0);
		PHY_RXC : IN std_logic;
		PHY_RXDV : IN std_logic;          
		Rd_data : OUT std_logic_vector(7 downto 0);
		Frm_valid : OUT std_logic
                -- buf_wr_en : out std_logic
		);
	END COMPONENT;
	
begin

Inst_Mac_RX2: Mac_RX2 PORT MAP(
		reset => not rst_n,
		MAC_addr => MAC_addr,
		Rd_Clk => Rd_Clk,
		Rd_en => Rd_en,
		Rd_Addr => Rd_Addr,
		Rd_data => Rd_data,
		Frm_valid => Frm_valid,
		PHY_RXD => PHY_RXD,
		PHY_RXC => PHY_RXC,
		PHY_RXDV => PHY_RXDV
                -- buf_wr_en => buf_wr_en
	);

--  frm_valid_d_ps: process (Rd_clk, rst_n) is
--  begin  -- process frm_valid_d
--    if Rd_clk'event and Rd_clk = '1' then  -- rising clock edge
--      frm_valid_d<=frm_valid;
--    end if;
--  end process frm_valid_d_ps;
--  
--  Rd_en_ps: process (Rd_clk,rst_n,frm_valid,frm_valid_d) is
--  begin  -- process Rd_en_ps
--    if rst_n = '0' then                 -- asynchronous reset (active low)
--      Rd_en<='0';
--    elsif Rd_clk'event and Rd_clk = '1' then
--    if frm_valid_d = '0' and frm_valid = '1' then  -- rising clock edge
--      Rd_en<='1';
--    elsif Rd_Addr>=x"42" then
--      Rd_en<='0';
--    end if;
--  end if;
--  end process Rd_en_ps;
--
--Rd_Addr_ps: process (Rd_clk, rst_n) is
--begin  -- process Rd_Addr_ps
--  if rst_n = '0' then                   -- asynchronous reset (active low)
--    Rd_Addr<=(others => '0');
--  elsif Rd_clk'event and Rd_clk = '1' then  -- rising clock edge
--    if Rd_Addr<=x"42" and Rd_en = '1'then
--    Rd_Addr<=Rd_Addr + 1;
--    elsif Rd_en = '0' or Rd_Addr>x"41" then
--      Rd_Addr<=(others => '0');
--  end if;
--end if;
--end process Rd_Addr_ps;

end Behavioral;

