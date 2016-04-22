----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:34:03 03/19/2016 
-- Design Name: 
-- Module Name:    G_ethernet_top - Behavioral 
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

entity G_ethernet_top is
  port (
    -- Osc_in_p         : in  std_logic;
    -- Osc_in_n         : in  std_logic;
    rst_n_gb_i       : in  std_logic;
    PHY_TXD_o        : out std_logic_vector(3 downto 0);
    PHY_GTXclk_quar  : out std_logic;
    phy_txen_quar    : out std_logic;
    phy_txer_o       : out std_logic;
    user_pushbutton  : in  std_logic;
    rst_n_o          : out std_logic;   --for test,generate from Gcnt
    -- SRCC1_p          : out std_logic;
    -- SRCC1_n          : out std_logic;
    -- MRCC2_p          : out std_logic;
    -- MRCC2_n          : out std_logic;
    fifo_upload_data : in  std_logic_vector(7 downto 0);  --测试时在中间层用叫做data的计数器代替了这个外部数据流
    ---------------------------------------------------------------------------
     Rd_data : out std_logic_vector(7 downto 0);
	  Rd_clk : in std_logic;
     Rd_en : in std_logic;
     Rd_Addr : in std_logic_vector(13 downto 0); 
     Frm_valid : out std_logic; 
    ---------------------------------------------------------------------------	  
    PHY_RXD : in std_logic_vector(3 downto 0);
    PHY_RXC : in std_logic;
    PHY_RXDV : in std_logic;


    CLK_125M :in std_logic;
    CLK_125M_quar : in std_logic;
--    CLK_71M : in std_logic;
-------------------------------------------------------------------------------
    ram_wren : out std_logic;
    ram_rden : out std_logic
    );
end G_ethernet_top;

architecture Behavioral of G_ethernet_top is
  -----------------------------------------------------------------------------
  attribute keep  : boolean;
  signal CLK_250M : std_logic;
  attribute keep of CLK_250M : signal is true;
  -- signal CLK_125M : std_logic;
  -- signal CLK_125M_quar : std_logic;
  -- signal CLK_71M : std_logic;
--  signal Rd_clk : std_logic;
--  signal Rd_en : std_logic;
--  signal Rd_Addr : std_logic_vector(13 downto 0);
  signal rst_n : std_logic;
  signal PHY_RXC_g : std_logic;
--  signal Frm_valid : std_logic;
  signal frm_valid_d : std_logic;
  -- signal ram_wren : std_logic;
  -- signal ram_rden : std_logic;
  -- signal ram_full : std_logic;
  -- signal fifo_upload_data : std_logic_vector(7 downto 0);
  -----------------------------------------------------------------------------
--  component ethernet_dcm
--    port
--      (                                 -- Clock in ports
--        CLK_IN1_P     : in  std_logic;
--        CLK_IN1_N     : in  std_logic;
--        -- Clock out ports
--        CLK_125M      : out std_logic;
--        CLK_125M_quar : out std_logic;
--        CLK_250M      : out std_logic;
--        CLK_OUT4 : out std_logic
--        );
--  end component;
--  ---------------------------------------------------------------------------
  component G_ehernet_Rx_data
    port(
      rst_n     : in  std_logic;
      Rd_clk    : in  std_logic;
      Rd_en     : in  std_logic;
      Rd_Addr   : in  std_logic_vector(13 downto 0);
      PHY_RXD   : in  std_logic_vector(3 downto 0);
      PHY_RXC   : in  std_logic;
      PHY_RXDV  : in  std_logic;
      Rd_data   : out std_logic_vector(7 downto 0);
      Frm_valid : out std_logic
      );
  end component;

  component G_ethernet_Tx_data
    port(
      CLK_125M_quar    : in  std_logic;
      CLK_125M         : in  std_logic;
      rst_n_gb_i       : in  std_logic;
      user_pushbutton  : in  std_logic;
      fifo_upload_data : in  std_logic_vector(7 downto 0);
      PHY_TXD_o        : out std_logic_vector(3 downto 0);
      PHY_GTXclk_quar  : out std_logic;
      phy_txen_quar    : out std_logic;
      phy_txer_o       : out std_logic;
      rst_n_o          : out std_logic;
      ram_wren : out std_logic;
      ram_rden : out std_logic
      );
  end component;

begin
 
--  Rd_clk<=CLK_71M;
  rst_n<=user_pushbutton;
  -----------------------------------------------------------------------------
  -- dcm_ethernet : ethernet_dcm
  --   port map
  --   (                                   -- Clock in ports
  --     CLK_IN1_P     => osc_IN_P,
  --     CLK_IN1_N     => osc_IN_N,
  --     -- Clock out ports
  --     CLK_125M      => CLK_125M,
  --     CLK_125M_quar => CLK_125M_quar,
  --     CLK_250M      => CLK_250M,
  --     CLK_OUT4 => CLK_71M);
  ---------------------------------------------------------------------------
  Inst_G_ehernet_Rx_data : G_ehernet_Rx_data port map(
    rst_n    => rst_n,
    Rd_clk   => Rd_clk,
    Rd_en    => rd_en,
    Rd_Addr  => Rd_Addr,
    PHY_RXD  => PHY_RXD,
    PHY_RXC  => PHY_RXC,
    PHY_RXDV => PHY_RXDV,
    Rd_data  => Rd_data,
    Frm_valid => Frm_valid
    -- buf_wr_en => wr_en
    );

  Inst_G_ethernet_Tx_data : G_ethernet_Tx_data port map(
    CLK_125M_quar   => CLK_125M_quar,
    CLK_125M        => CLK_125M,
    rst_n_gb_i      => rst_n_gb_i,
    PHY_TXD_o       => PHY_TXD_o,
    PHY_GTXclk_quar => PHY_GTXclk_quar,
    phy_txen_quar   => phy_txen_quar,
    phy_txer_o      => phy_txer_o,
    user_pushbutton => user_pushbutton,
    rst_n_o         => rst_n_o,
    fifo_upload_data => fifo_upload_data,
    ram_rden => ram_rden,
    ram_wren => ram_wren
    );

--    IBUFG_inst : IBUFG
--    generic map (
--       IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
--       IOSTANDARD => "DEFAULT")
--    port map (
--       O => phy_rxc_g, -- Clock buffer output
--       I => phy_rxc  -- Clock buffer input (connect directly to top-level port)
--    );
--	 


end Behavioral;

