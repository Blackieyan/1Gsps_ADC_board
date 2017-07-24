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
    -- rst_n_gb_i                : in     std_logic; 
    PHY_TXD_o                 : out    std_logic_vector(3 downto 0); 
    PHY_GTXclk_quar           : out    std_logic; 
    phy_txen_quar             : out    std_logic; 
    phy_txer_o                : out    std_logic; 
    user_pushbutton           : in     std_logic; 
    rst_n_o                   : out    std_logic;  --for test,generate from Gcnt
    fifo_upload_data          : in     std_logic_vector(7 downto 0);  --测试时在中间层用叫做data的计数器代替了这个外部数据流
    ---------------------------------------------------------------------------
    Rd_data                   : out    std_logic_vector(7 downto 0); 
    Rd_clk                    : in     std_logic; 
    Rd_en                     : in     std_logic; 
    Rd_Addr                   : in     std_logic_vector(13 downto 0); 
    Frm_valid                 : out    std_logic; 
    ---------------------------------------------------------------------------   
    PHY_RXD                   : in     std_logic_vector(3 downto 0); 
    PHY_RXC                   : in     std_logic; 
    PHY_RXDV                  : in     std_logic; 
    CLK_125M                  : in     std_logic; 
    CLK_125M_quar             : in     std_logic; 
-------------------------------------------------------------------------------
    -- ram_wren                  : buffer std_logic; 
    ram_rden                  : out    std_logic; 
    -- ram_start                 : in     std_logic;
    -- ram_last                  : in     std_logic;
    -- srcc1_p_trigin            : in     std_logic;
    -- SRCC1_n_upload_sma_trigin : in     std_logic;
    -- upload_trig_ethernet      : in     std_logic;
    posedge_upload_trig       : in     std_logic;
    TX_dst_MAC_addr           : in     std_logic_vector(47 downto 0);
    TX_src_MAC_addr : in std_logic_vector(3 downto 0);
    sample_en                 : in     std_logic;
 ------------------------------------------------------------------------------
    CH_flag                   : in     std_logic_vector(7 downto 0);
    -- ch_stat                   : in     std_logic_vector(1 downto 0);
    mult_frame_en               : in     std_logic;
    sw_ram_last : in std_logic;
    data_strobe : out std_logic;
    ether_trig : in std_logic
    );
end G_ethernet_top; 

architecture Behavioral of G_ethernet_top is
  -----------------------------------------------------------------------------
  attribute keep : boolean; 
  signal rst_n   : std_logic; 
  -----------------------------------------------------------------------------
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
      CLK_125M_quar             : in     std_logic; 
      CLK_125M                  : in     std_logic; 
      user_pushbutton           : in     std_logic; 
      fifo_upload_data          : in     std_logic_vector(7 downto 0); 
      PHY_TXD_o                 : out    std_logic_vector(3 downto 0); 
      PHY_GTXclk_quar           : out    std_logic; 
      phy_txen_quar             : out    std_logic; 
      phy_txer_o                : out    std_logic; 
      rst_n_o                   : out    std_logic;
      -- ram_wren                  : buffer std_logic; 
      ram_rden                  : out    std_logic; 
      posedge_upload_trig       : in     std_logic;
      TX_dst_MAC_addr           : in     std_logic_vector(47 downto 0);
      TX_src_MAC_addr : in std_logic_vector(3 downto 0);
      sample_en                 : in     std_logic;
      CH_flag                   : in     std_logic_vector(7 downto 0);
      -- ch_stat                   : in     std_logic_vector(1 downto 0);
      mult_frame_en               : in     std_logic;
      sw_ram_last : in std_logic;
      data_strobe :out std_logic;
      ether_trig : in std_logic
      );
  end component;

begin
 
--  Rd_clk<=CLK_71M;
  rst_n <= user_pushbutton; 
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
    rst_n     => rst_n,
    Rd_clk    => Rd_clk,
    Rd_en     => rd_en,
    Rd_Addr   => Rd_Addr,
    PHY_RXD   => PHY_RXD,
    PHY_RXC   => PHY_RXC,
    PHY_RXDV  => PHY_RXDV,
    Rd_data   => Rd_data,
    Frm_valid => Frm_valid
    -- buf_wr_en => wr_en
    );

  Inst_G_ethernet_Tx_data : G_ethernet_Tx_data port map(
    CLK_125M_quar             => CLK_125M_quar, 
    CLK_125M                  => CLK_125M, 
    -- rst_n_gb_i                => rst_n_gb_i, 
    PHY_TXD_o                 => PHY_TXD_o, 
    PHY_GTXclk_quar           => PHY_GTXclk_quar, 
    phy_txen_quar             => phy_txen_quar, 
    phy_txer_o                => phy_txer_o, 
    user_pushbutton           => user_pushbutton, 
    rst_n_o                   => rst_n_o,
    fifo_upload_data          => fifo_upload_data, 
    ram_rden                  => ram_rden, 
    -- ram_wren                  => ram_wren, 
    -- ram_start                 => ram_start,
    -- srcc1_p_trigin            => srcc1_p_trigin,
    -- SRCC1_n_upload_sma_trigin => SRCC1_n_upload_sma_trigin,
    -- upload_trig_ethernet      => upload_trig_ethernet,
    -- ram_last                  => ram_last,
    posedge_upload_trig       => posedge_upload_trig,
    TX_dst_MAC_addr           => TX_dst_MAC_addr,
    TX_src_MAC_addr => TX_src_MAC_addr,
    sample_en                 => sample_en,
    CH_flag                   => CH_flag,
    -- ch_stat                   => ch_stat,
    mult_frame_en              => mult_frame_en,
    sw_ram_last =>sw_ram_last,                                                    
    data_strobe =>data_strobe,
    ether_trig =>ether_trig                                                    
    );


end Behavioral; 

