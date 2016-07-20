----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:31:10 12/10/2015 
-- Design Name: 
-- Module Name:    ZJUprojects - Behavioral 
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

entity ZJUprojects is
  port(
    OSC_in_n                             : in     std_logic;
    OSC_in_p                             : in     std_logic;
    GHz_in_n                             : in     std_logic;
    GHz_in_p                             : in     std_logic;
---------------------------------------------------------------------------
    ADC_Mode                             : out std_logic;
    ADC_sclk_OUT                         : out std_logic;
    ADC_sldn_OUT                         : out std_logic;
    ADC_sdata                            : out std_logic_vector(0 downto 0);  --ADC interface
-------------------------------------------------------------------------------
    spi_clk                              : out    std_logic;
    spi_mosi                             : out    std_logic;
    spi_le                               : out    std_logic;
    spi_syn                              : out    std_logic;
    spi_miso                             : in     std_logic;
    spi_powerdn                          : inout    std_logic;
    spi_revdata                          : out    std_logic_vector(31 downto 0);
    cfg_finish                           : out    std_logic;  --CDCE62005
    -- spi_pd                               : inout std_logic;
-------------------------------------------------------------------------------
    test                                 : out    std_logic_vector(0 downto 0);
    user_pushbutton                      : in     std_logic;  --glbclr_n
    ---------------------------------------------------------------------------
    ADC_CLKOI_p                          : in     std_logic;  -- ADC CLKOI 500MHz/250MHz
    ADC_CLKOI_n                          : in     std_logic;
    ADC_CLKOQ_p                          : in     std_logic;
    ADC_CLKOQ_n                          : in     std_logic;
    ADC_DOIA_p                           : in     std_logic_vector(7 downto 0);
    ADC_DOIA_n                           : in     std_logic_vector(7 downto 0);
    ADC_DOIB_p                           : in     std_logic_vector(7 downto 0);
    ADC_DOIB_n                           : in     std_logic_vector(7 downto 0);
    ADC_DOQA_p                           : in     std_logic_vector(7 downto 0);
    ADC_DOQA_n                           : in     std_logic_vector(7 downto 0);
    ADC_DOQB_p                           : in     std_logic_vector(7 downto 0);
    ADC_DOQB_n                           : in     std_logic_vector(7 downto 0);
    DOIRI_p                              : in     std_logic;
    DOIRI_n                              : in     std_logic;
    DOIRQ_p                              : in     std_logic;
    DOIRQ_n                              : in     std_logic;
    SRCC1_p_trigin                       : in    std_logic;
    SRCC1_n_upload_sma_trigin                : in    std_logic;
    MRCC2_p                              : out    std_logic;
    MRCC2_n                              : out    std_logic_vector(0 downto 0);
    ---------------------------------------------------------------------------
    -- USB_data : inout std_logic_vector(15 downto 0);  --USB
    -- USB_DataEPFull : in std_logic;
    -- USB_CmdEPEmpty : in std_logic;
    -- USB_SLRD : out std_logic;
    -- USB_SLOE : out std_logic;
    -- USB_SLWR : out std_logic;
    -- USB_PKTEND : out std_logic;
    -- USB_IFCLK :out std_logic;
    -- USB_FIFOADR : out std_logic_vector(1 downto 0);
    --      USB_RST :out std_logic
    ---------------------------------------------------------------------------
               -- ethernet_rst_n_gb_i       : IN     std_logic;
--               ethernet_Rd_clk           : IN     std_logic;
--               ethernet_Rd_en            : IN     std_logic;
--               ethernet_Rd_Addr          : IN     std_logic_vector(13 downto 0);
               PHY_RXD                   : IN     std_logic_vector(3 downto 0);
               PHY_RXC                  : IN     std_logic;
               PHY_RXDV                 : IN     std_logic;
               PHY_TXD_o                : OUT    std_logic_vector(3 downto 0);
               PHY_GTXclk_quar          : OUT    std_logic;
                PHy_txen_quar            : OUT    std_logic;
                phy_txer_o               : OUT    std_logic;
                -- ethernet_Rd_data         : buffer    std_logic_vector(7 downto 0);
--                ethernet_Frm_valid       : OUT    std_logic;
                phy_rst_n_o : out std_logic
                
    );
end ZJUprojects;

architecture Behavioral of ZJUprojects is
  signal clk2_cnt     : std_logic_vector(31 downto 0) := x"00000000";
-------------------------------------------------------------------------------
  signal cdce62005_en : std_logic;
  signal clk_spi      : std_logic;  --make clear what is the function of clk_spi
-------------------------------------------------------------------------------
  -- signal OSC_clk : std_logic;
  signal OSC_in       : std_logic;
  signal GHz_in : std_logic;
  signal clk1         : std_logic;
  signal clk2         : std_logic;
  signal clk3         : std_logic;
  signal CLK5_200MHz : std_logic;
  signal CLK6_20MHz : std_logic;
--   signal spi_mosi : std_logic;
-------------------------------------------------------------------------------
  signal rst_gb : std_logic;               --global signal
  -----------------------------------------------------------------------------
  signal full_IA1 : std_logic;          -- fifo_i
  signal empty_IA1 : std_logic;
  signal valid_IA1 : std_logic;
  signal almost_full_IA1 : std_logic;
  signal din_Q : std_logic_vector(31 downto 0);
  -- signal full_IA2 : std_logic;
  -- signal empty_IA2 : std_logic;
  -- signal valid_IA2 : std_logic;
  -- signal almost_full_IA2 : std_logic;
  --   signal full_IB1 : std_logic;
  -- signal empty_IB1 : std_logic;
  -- signal valid_IB1 : std_logic;
  -- signal almost_full_IB1 : std_logic;
  -- signal full_IB2 : std_logic;
  -- signal empty_IB2 : std_logic;
  -- signal valid_IB2 : std_logic;
  -- signal almost_full_IB2 : std_logic;
  -----------------------------------------------------------------------------
  signal full_QA1 : std_logic;          -- fifo_q
  signal empty_QA1 : std_logic;
  signal valid_QA1 : std_logic;
  signal almost_full_QA1 : std_logic;
  --   signal full_QA2 : std_logic;
  -- signal empty_QA2 : std_logic;
  -- signal valid_QA2 : std_logic;
  -- signal almost_full_QA2 : std_logic;
  -- signal full_QB1 : std_logic;
  -- signal empty_QB1 : std_logic;
  -- signal valid_QB1 : std_logic;
  -- signal almost_full_QB1 : std_logic;
  --   signal full_QB2 : std_logic;
  -- signal empty_QB2 : std_logic;
  -- signal valid_QB2 : std_logic;
  -- signal almost_full_QB2 : std_logic;
  -----------------------------------------------------------------------------
  signal wr_en : std_logic;
  signal rd_en : std_logic;
  
  -----------------------------------------------------------------------------
   attribute keep : boolean;
  signal ADC_DOIA_1 : std_logic_vector(7 downto 0);  -- ADC data receiver
    signal ADC_DOIA_2 : std_logic_vector(7 downto 0);
    signal ADC_DOIB_1 : std_logic_vector(7 downto 0);
    signal ADC_DOIB_2 : std_logic_vector(7 downto 0);
    signal ADC_DOQA_1 : std_logic_vector(7 downto 0);
    signal ADC_DOQA_2 : std_logic_vector(7 downto 0);
    signal ADC_DOQB_1 : std_logic_vector(7 downto 0);
    signal ADC_DOQB_2 : std_logic_vector(7 downto 0);
  signal ADC_DOIA_1_out : std_logic_vector(7 downto 0);
  signal ADC_DOIA_2_out : std_logic_vector(7 downto 0);
  signal ADC_DOIB_1_out : std_logic_vector(7 downto 0);
  signal ADC_DOIB_2_out : std_logic_vector(7 downto 0);
  signal ADC_DOQA_1_out : std_logic_vector(7 downto 0);
  signal ADC_DOQA_2_out : std_logic_vector(7 downto 0);
  signal ADC_DOQB_1_out : std_logic_vector(7 downto 0);
  signal ADC_DOQB_2_out : std_logic_vector(7 downto 0);
  signal ADC_DOIA       : std_logic_vector(7 downto 0);
  signal ADC_DOIB : std_logic_vector(7 downto 0);
  signal ADC_DOQA : std_logic_vector(7 downto 0);
  signal ADC_DOQB : std_logic_vector(7 downto 0);
  signal ADC_clkoi_inv : std_logic;
  signal ADC_clkoq_inv : std_logic;
  signal ADC_doqa_delay : std_logic_vector(7 downto 0);
  signal ADC_doqb_delay : std_logic_vector(7 downto 0); 
  signal ADC_DOQA_1_d : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOQA_1_d : signal is true;
  signal ADC_DOQA_2_d : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOQA_2_d : signal is true;
  signal ADC_DOQB_1_d : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOQB_1_d : signal is true;
  signal ADC_DOQB_2_d : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOQB_2_d : signal is true;
  signal ADC_CLKOI : std_logic;
  attribute keep of ADC_CLKOI : signal is true;
  signal ADC_CLKOQ            : std_logic;
  signal rst_gb_d             : std_logic;
  signal rst_n : std_logic;
  signal posedge_upload_trig : std_logic;
 
  attribute keep of rst_gb_d  : signal is true;
  signal OIcounter            : std_logic_vector(7 downto 0);
  attribute keep of OIcounter : signal is true;
  signal OQcounter            : std_logic_vector(7 downto 0);
  attribute keep of OQcounter : signal is true;
  attribute IODELAY_GROUP     : string;
  -----------------------------------------------------------------------------
  -- signal fd : std_logic_vector(15 downto 0); --usb module
  -- -- signal DataEPFull : std_logic;
  -- -- signal CmdEPEmpty : std_logic;
  -- signal usb_start : std_logic;
  -- signal usb_clr :std_logic;
  -- signal data_in_usb : std_logic_vector(15 downto 0);
  -- signal dout : std_logic_vector(15 downto 0);
  -- signal clk_div_cnt :std_logic_vector(7 downto 0);
  -- constant Div_multi :std_logic_vector(3 downto 0) := "1010";
  -- signal usb_SCLK : std_logic;
  -----------------------------------------------------------------------------
  signal CLK_250M : std_logic;
  attribute keep of CLK_250M : signal is true;
  signal CLK_125M : std_logic;
  signal CLK_125M_quar : std_logic;
  signal CLK_71M : std_logic;
   signal ethernet_Rd_clk : std_logic;
   signal ethernet_Rd_en : std_logic;
   signal ethernet_Rd_addr : std_logic_vector(13 downto 0);
	signal ethernet_frm_valid : std_logic;
	signal frm_valid_d : std_logic;
	signal ethernet_rd_data : std_logic_vector(7 downto 0);
    attribute keep of ethernet_Rd_data : signal is true;
  -- signal rst_n : std_logic;
  signal ethernet_fifo_upload_data : std_logic_vector(7 downto 0);
  signal ethernet_rst_n_gb_i : std_logic;
  signal cmd_frm_length : std_logic_vector(15 downto 0);
  signal cmd_frm_type : std_logic_vector(15 downto 0);
  -- signal start_sample : std_logic;

  signal phy_rxc_g :std_logic;
  -----------------------------------------------------------------------------
    signal ram_doutb : std_logic_vector(7 downto 0);  --ram control
    attribute keep of ram_doutb : signal is true;
  signal ram_dina : std_logic_vector(31 downto 0);
  signal ram_clka : std_logic;
  signal ram_clkb : std_logic;
  signal ram_rstb : std_logic;
  signal ram_ena : std_logic;
  signal ram_enb : std_logic;
  signal ram_wea : std_logic_vector(0 downto 0);
  -- signal dina_1 : std_logic_vector(7 downto 0);
  -- signal dina_2 : std_logic_vector(7 downto 0);
  -- signal dina_3 : std_logic_vector(7 downto 0);
  -- signal dina_4 : std_logic_vector(7 downto 0);
  signal ram_addra : std_logic_vector(13 downto 0);
  signal ram_addrb : std_logic_vector(15 downto 0);
  signal clr_n_ram : std_logic;
  signal ram_last : std_logic;
  signal ram_q_last : std_logic;
  signal ram_i_last : std_logic;
  signal ram_rst : std_logic;
    attribute keep of ram_rst : signal is true;
  signal ram_start : std_logic;
  signal  upload_trig_ethernet : std_logic;
  signal ram_start_d : std_logic;
  signal ram_start_d2 : std_logic;
  signal trigin_d2 : std_logic;
  signal trigin_d : std_logic;
  signal ram_wren : std_logic;
  signal ram_rden : std_logic;
  signal ram_full : std_logic;
  signal ram_q_full : std_logic;
  signal ram_i_full : std_logic;
  -----------------------------------------------------------------------------
  signal ram_i_doutb : std_logic_vector(7 downto 0);
  attribute keep of ram_i_doutb : signal is true;
  signal ram_i_dina : std_logic_vector(31 downto 0);
  signal ram_i_clka : std_logic;
  signal ram_i_clkb : std_logic;
  signal ram_i_rstb : std_logic;
  signal ram_i_ena : std_logic;
  signal ram_i_enb : std_logic;
  signal ram_i_wea : std_logic_vector(0 downto 0);
  signal ram_i_addra : std_logic_vector(13 downto 0);
  signal ram_i_addrb : std_logic_vector(15 downto 0);
  signal ram_i_rst : std_logic;
  signal ADC_doia_delay : std_logic_vector(7 downto 0);
  signal ADC_doib_delay : std_logic_vector(7 downto 0); 
  signal ADC_DOiA_1_d : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOiA_1_d : signal is true;
  signal ADC_DOiA_2_d : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOiA_2_d : signal is true;
  signal ADC_DOiB_1_d : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOiB_1_d : signal is true;
  signal ADC_DOiB_2_d : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOiB_2_d : signal is true;
  signal ram_switch : std_logic_vector(2 downto 0);
  signal SRCC1_n_upload_sma_trigin_d : std_logic;
  signal SRCC1_n_upload_sma_trigin_d2 : std_logic;
  signal upload_trig_ethernet_d: std_logic;
  signal upload_trig_ethernet_d2: std_logic;
  -----------------------------------------------------------------------------
  component CDCE62005_config
    port(
      clk         : in  std_logic;
      clk_spi     : in  std_logic;
      en          : in  std_logic;
      spi_miso    : in  std_logic;
      spi_clk     : out std_logic;
      spi_mosi    : out std_logic;
      spi_le      : out std_logic;
      spi_syn     : out std_logic;
      spi_powerdn : out std_logic;
      cfg_finish  : out std_logic;
      spi_revdata : out std_logic_vector(31 downto 0)
      );
  end component;
  -------------------------------------------------------------------------------
  component ADC_interface
    port(
      clk2 : in std_logic;
      CLK1         : in  std_logic;
      user_pushbutton : in std_logic;
      ADC_Mode     : out std_logic;
      ADC_sclk_OUT : out std_logic;
      ADC_sldn_OUT : out std_logic;
      ADC_sdata    : out std_logic_vector(0 to 0)
      );
  end component;
-------------------------------------------------------------------------------
  	-- COMPONENT usb2_interface
	-- PORT(
	-- 	clk_20m : IN std_logic;
	-- 	clk_10m : in std_logic;
	-- 	rst_n : IN std_logic;
	-- 	DataEPFull : IN std_logic;
	-- 	CmdEPEmpty : IN std_logic;
	-- 	data_in_usb : IN std_logic_vector(15 downto 0);    
	-- 	USB_data : INOUT std_logic_vector(15 downto 0);      
	-- 	EPADDR : OUT std_logic_vector(1 downto 0);
	-- 	SLRD : OUT std_logic;
	-- 	SLOE : OUT std_logic;
	-- 	SLWR : OUT std_logic;
	-- 	PKTEND : OUT std_logic;
	-- 	IFCLk : OUT std_logic;
	-- 	usb_start : OUT std_logic;
	-- 	usb_clr : OUT std_logic;
	-- 	dout : out std_logic_vector(15 downto 0)
	-- 	);
	-- END COMPONENT;
  -----------------------------------------------------------------------------
	COMPONENT G_ethernet_top
	PORT(
		rst_n_gb_i : IN std_logic;
		user_pushbutton : IN std_logic;
		fifo_upload_data : IN std_logic_vector(7 downto 0);
		Rd_clk : IN std_logic;
		Rd_en : IN std_logic;
		Rd_Addr : IN std_logic_vector(13 downto 0);
		PHY_RXD : IN std_logic_vector(3 downto 0);
		PHY_RXC : IN std_logic;
		PHY_RXDV : IN std_logic;
		CLK_125M : IN std_logic;
		CLK_125M_quar : IN std_logic;          
		PHY_TXD_o : OUT std_logic_vector(3 downto 0);
		PHY_GTXclk_quar : OUT std_logic;
		phy_txen_quar : OUT std_logic;
		phy_txer_o : OUT std_logic;
		rst_n_o : OUT std_logic;
		Rd_data : OUT std_logic_vector(7 downto 0);
		Frm_valid : OUT std_logic;
		ram_wren : buffer std_logic;
		ram_rden : OUT std_logic;
           ram_start : in std_logic;
           srcc1_p_trigin : in std_logic;
           ram_last : in std_logic;
           SRCC1_n_upload_sma_trigin : in std_logic;
           upload_trig_ethernet : in std_logic
		);
	END COMPONENT;
  -----------------------------------------------------------------------------
        COMPONENT command_analysis
	PORT(
		rd_data : IN std_logic_vector(7 downto 0);
		rd_clk : IN std_logic;
		rd_addr : IN std_logic_vector(13 downto 0);
		rd_en : IN std_logic;          
		frm_length : OUT std_logic_vector(15 downto 0);
		frm_type : OUT std_logic_vector(15 downto 0);
		-- mac_dst : OUT std_logic_vector(47 downto 0);
		-- mac_src : OUT std_logic_vector(47 downto 0);
		-- reg_addr : OUT std_logic_vector(15 downto 0);
		-- reg_data : OUT std_logic_vector(31 downto 0);
	         ram_start  : buffer std_logic;
                user_pushbutton : in std_logic;
                ram_switch : out std_logic_vector(2 downto 0);
                upload_trig_ethernet : buffer std_logic
		);
	END COMPONENT;
  -----------------------------------------------------------------------------
  component dcm
    port
      (                                 -- Clock in ports
        CLK_IN1_P : in  std_logic;
        CLK_IN1_N : in  std_logic;
        -- Clock out ports
        CLK_OUT1  : out std_logic;      --100mhz
        CLK_OUT2  : out std_logic;      -- 10mhz
        CLK_OUT3  : out std_logic;      -- 71mhz
        CLK_OUT4  : out std_logic;      -- 500mhz
        CLK_OUT5  : out std_logic;      -- 200mhz
        CLK_OUT6 : out std_logic;  -- 125mhz
        CLK_out7 : out std_logic  -- 125mhz quar
        );
  end component;

  component dcm_adc_clkoi
port
 (-- Clock in ports
  CLK_IN1_P         : in     std_logic;
  CLK_IN1_N         : in     std_logic;
  -- Clock out ports
  ADC_clkoi          : out    std_logic;
  ADC_clkoi_inv          : out    std_logic
 );
end component;

component dcm_adc_clkoq
port
 (-- Clock in ports
  CLK_IN1_P         : in     std_logic;
  CLK_IN1_N         : in     std_logic;
  -- Clock out ports
  ADC_clkoq          : out    std_logic;
  ADC_clkoq_inv          : out    std_logic
 );
end component;
component dcm_rxc
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic
 );
end component;
-------------------------------------------------------------------------------
  COMPONENT fifo
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

  COMPONENT ram_data
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    rstb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

  COMPONENT ram_data_i
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    rstb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;
-------------------------------------------------------------------------------
	COMPONENT IDDR_inst
	PORT(
		CLK : IN std_logic;
		D : IN std_logic_vector(7 downto 0);          
		Q1 : OUT std_logic_vector(7 downto 0);
		Q2 : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;
-------------------------------------------------------------------------------
  	COMPONENT IBUFD_8bit
	PORT(
		I : IN std_logic_vector(7 downto 0);
		IB : IN std_logic_vector(7 downto 0);          
		O : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;      
-------------------------------------------------------------------------------

---------------------------------------------------------------------------------primitive instantiation       
begin
  ----------------------------------------------------------------------------
  dcm1 : dcm
    port map
    (                                   -- Clock in ports
      CLK_IN1_P => OSC_in_p,
      CLK_IN1_N => OSC_in_n,
      -- Clock out ports
      CLK_OUT1  => CLK1,                --100MHz
      CLK_OUT2  => CLK2,                --5MHz
      CLK_OUT3  => CLK_71M,                -- 71mhz inv
      CLK_OUT4  => open,                -- for chipscope
      CLK_OUT5 => CLK5_200MHz,          -- iodley ctrl
		CLK_OUT6 => CLK_125M,  -- for ethernet 
      CLK_OUT7 => CLK_125M_quar
      );               --10MHz 50shift

 dcm2 : dcm_adc_clkoi
  port map
   (-- Clock in ports
    CLK_IN1_P => ADC_CLKOI_p,
    CLK_IN1_N => ADC_CLKOI_n,
    -- Clock out ports
    ADC_clkoi => ADC_clkoi,
    ADC_clkoi_inv =>  ADC_clkoi_inv);

  dcm3 : dcm_adc_clkoq
  port map
   (-- Clock in ports
    CLK_IN1_P => ADC_CLKOQ_p,
    CLK_IN1_N => ADC_CLKOQ_n,
    -- Clock out ports
    ADC_clkoq => ADC_clkoq,
    ADC_clkoq_inv => ADC_clkoq_inv);
	
    --         IBUFG_inst : IBUFG
    -- generic map (
    --    IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
    --    IOSTANDARD => "DEFAULT")
    -- port map (
    --    O => phy_rxc_g, -- Clock buffer output
    --    I => phy_rxc  -- Clock buffer input (connect directly to top-level port)
    -- );
	 
dcm_rxc_inst : dcm_rxc
  port map
   (-- Clock in ports
    CLK_IN1 => PHY_RXC,
    -- Clock out ports
    CLK_OUT1 => PHY_RXC_g);
-------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  	Inst_IBUFD_8bit1: IBUFD_8bit PORT MAP(  -- 数据差分转单端
		O =>ADC_DOQB ,
		I =>ADC_DOQB_p ,
		IB =>ADC_DOQB_n 
	);

  	Inst_IBUFD_8bit2: IBUFD_8bit PORT MAP(
		O =>ADC_DOQA ,
		I =>ADC_DOQA_p ,
		IB =>ADC_DOQA_n 
	);
    	Inst_IBUFD_8bit3: IBUFD_8bit PORT MAP(
		O =>ADC_DOIB ,
		I =>ADC_DOIB_p ,
		IB =>ADC_DOIB_n 
	);
    	Inst_IBUFD_8bit4: IBUFD_8bit PORT MAP(
		O =>ADC_DOIA ,
		I =>ADC_DOIA_p ,
		IB =>ADC_DOIA_n 
	);
-------------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- io delay
ADC_doqa_inst: FOR i in 0 to 7 generate
begin
  specify_one: if i = 5 generate        --i=5为需要调整第5bit的延迟
    begin
IODELAYE1_inst : IODELAYE1
  generic map (
     CINVCTRL_SEL => FALSE,          -- Enable dynamic clock inversion (TRUE/FALSE)
     DELAY_SRC => "I",               -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
     HIGH_PERFORMANCE_MODE => FALSE, -- Reduced jitter (TRUE), Reduced power (FALSE)
     IDELAY_TYPE => "FIXED",       -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     IDELAY_VALUE => 0,              -- Input delay tap setting (0-31)
     ODELAY_TYPE => "FIXED",         -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     ODELAY_VALUE => 0,              -- Output delay tap setting (0-31)
     REFCLK_FREQUENCY => 200.0,      -- IDELAYCTRL clock input frequency in MHz
     SIGNAL_PATTERN => "DATA"        -- "DATA" or "CLOCK" input signal
  )
  port map (
     CNTVALUEOUT => open, -- 5-bit output: Counter value output
     DATAOUT => ADC_doqa_delay(i),         -- 1-bit output: Delayed data output
     C =>  '0',                     -- 1-bit input: Clock input
     CE => '0',                   -- 1-bit input: Active high enable increment/decrement input
     CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
     CLKIN => '0',             -- 1-bit input: Clock delay input
     CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
     DATAIN => '0',           -- 1-bit input: Internal delay data input
     IDATAIN => ADC_doqa(i),         -- 1-bit input: Data input from the I/O
     INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
     ODATAIN => '0',         -- 1-bit input: Output delay data input
     RST => '0',                 -- 1-bit input: Active-high reset tap-delay input
     T => '0'                      -- 1-bit input: 3-state input
  );
  end generate specify_one;
  
  universal: if i/=5 generate
IODELAYE1_inst : IODELAYE1
  generic map (
     CINVCTRL_SEL => FALSE,          -- Enable dynamic clock inversion (TRUE/FALSE)
     DELAY_SRC => "I",               -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
     HIGH_PERFORMANCE_MODE => FALSE, -- Reduced jitter (TRUE), Reduced power (FALSE)
     IDELAY_TYPE => "FIXED",       -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     IDELAY_VALUE => 0,              -- Input delay tap setting (0-31)
     ODELAY_TYPE => "FIXED",         -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     ODELAY_VALUE => 0,              -- Output delay tap setting (0-31)
     REFCLK_FREQUENCY => 200.0,      -- IDELAYCTRL clock input frequency in MHz
     SIGNAL_PATTERN => "DATA"        -- "DATA" or "CLOCK" input signal
  )
  port map (
     CNTVALUEOUT => open, -- 5-bit output: Counter value output
     DATAOUT => ADC_doqa_delay(i),         -- 1-bit output: Delayed data output
     C =>  '0',                     -- 1-bit input: Clock input
     CE => '0',                   -- 1-bit input: Active high enable increment/decrement input
     CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
     CLKIN => '0',             -- 1-bit input: Clock delay input
     CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
     DATAIN => '0',           -- 1-bit input: Internal delay data input
     IDATAIN => ADC_doqa(i),         -- 1-bit input: Data input from the I/O
     INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
     ODATAIN => '0',         -- 1-bit input: Output delay data input
     RST => '0',                 -- 1-bit input: Active-high reset tap-delay input
     T => '0'                      -- 1-bit input: 3-state input
  );
  end generate universal;
end generate;

-------------------------------------------------------------------------------
 ADC_doqb_inst: FOR i in 0 to 7 generate
begin
  specify_one: if i = 5 generate
    begin
IODELAYE1_inst : IODELAYE1
  generic map (
     CINVCTRL_SEL => FALSE,          -- Enable dynamic clock inversion (TRUE/FALSE)
     DELAY_SRC => "I",               -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
     HIGH_PERFORMANCE_MODE => FALSE, -- Reduced jitter (TRUE), Reduced power (FALSE)
     IDELAY_TYPE => "FIXED",       -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     IDELAY_VALUE => 0,              -- Input delay tap setting (0-31)
     ODELAY_TYPE => "FIXED",         -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     ODELAY_VALUE => 0,              -- Output delay tap setting (0-31)
     REFCLK_FREQUENCY => 200.0,      -- IDELAYCTRL clock input frequency in MHz
     SIGNAL_PATTERN => "DATA"        -- "DATA" or "CLOCK" input signal
  )
  port map (
     CNTVALUEOUT => open, -- 5-bit output: Counter value output
     DATAOUT => ADC_doqb_delay(i),         -- 1-bit output: Delayed data output
     C =>  '0',                     -- 1-bit input: Clock input
     CE => '0',                   -- 1-bit input: Active high enable increment/decrement input
     CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
     CLKIN => '0',             -- 1-bit input: Clock delay input
     CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
     DATAIN => '0',           -- 1-bit input: Internal delay data input
     IDATAIN => ADC_doqb(i),         -- 1-bit input: Data input from the I/O
     INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
     ODATAIN => '0',         -- 1-bit input: Output delay data input
     RST => '0',                 -- 1-bit input: Active-high reset tap-delay input
     T => '0'                      -- 1-bit input: 3-state input
  );
  end generate specify_one;
  
  universal: if i/=5 generate
IODELAYE1_inst : IODELAYE1
  generic map (
     CINVCTRL_SEL => FALSE,          -- Enable dynamic clock inversion (TRUE/FALSE)
     DELAY_SRC => "I",               -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
     HIGH_PERFORMANCE_MODE => FALSE, -- Reduced jitter (TRUE), Reduced power (FALSE)
     IDELAY_TYPE => "FIXED",       -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     IDELAY_VALUE => 0,              -- Input delay tap setting (0-31)
     ODELAY_TYPE => "FIXED",         -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     ODELAY_VALUE => 0,              -- Output delay tap setting (0-31)
     REFCLK_FREQUENCY => 200.0,      -- IDELAYCTRL clock input frequency in MHz
     SIGNAL_PATTERN => "DATA"        -- "DATA" or "CLOCK" input signal
  )
  port map (
     CNTVALUEOUT => open, -- 5-bit output: Counter value output
     DATAOUT => ADC_doqb_delay(i),         -- 1-bit output: Delayed data output
     C =>  '0',                     -- 1-bit input: Clock input
     CE => '0',                   -- 1-bit input: Active high enable increment/decrement input
     CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
     CLKIN => '0',             -- 1-bit input: Clock delay input
     CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
     DATAIN => '0',           -- 1-bit input: Internal delay data input
     IDATAIN => ADC_doqb(i),         -- 1-bit input: Data input from the I/O
     INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
     ODATAIN => '0',         -- 1-bit input: Output delay data input
     RST => '0',                 -- 1-bit input: Active-high reset tap-delay input
     T => '0'                      -- 1-bit input: 3-state input
  );
  end generate universal;
end generate;
-------------------------------------------------------------------------------
ADC_doia_inst: FOR i in 0 to 7 generate
begin
  specify_one: if i = 5 generate        --i=5为需要调整第5bit的延迟
    begin
IODELAYE1_inst : IODELAYE1
  generic map (
     CINVCTRL_SEL => FALSE,          -- Enable dynamic clock inversion (TRUE/FALSE)
     DELAY_SRC => "I",               -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
     HIGH_PERFORMANCE_MODE => FALSE, -- Reduced jitter (TRUE), Reduced power (FALSE)
     IDELAY_TYPE => "FIXED",       -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     IDELAY_VALUE => 0,              -- Input delay tap setting (0-31)
     ODELAY_TYPE => "FIXED",         -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     ODELAY_VALUE => 0,              -- Output delay tap setting (0-31)
     REFCLK_FREQUENCY => 200.0,      -- IDELAYCTRL clock input frequency in MHz
     SIGNAL_PATTERN => "DATA"        -- "DATA" or "CLOCK" input signal
  )
  port map (
     CNTVALUEOUT => open, -- 5-bit output: Counter value output
     DATAOUT => ADC_doia_delay(i),         -- 1-bit output: Delayed data output
     C =>  '0',                     -- 1-bit input: Clock input
     CE => '0',                   -- 1-bit input: Active high enable increment/decrement input
     CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
     CLKIN => '0',             -- 1-bit input: Clock delay input
     CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
     DATAIN => '0',           -- 1-bit input: Internal delay data input
     IDATAIN => ADC_doia(i),         -- 1-bit input: Data input from the I/O
     INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
     ODATAIN => '0',         -- 1-bit input: Output delay data input
     RST => '0',                 -- 1-bit input: Active-high reset tap-delay input
     T => '0'                      -- 1-bit input: 3-state input
  );
  end generate specify_one;
  
  universal: if i/=5 generate
IODELAYE1_inst : IODELAYE1
  generic map (
     CINVCTRL_SEL => FALSE,          -- Enable dynamic clock inversion (TRUE/FALSE)
     DELAY_SRC => "I",               -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
     HIGH_PERFORMANCE_MODE => FALSE, -- Reduced jitter (TRUE), Reduced power (FALSE)
     IDELAY_TYPE => "FIXED",       -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     IDELAY_VALUE => 0,              -- Input delay tap setting (0-31)
     ODELAY_TYPE => "FIXED",         -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     ODELAY_VALUE => 0,              -- Output delay tap setting (0-31)
     REFCLK_FREQUENCY => 200.0,      -- IDELAYCTRL clock input frequency in MHz
     SIGNAL_PATTERN => "DATA"        -- "DATA" or "CLOCK" input signal
  )
  port map (
     CNTVALUEOUT => open, -- 5-bit output: Counter value output
     DATAOUT => ADC_doia_delay(i),         -- 1-bit output: Delayed data output
     C =>  '0',                     -- 1-bit input: Clock input
     CE => '0',                   -- 1-bit input: Active high enable increment/decrement input
     CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
     CLKIN => '0',             -- 1-bit input: Clock delay input
     CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
     DATAIN => '0',           -- 1-bit input: Internal delay data input
     IDATAIN => ADC_doia(i),         -- 1-bit input: Data input from the I/O
     INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
     ODATAIN => '0',         -- 1-bit input: Output delay data input
     RST => '0',                 -- 1-bit input: Active-high reset tap-delay input
     T => '0'                      -- 1-bit input: 3-state input
  );
  end generate universal;
end generate;

-------------------------------------------------------------------------------
 ADC_doib_inst: FOR i in 0 to 7 generate
begin
  specify_one: if i = 5 generate
    begin
IODELAYE1_inst : IODELAYE1
  generic map (
     CINVCTRL_SEL => FALSE,          -- Enable dynamic clock inversion (TRUE/FALSE)
     DELAY_SRC => "I",               -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
     HIGH_PERFORMANCE_MODE => FALSE, -- Reduced jitter (TRUE), Reduced power (FALSE)
     IDELAY_TYPE => "FIXED",       -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     IDELAY_VALUE => 0,              -- Input delay tap setting (0-31)
     ODELAY_TYPE => "FIXED",         -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     ODELAY_VALUE => 0,              -- Output delay tap setting (0-31)
     REFCLK_FREQUENCY => 200.0,      -- IDELAYCTRL clock input frequency in MHz
     SIGNAL_PATTERN => "DATA"        -- "DATA" or "CLOCK" input signal
  )
  port map (
     CNTVALUEOUT => open, -- 5-bit output: Counter value output
     DATAOUT => ADC_doib_delay(i),         -- 1-bit output: Delayed data output
     C =>  '0',                     -- 1-bit input: Clock input
     CE => '0',                   -- 1-bit input: Active high enable increment/decrement input
     CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
     CLKIN => '0',             -- 1-bit input: Clock delay input
     CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
     DATAIN => '0',           -- 1-bit input: Internal delay data input
     IDATAIN => ADC_doib(i),         -- 1-bit input: Data input from the I/O
     INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
     ODATAIN => '0',         -- 1-bit input: Output delay data input
     RST => '0',                 -- 1-bit input: Active-high reset tap-delay input
     T => '0'                      -- 1-bit input: 3-state input
  );
  end generate specify_one;
  
  universal: if i/=5 generate
IODELAYE1_inst : IODELAYE1
  generic map (
     CINVCTRL_SEL => FALSE,          -- Enable dynamic clock inversion (TRUE/FALSE)
     DELAY_SRC => "I",               -- Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
     HIGH_PERFORMANCE_MODE => FALSE, -- Reduced jitter (TRUE), Reduced power (FALSE)
     IDELAY_TYPE => "FIXED",       -- "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     IDELAY_VALUE => 0,              -- Input delay tap setting (0-31)
     ODELAY_TYPE => "FIXED",         -- "FIXED", "VARIABLE", or "VAR_LOADABLE" 
     ODELAY_VALUE => 0,              -- Output delay tap setting (0-31)
     REFCLK_FREQUENCY => 200.0,      -- IDELAYCTRL clock input frequency in MHz
     SIGNAL_PATTERN => "DATA"        -- "DATA" or "CLOCK" input signal
  )
  port map (
     CNTVALUEOUT => open, -- 5-bit output: Counter value output
     DATAOUT => ADC_doib_delay(i),         -- 1-bit output: Delayed data output
     C =>  '0',                     -- 1-bit input: Clock input
     CE => '0',                   -- 1-bit input: Active high enable increment/decrement input
     CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
     CLKIN => '0',             -- 1-bit input: Clock delay input
     CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
     DATAIN => '0',           -- 1-bit input: Internal delay data input
     IDATAIN => ADC_doib(i),         -- 1-bit input: Data input from the I/O
     INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
     ODATAIN => '0',         -- 1-bit input: Output delay data input
     RST => '0',                 -- 1-bit input: Active-high reset tap-delay input
     T => '0'                      -- 1-bit input: 3-state input
  );
  end generate universal;
end generate;
-------------------------------------------------------------------------------	
IDELAYCTRL_inst : IDELAYCTRL
  port map (
     RDY => open,       -- 1-bit output indicates validity of the REFCLK
     REFCLK => CLK5_200MHz, -- 1-bit reference clock input
     RST => '0'        -- 1-bit reset input
  );
-------------------------------------------------------------------------------
  -----------------------------------------------------------------------------
-- iddr(iob)
        Inst_IDDR_inst1: IDDR_inst PORT MAP(
		CLK =>ADC_CLKOI ,
		Q1 =>ADC_DOIA_1 ,
		Q2 =>ADC_DOIA_2 ,
		D =>ADC_DOIA_delay
	);
    	Inst_IDDR_inst2: IDDR_inst PORT MAP(
		CLK =>ADC_CLKOI ,
		Q1 =>ADC_DOIB_1 ,
		Q2 =>ADC_DOIB_2 ,
		D =>ADC_DOIB_delay 
	);
    	Inst_IDDR_inst3: IDDR_inst PORT MAP(
		CLK =>ADC_CLKOQ ,
		Q1 =>ADC_DOQA_1 ,
		Q2 =>ADC_DOQA_2 ,
		D =>ADC_DOQA_delay 
	);
    	Inst_IDDR_inst4: IDDR_inst PORT MAP(
		CLK =>ADC_CLKOQ ,
		Q1 =>ADC_DOQB_1 ,
		Q2 =>ADC_DOQB_2 ,
		D =>ADC_DOQB_delay 
	);

  -----------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- dff(iob->dff)为了更好地约束走线
  DFF_doqA_1_inst1: for i in 0 to 7 generate
  begin  
   FDCE_inst : FDCE
   generic map (
      INIT => '0') -- Initial value of register ('0' or '1')  
   port map (
      Q =>ADC_DOQA_1_d(i) ,      -- Data output
      C => ADC_clkoq,      -- Clock input
      CE => '1',    -- Clock enable input
      CLR => '0',  -- Asynchronous clear input
      D =>ADC_DOQA_1(i)        -- Data input
   );
  end generate DFF_doqA_1_inst1;

    DFF_doqA_2_inst2: for i in 0 to 7 generate
  begin  
     FDCE_inst : FDCE
   generic map (
      INIT => '0') -- Initial value of register ('0' or '1')  
   port map (
      Q =>ADC_DOQA_2_d(i) ,      -- Data output
      C => ADC_clkoq,      -- Clock input
      CE => '1',    -- Clock enable input
      CLR => '0',  -- Asynchronous clear input
      D =>ADC_DOQA_2(i)        -- Data input
   );
  end generate DFF_doqA_2_inst2;

      DFF_doqB_1_inst3: for i in 0 to 7 generate
  begin  
     FDCE_inst : FDCE
   generic map (
      INIT => '0') -- Initial value of register ('0' or '1')  
   port map (
      Q =>ADC_DOQB_1_d(i) ,      -- Data output
      C =>  ADC_clkoq,      -- Clock input
      CE => '1',    -- Clock enable input
      CLR => '0',  -- Asynchronous clear input
      D =>ADC_DOQB_1(i)        -- Data input
   );
  end generate DFF_doqB_1_inst3;

      DFF_doqB_2_inst4: for i in 0 to 7 generate
  begin  
     FDCE_inst : FDCE
   generic map (
      INIT => '0') -- Initial value of register ('0' or '1')  
   port map (
      Q =>ADC_DOQB_2_d(i) ,      -- Data output
      C =>  ADC_clkoq,      -- Clock input
      CE => '1',    -- Clock enable input
      CLR => '0',  -- Asynchronous clear input
      D =>ADC_DOQB_2(i)        -- Data input
   );
  end generate DFF_doqB_2_inst4;
  -----------------------------------------------------------------------------
    DFF_doiA_1_inst1: for i in 0 to 7 generate
  begin  
   FDCE_inst : FDCE
   generic map (
      INIT => '0') -- Initial value of register ('0' or '1')  
   port map (
      Q =>ADC_DOiA_1_d(i) ,      -- Data output
      C => ADC_clkoi,      -- Clock input
      CE => '1',    -- Clock enable input
      CLR => '0',  -- Asynchronous clear input
      D =>ADC_DOiA_1(i)        -- Data input
   );
  end generate DFF_doiA_1_inst1;

    DFF_doiA_2_inst2: for i in 0 to 7 generate
  begin  
     FDCE_inst : FDCE
   generic map (
      INIT => '0') -- Initial value of register ('0' or '1')  
   port map (
      Q =>ADC_DOiA_2_d(i) ,      -- Data output
      C => ADC_clkoi,      -- Clock input
      CE => '1',    -- Clock enable input
      CLR => '0',  -- Asynchronous clear input
      D =>ADC_DOiA_2(i)        -- Data input
   );
  end generate DFF_doiA_2_inst2;

      DFF_doiB_1_inst3: for i in 0 to 7 generate
  begin  
     FDCE_inst : FDCE
   generic map (
      INIT => '0') -- Initial value of register ('0' or '1')  
   port map (
      Q =>ADC_DOiB_1_d(i) ,      -- Data output
      C =>  ADC_clkoi,      -- Clock input
      CE => '1',    -- Clock enable input
      CLR => '0',  -- Asynchronous clear input
      D =>ADC_DOiB_1(i)        -- Data input
   );
  end generate DFF_doiB_1_inst3;

      DFF_doiB_2_inst4: for i in 0 to 7 generate
  begin  
     FDCE_inst : FDCE
   generic map (
      INIT => '0') -- Initial value of register ('0' or '1')  
   port map (
      Q =>ADC_DOiB_2_d(i) ,      -- Data output
      C =>  ADC_clkoi,      -- Clock input
      CE => '1',    -- Clock enable input
      CLR => '0',  -- Asynchronous clear input
      D =>ADC_DOiB_2(i)        -- Data input
   );
  end generate DFF_doiB_2_inst4;
  -----------------------------------------------------------------------------
        
   --   IBUFGDS_inst1 : IBUFGDS
   -- generic map (
   --    DIFF_TERM => FALSE, -- Differential Termination 
   --    IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
   --    IOSTANDARD => "DEFAULT")
   -- port map (
   --    O => ADC_CLKOQ,  -- Clock buffer output
   --    I => ADC_CLKOQ_p,  -- Diff_p clock buffer input (connect directly to top-level port)
   --    IB => ADC_CLKOQ_n -- Diff_n clock buffer input (connect directly to top-level port)
   -- );
  
   --   IBUFGDS_inst2 : IBUFGDS
   -- generic map (
   --    DIFF_TERM => FALSE, -- Differential Termination 
   --    IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
   --    IOSTANDARD => "DEFAULT")
   -- port map (
   --    O =>ADC_CLKOI,  -- Clock buffer output
   --    I => ADC_CLKOI_p,  -- Diff_p clock buffer input (connect directly to top-level port)
   --    IB => ADC_CLKOI_n -- Diff_n clock buffer input (connect directly to top-level port)
   -- );

      IBUFGDS_inst3 : IBUFGDS
   generic map (
      DIFF_TERM    => FALSE,            -- Differential Termination 
      IBUF_LOW_PWR => TRUE,  -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
      IOSTANDARD   => "DEFAULT")
   port map (
      O  => GHz_in,                     -- Clock buffer output
      I  => GHz_in_p,  -- Diff_p clock buffer input (connect directly to top-level port)
      IB => GHz_in_n  -- Diff_n clock buffer input (connect directly to top-level port)
   );
-------------------------------------------------------------------------------
  Inst_ADC_interface : ADC_interface port map(
    ADC_Mode        => ADC_Mode,
    user_pushbutton => user_pushbutton,
    ADC_sclk_OUT    => ADC_sclk_OUT,
    ADC_sldn_OUT    => ADC_sldn_OUT,
    ADC_sdata       => ADC_sdata,
    CLK1            => CLK1,
    CLK2            => CLK2
    );
-------------------------------------------------------------------------------
  Inst_CDCE62005_config : CDCE62005_config port map(
    clk         => clk2,
    clk_spi     => not clk2,
    en          => cdce62005_en,
    spi_clk     => spi_clk,
    spi_mosi    => spi_mosi,
    spi_miso    => spi_miso,
    spi_le      => spi_le,
    spi_syn     => spi_syn,
    spi_powerdn => spi_powerdn,
    cfg_finish  => cfg_finish,
    spi_revdata => spi_revdata
    );
-------------------------------------------------------------------------------
        -- Inst_usb2_interface : usb2_interface PORT MAP(
        --         clk_20m     => CLK6_20MHz,
	-- 				 clk_10m     =>usb_SCLK,
        --         USB_data    => USB_data,
        --         rst_n       => rst_n,
        --         DataEPFull  => USB_DataEPFull,
        --         CmdEPEmpty  => USB_CmdEPEmpty,
        --         data_in_usb => data_in_usb,
        --         EPADDR      => USB_FIFOADR,
        --         SLRD        => USB_SLRD,
        --         SLOE        => USB_SLOE,
        --         SLWR        => USB_SLWR,
        --         PKTEND      => USB_PKTEND,
        --         IFCLk       => USB_IFCLk,
        --         usb_start       => usb_start,
        --         usb_clr     => usb_clr,
	-- 				 dout => dout
        -- );
-------------------------------------------------------------------------------
	Inst_G_ethernet_top: G_ethernet_top PORT MAP(
		rst_n_gb_i => ethernet_rst_n_gb_i,
		PHY_TXD_o => PHY_TXD_o,
		PHY_GTXclk_quar => PHY_GTXclk_quar,
		phy_txen_quar => phy_txen_quar,
		phy_txer_o => phy_txer_o,
		user_pushbutton => user_pushbutton,
		rst_n_o => phy_rst_n_o,
		fifo_upload_data =>ethernet_fifo_upload_data,
		Rd_clk => ethernet_Rd_clk,
		Rd_en => ethernet_Rd_en,
		Rd_Addr => ethernet_Rd_Addr,
		PHY_RXD => PHY_RXD,
		PHY_RXC => phy_rxc_g,
		PHY_RXDV => PHY_RXDV,
		Rd_data => ethernet_Rd_data,
		Frm_valid => ethernet_Frm_valid,
		CLK_125M => CLK_125M,
		CLK_125M_quar => CLK_125M_quar,
                ram_wren => ram_wren,
                ram_rden => ram_rden,
                ram_start =>ram_start,
                srcc1_p_trigin => SRCC1_p_trigin,
                ram_last => ram_last,
                SRCC1_n_upload_sma_trigin=>SRCC1_n_upload_sma_trigin,
                upload_trig_ethernet=>upload_trig_ethernet
                
	);
-------------------------------------------------------------------------------
  	Inst_command_analysis: command_analysis PORT MAP(
		rd_data =>ethernet_Rd_data ,
		rd_clk => ethernet_Rd_clk,
		rd_addr =>ethernet_rd_addr ,
		rd_en => ethernet_Rd_en,
		frm_length =>cmd_frm_length ,
		frm_type =>cmd_frm_type ,
		-- mac_dst =>mac_dst ,
		-- mac_src =>mac_src ,
		-- reg_addr =>mac_reg_addr ,
		-- reg_data =>mac_reg_data ,
	        ram_start => ram_start,
                user_pushbutton => user_pushbutton,
                ram_switch =>ram_switch,
                upload_trig_ethernet=> upload_trig_ethernet
	);
-------------------------------------------------------------------------------
    ram_data_inst : ram_data
  PORT MAP (
    clka =>ADC_clkoq,
    ena => ram_ena,
    wea => ram_wea,
    addra => ram_addra,
    dina => ram_dina,
    clkb => ram_clkb,
    rstb => ram_rstb,
    enb => ram_enb,
    addrb => ram_addrb,
    doutb => ram_doutb
  );
  -- ram_dina<=ADC_DOQA_1_d&ADC_DOQB_1_d&ADC_DOQA_2_d&ADC_DOQB_2_d;
  ram_dina<=ADC_DOQB_2_d&ADC_DOQA_2_d&ADC_DOQB_1_d&ADC_DOQA_1_d;
  ram_clka<=ADC_clkoq;
  ram_CLKb<=CLK_125M;
  ram_enb<=ram_rden;
  ram_ena<=ram_wren and (not ram_full);     --ram_wren 在trig信号后一拍到来在endstate后一拍结束，ram输入端使能信号要从trig_i开始一直到满或者20us结束。可以考虑重做ram_wren
  ram_wea(0)<=ram_wren and (not ram_full);
  ram_rstb<=not rst_n;
  clr_n_ram<=rst_n;
 
------------------------------------------------------------------------------
     ram_data_inst2 : ram_data_i
  PORT MAP (
    clka =>ADC_clkoi,
    ena => ram_i_ena,
    wea => ram_i_wea,
    addra => ram_i_addra,
    dina => ram_i_dina,
    clkb => ram_i_clkb,
    rstb => ram_i_rstb,
    enb => ram_i_enb,
    addrb => ram_i_addrb,
    doutb => ram_i_doutb
  );
  ram_i_dina<=ADC_DOiB_2_d&ADC_DOiA_2_d&ADC_DOiB_1_d&ADC_DOiA_1_d;
  ram_i_clkb<=CLK_125M;
  ram_i_enb<=ram_rden;
  ram_i_ena<=ram_wren and (not ram_i_full);
  ram_i_wea(0)<=ram_wren and (not ram_i_full);
  ram_i_rstb<=not rst_n;
  clr_n_ram<=rst_n;
-----------------------------------------------------------------------------
-- Inst_fifo_receivedata_I_A1  : fifo
--   PORT MAP (
--     rst => rst,
--     wr_clk => CLKOI,
--     rd_clk => CLKOI,
--     din =>din_IA1 ,
--     wr_en => wr_en,
--     rd_en => rd_en,
--     dout => ADC_DOIA_1_out,
--     full => full_IA1,
--     almost_full => almost_full_IA1,
--     empty => empty_IA1,
--     valid => valid_IA1
--   );
  -- Inst_fifo_receivedata_I_A2  : fifo
  -- PORT MAP (
  --   rst => rst,
  --   wr_clk => CLKOI,
  --   rd_clk => CLKOI,
  --   din => ADC_DOIA_2,
  --   wr_en => wr_en,
  --   rd_en => rd_en,
  --   dout =>ADC_DOIA_2_out,
  --   full => full_IA2,
  --   almost_full => almost_full_IA2,
  --   empty => empty_IA2,
  --   valid => valid_IA2
  -- );

  -- Inst_fifo_receivedata_I_B1  : fifo
  -- PORT MAP (
  --   rst => rst,
  --   wr_clk => CLKOI,
  --   rd_clk => CLKOI,
  --   din =>ADC_DOIB_1 ,
  --   wr_en => wr_en,
  --   rd_en => rd_en,
  --   dout => ADC_DOIB_1_out,
  --   full => full_IB1,
  --   almost_full => almost_full_IB1,
  --   empty => empty_IB1,
  --   valid => valid_IB1
  -- );

  -- Inst_fifo_receivedata_I_B2  : fifo
  -- PORT MAP (
  --   rst => rst,
  --   wr_clk => CLKOI,
  --   rd_clk => CLKOI,
  --   din => din_IB2,
  --   wr_en => wr_en,
  --   rd_en => rd_en,
  --   dout =>ADC_DOIB_2_out,
  --   full => full_IB2,
  --   almost_full => almost_full_IB2,
  --   empty => empty_IB2,
  --   valid => valid_IB2
  -- );

--   Inst_fifo_receivedata_Q  : fifo       --测试用fifo
--   PORT MAP (
--     rst => rst_gb,
--     wr_clk => ADC_CLKOQ,
--     rd_clk => ADC_CLKOQ,
--     din =>din_Q ,
--     wr_en => wr_en,
--     rd_en => rd_en,
--     dout => ADC_DOQA_1_out,
--     full => full_QA1,
--     almost_full => almost_full_QA1,
--     empty => empty_QA1,
--     valid => valid_QA1
--   );
-- din_Q<=ADC_DOQA_1_d&ADC_DOQB_1_d&ADC_DOQA_2_d&ADC_DOQB_2_d;
-- wr_en<='1';
-- rd_en<='1';
  -- Inst_fifo_receivedata_Q_A2  : fifo
  -- PORT MAP (
  --   rst => rst,
  --   wr_clk => CLKOQ,
  --   rd_clk => CLKOQ,
  --   din => ADC_DOQA_2,
  --   wr_en => wr_en,
  --   rd_en => rd_en,
  --   dout =>ADC_DOQA_2_out,
  --   full => full_QA2,
  --   almost_full => almost_full_QA2,
  --   empty => empty_QA2,
  --   valid => valid_QA2
  -- );

  -- Inst_fifo_receivedata_Q_B1  : fifo
  -- PORT MAP (
  --   rst => rst,
  --   wr_clk => CLKOQ,
  --   rd_clk => CLKOQ,
  --   din =>ADC_DOQB_1 ,
  --   wr_en => wr_en,
  --   rd_en => rd_en,
  --   dout => ADC_DOQB_1_out,
  --   full => full_QB1,
  --   almost_full => almost_full_QB1,
  --   empty => empty_QB1,
  --   valid => valid_QB1
  -- );

  -- Inst_fifo_receivedata_Q_B2  : fifo
  -- PORT MAP (
  --   rst => rst,
  --   wr_clk => CLKOQ,
  --   rd_clk => CLKOQ,
  --   din => ADC_DOQB_2,
  --   wr_en => wr_en,
  --   rd_en => rd_en,
  --   dout =>ADC_DOQB_2_out,
  --   full => full_QB2,
  --   almost_full => almost_full_QB2,
  --   empty => empty_QB2,
  --   valid => valid_QB2
  -- );

  -----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  ram_switch_ps: process (CLK_125M, rst_n) is
  begin  -- process ram_switch_ps
    if rst_n ='0' then
      ethernet_fifo_upload_data<=ram_doutb;
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      case ram_switch is
        when "001" =>
          ethernet_fifo_upload_data<=ram_doutb;
          ram_last<=ram_q_last;
          ram_full<=ram_q_full;
        when "010" =>
          ethernet_fifo_upload_data<=ram_i_doutb;
          ram_last<=ram_i_last;
          ram_full<=ram_i_full;
        when others =>
         ethernet_fifo_upload_data<=ram_doutb;
         ram_last<=ram_q_last;
         ram_full<=ram_q_full;
      end case;
    end if;
  end process ram_switch_ps;
  -----------------------------------------------------------------------------
  -- purpose: to combine all the conditions
  -- type   : sequential
  -- inputs : CLK_125M, rst_n
  -- outputs: 
  posedge_upload_trig_ps: process (CLK_125M, rst_n, ram_start_d, ram_start_d2, trigin_d2, trigin_d, SRCC1_n_upload_sma_trigin_d, SRCC1_n_upload_sma_trigin_d2, upload_trig_ethernet_d, upload_trig_ethernet_d2) is
  begin  -- process posedge_upload_trig_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
     posedge_upload_trig<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      if (ram_start_d = '1' and ram_start_d2='0') or (trigin_d2 ='0' and trigin_d='1') or (SRCC1_n_upload_sma_trigin_d = '1' and SRCC1_n_upload_sma_trigin_d2 = '0') or (upload_trig_ethernet_d = '1' and upload_trig_ethernet_d2 = '0') then
      posedge_upload_trig<='1';
      else
        posedge_upload_trig<='0';
      end if;
    end if;
  end process posedge_upload_trig_ps;
  
    --ram_addr
ram_addra_ps: process (ADC_CLKOQ, clr_n_ram, ram_start_d, ram_start_d2, trigin_d2, trigin_d) is --trigin是sma触发，ram_start是上位机的触发
begin  -- process addra_ps
  if clr_n_ram = '0' or (ram_start_d = '1' and ram_start_d2='0') or (trigin_d2 ='0' and trigin_d='1')  then                   -- asynchronous reset (active low)
    ram_addra<=(others => '0');
  elsif ADC_CLKOQ'event and ADC_CLKOQ = '1' then  -- rising clock edge
    if ram_wren='1' then                --收到wren控制，希望wren是上位机的trig到来后的10us或者20us这样一个持续，ram_wren来自tx_module
    if ram_addra<x"270e" then        --只写入一次 10000的ram深度
      ram_addra<=ram_addra+1;
      ram_q_full<='0';
    elsif ram_addra= x"270e" then       --270f是最后一个地址 留一个余量防止ram崩溃
      ram_q_full<='1';                    --为了保持这个full的状态，ram_addra不能清零
    end if;
  end if;
  end if;
end process ram_addra_ps;

ram_addrb_ps: process (CLK_125M, clr_n_ram, posedge_upload_trig) is
begin  -- process addrb_ps
  if clr_n_ram = '0'  then
    ram_addrb<=(others => '0');
    ram_q_last<='1';
  elsif posedge_upload_trig='1' then    --比真正的trig上升沿到来晚一拍
    ram_addrb<=(others => '0');
    ram_q_last<='1';
  elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
    if ram_rden='1' then
     if ram_addrb<x"9c37" then
      ram_addrb<=ram_addrb+1;                   --只读一轮 测试阶段先循环读出,现在ram的深度为10000 位宽32bit,对于8bit的读出位宽深度为40000，x“9c40"
      ram_q_last<='0';
    elsif ram_addrb>=x"9c37" then        --不要读满。。余几个量
      ram_q_last<='1';
             --根据方针前4个值为空，9c40为x
     end if;
  end if;
end if;
end process ram_addrb_ps;
-------------------------------------------------------------------------------
ram_i_addra_ps: process (ADC_CLKOi, clr_n_ram, ram_start_d, ram_start_d2,trigin_d2,trigin_d) is
begin  -- process addra_ps
  if clr_n_ram = '0' or (ram_start_d = '1' and ram_start_d2='0') or (trigin_d2 ='0' and trigin_d='1') then                   -- asynchronous reset (active low)
    ram_i_addra<=(others => '0');
  elsif ADC_CLKOi'event and ADC_CLKOi = '1' then  -- rising clock edge
    if ram_wren='1' then                --收到wren控制，希望wren是上位机的trig到来后的10us或者20us这样一个持续
    if ram_i_addra<x"270e" then        --只写入一次 10000的ram深度
      ram_i_addra<=ram_i_addra+1;
      ram_i_full<='0';
    elsif ram_i_addra= x"270e" then       --270f是最后一个地址 留一个余量防止ram崩溃
      ram_i_full<='1';                    --为了保持这个full的状态，ram_addra不能清零
    end if;
  end if;
  end if;
end process ram_i_addra_ps;

ram_i_addrb_ps: process (CLK_125M, clr_n_ram, posedge_upload_trig) is
begin  -- process addrb_ps
  if clr_n_ram = '0'  then
    ram_i_addrb<=(others => '0');
    ram_i_last<='1';
  elsif posedge_upload_trig ='1' then  --比真正的trig上升沿到来晚一拍
    ram_i_addrb<=(others => '0');
    ram_i_last<='1';
  elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
    if ram_rden='1' then
     if ram_i_addrb<x"9c37" then
      ram_i_addrb<=ram_i_addrb+1;                   --只读一轮 测试阶段先循环读出,现在ram的深度为10000 位宽32bit,对于8bit的读出位宽深度为40000，x“9c40"
      ram_i_last<='0';
    elsif ram_i_addrb>=x"9c37" then        --不要读满。。余几个量
      ram_i_last<='1';
            --根据方针前4个值为空，9c40为x
     end if;
  end if;
end if;
end process ram_i_addrb_ps;

-------------------------------------------------------------------------------
--ram sample trigger for sma and ethernet;delay
ram_start_d_ps: process (CLK_125M) is
  begin  -- process ram_start_d_ps
    if CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      ram_start_d<=ram_start;
    end if;
  end process ram_start_d_ps;
ram_start_d2_ps: process (CLK_125M) is
  begin  -- process ram_start_d_ps
    if CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      ram_start_d2<=ram_start_d;
    end if;
  end process ram_start_d2_ps;

  SRCC1_p_trigin_d_ps: process (CLK_125M) is
  begin  -- process SRCC1_p_trigin_d_ps
    if CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
       trigin_d<=SRCC1_p_trigin;
       trigin_d2<=trigin_d;
    end if;
  end process SRCC1_p_trigin_d_ps;
  ----------------------------
   upload_trig_ethernet_d_ps: process (CLK_125M, rst_n) is
  begin  -- process trig_in_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      upload_trig_ethernet_d<='0';
      upload_trig_ethernet_d2<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      upload_trig_ethernet_d<=upload_trig_ethernet;
      upload_trig_ethernet_d2<=upload_trig_ethernet_d;
    end if;
  end process upload_trig_ethernet_d_ps;
  
    SRCC1_n_upload_sma_trigin_d_ps: process (CLK_125M, rst_n) is
  begin  -- process trig_in_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      SRCC1_n_upload_sma_trigin_d<='0';
      SRCC1_n_upload_sma_trigin_d2<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      SRCC1_n_upload_sma_trigin_d<=SRCC1_n_upload_sma_trigin;
      SRCC1_n_upload_sma_trigin_d2<=SRCC1_n_upload_sma_trigin_d;
    end if;
  end process SRCC1_n_upload_sma_trigin_d_ps;
-------------------------------------------------------------------------------
 frm_valid_d_ps: process (ethernet_Rd_clk, rst_n) is
  begin  -- process frm_valid_d
    if ethernet_Rd_clk'event and ethernet_Rd_clk = '1' then  -- rising clock edge
      frm_valid_d<= ethernet_frm_valid;
    end if;
  end process frm_valid_d_ps;
  
  Rd_en_ps: process (ethernet_Rd_clk,rst_n,ethernet_frm_valid,frm_valid_d) is
  begin  -- process Rd_en_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      ethernet_Rd_en<='0';
    elsif ethernet_Rd_clk'event and ethernet_Rd_clk = '1' then
    if frm_valid_d = '0' and ethernet_frm_valid = '1' then  -- rising clock edge
      ethernet_Rd_en<='1';
    elsif ethernet_Rd_Addr>=x"42" then
    -- elsif ethernet_Rd_Addr>=x"16" then
      ethernet_Rd_en<='0';
    end if;
  end if;
  end process Rd_en_ps;

Rd_Addr_ps: process (ethernet_Rd_clk, rst_n) is
begin  -- process Rd_Addr_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    ethernet_Rd_Addr<=(others => '0');
  elsif ethernet_Rd_clk'event and ethernet_Rd_clk = '1' then  -- rising clock edge
    if ethernet_Rd_Addr<=x"42" and ethernet_Rd_en = '1'then
    ethernet_Rd_Addr<=ethernet_Rd_Addr + 1;
    elsif ethernet_Rd_en = '0' or ethernet_Rd_Addr>x"41" then
      ethernet_Rd_Addr<=(others => '0');
  end if;
end if;
end process Rd_Addr_ps;
--     Rd_Addr_ps: process (ethernet_Rd_clk, rst_n) is
-- begin  -- process Rd_Addr_ps
--   if rst_n = '0' then                   -- asynchronous reset (active low)
--     ethernet_Rd_Addr<="00"&(x"011");
--   elsif ethernet_Rd_clk'event and ethernet_Rd_clk = '1' then  -- rising clock edge
--     if ethernet_Rd_Addr<=x"16" and ethernet_Rd_en = '1'then
--     ethernet_Rd_Addr<=ethernet_Rd_Addr + 1;
--     elsif ethernet_Rd_en = '0' or ethernet_Rd_Addr>x"16" then
--       ethernet_Rd_Addr<="00"&(x"011");
--   end if;
-- end if;
-- end process Rd_Addr_ps;
  -----------------------------------------------------------------------------
-- purpose: set Gcnt
-- type   : sequential
-- inputs : CLK2
-- outputs: clk2_cnt
    set_clk2_cnt : process (CLK2, clk2_cnt) is
    begin  -- process set_Gcnt    
      if CLK2'event and CLK2 = '1' then
        if clk2_cnt <= x"11111111" then
          clk2_cnt <= clk2_cnt+1;
          else
            clk2_cnt<=clk2_cnt;
        end if;
      end if;
    end process set_clk2_cnt;

    set_cdce62005_en : process (CLK1, cdce62005_en) is
    begin  -- process cdce62005_en
      if CLK1'event and CLK1 = '1' then
      if clk2_cnt >= x"00000000" and clk2_cnt <= x"00000050" then
        cdce62005_en <= '0';
      else
        cdce62005_en <= '1';
      end if;
    end if;
    end process set_cdce62005_en;
  -- purpose: set global_rst---以clk2_cnt为计数设置一个全局的高有效复位信号
  -- type   : sequential
  -- inputs : clk1
  -- outputs: rst_gb
  set_rst: process (clk1) is
  begin  -- process set_rst
     if CLK1'event and CLK1 = '1' then
      if clk2_cnt >= x"00000001" and clk2_cnt <= x"0000002" then
        rst_gb<='1';
        else
          rst_gb<='0';
    end if;
  end if;
  end process set_rst;

  -- purpose: make GHz_in reveal in the chipscope 
  -- type   : sequential
  -- inputs : GHz_in
  -- outputs: 
  set_GHz_in: process (GHz_in) is
  begin  -- process set_GHz_in
    if GHz_in'event and GHz_in = '1' then  -- rising clock edge
      rst_gb_d<=rst_gb;
    end if;
  end process set_GHz_in;

  set_OQcountera: process (ADC_CLKOQ) is
  begin  -- process set_OQcounter
    if ADC_CLKOQ'event and ADC_CLKOQ = '1' then  -- rising clock edge
      OQcounter<=OQcounter+1;
    end if;
  end process set_OQcountera;
   set_OIcounter: process (ADC_CLKOI) is
  begin  -- process set_OQcounter
    if ADC_CLKOI'event and ADC_CLKOI = '1' then  -- rising clock edge
      OIcounter<=OIcounter+1;
    end if;
  end process set_OIcounter;
-----------------------------------------------------------------------------
  -- set_clk_div_cnt : process (CLK2, rst_n) is --usb data
  -- begin  -- process set_clk_div_cnt
  --   if rst_n = '0' then                 -- asynchronous reset (active
  --     clk_div_cnt <= x"00";
  --   elsif CLK2'event and CLK2 = '1' then          -- rising clock edge
  --     if clk_div_cnt <= Div_multi then
  --       clk_div_cnt <= clk_div_cnt+1;
  --     else
  --       clk_div_cnt <= x"00";
  --     end if;
  --   end if;
  -- end process set_clk_div_cnt;

  -- set_usb_sclk : process (CLK2, rst_n) is
  -- begin  -- process set_ADC_sclk
  --   if rst_n = '0' then                   -- asynchronous reset (active low)
  --     usb_SCLK <= '0';
  --   elsif CLK2'event and CLK2 = '1' then  -- rising clock edge
  --     if clk_div_cnt <= Div_multi(3 downto 1) then
  --       usb_SCLK <= '0';
  --     else
  --       usb_SCLK <= '1';
  --     end if;
  --   end if;
  -- end process set_usb_sclk;


  -- data_in_usb_ps: process (usb_SCLK, rst_n) is
  -- begin  -- process data_in_usb_ps
  --   if rst_n = '0' then                 -- asynchronous reset (active low)
  --     data_in_usb<=(others => '0');
  --   elsif usb_SCLK'event and usb_SCLK = '1' then  -- rising clock edge
  --     data_in_usb<=data_in_usb+1;
  --   end if;
  -- end process data_in_usb_ps;
------------------------------------------------------------------------------

-----------------------------------------------------------------------------
 -- SRCC1_n<=ADC_CLKOQ_n;
  -- SRCC1_p<=USB_data(0); --j9
  -- SRCC1_n<=data_in_usb(0);--j8
  -- MRCC2_p<=dout(0);--j12
  -- MRCC2_n<=ADC_sdata;
 rst_n<=user_pushbutton;
 ethernet_rd_clk<= CLK_71M;
 -- ethernet_fifo_upload_data<=ADC_DOQA_1_d;
  -- usb_rst<= user_pushbutton;
    end Behavioral;
  


