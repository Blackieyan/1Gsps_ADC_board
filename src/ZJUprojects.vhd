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
  generic (
    dds_phase_width : integer := 24
    );
  port(
    OSC_in_n        : in    std_logic;
    OSC_in_p        : in    std_logic;
---------------------------------------------------------------------------
    ADC_Mode        : out   std_logic;
    ADC_sclk_OUT    : out   std_logic;
    ADC_sldn_OUT    : out   std_logic;
    ADC_sdata       : out   std_logic_vector(0 downto 0);  --ADC interface
-------------------------------------------------------------------------------
    spi_clk         : out   std_logic;
    spi_mosi        : out   std_logic;
    spi_le          : out   std_logic;
    spi_syn         : out   std_logic;
    spi_miso        : in    std_logic;
    spi_powerdn     : inout std_logic;
    spi_revdata     : out   std_logic_vector(31 downto 0);
    cfg_finish      : out   std_logic;  --CDCE62005
    -- spi_pd                               : inout std_logic;
-------------------------------------------------------------------------------
    user_pushbutton : in    std_logic;  --glbclr_n
    ---------------------------------------------------------------------------
    ADC_CLKOI_p     : in    std_logic;  -- ADC CLKOI 500MHz/250MHz
    ADC_CLKOI_n     : in    std_logic;
    -- ADC_CLKOQ_p               : in    std_logic;
    -- ADC_CLKOQ_n               : in    std_logic;
    ADC_DOIA_p      : in    std_logic_vector(7 downto 0);
    ADC_DOIA_n      : in    std_logic_vector(7 downto 0);
    ADC_DOIB_p      : in    std_logic_vector(7 downto 0);
    ADC_DOIB_n      : in    std_logic_vector(7 downto 0);
    ADC_DOQA_p      : in    std_logic_vector(7 downto 0);
    ADC_DOQA_n      : in    std_logic_vector(7 downto 0);
    ADC_DOQB_p      : in    std_logic_vector(7 downto 0);
    ADC_DOQB_n      : in    std_logic_vector(7 downto 0);
    DOIRI_p         : in    std_logic;
    DOIRI_n         : in    std_logic;
    DOIRQ_p         : in    std_logic;
    DOIRQ_n         : in    std_logic;
    SRCC1_p_trigin  : in    std_logic;  --J31
    ---------------------------------------------------------------------------
    -- SRCC1_n                   : out    std_logic;  --J8
    -- SRCC1_p                   : out   std_logic;  --J9
    -- MRCC1_n                   : out std_logic;  --J11
    -- MRCC1_p                   : out std_logic;  --J10
    -- MRCC2_n                   : out   std_logic_vector(0 downto 0); -- pinsfor test
    ---------------------------------------------------------------------------
	 
	 
	 -----------------------------SelfAdpt----------------------------------------------
	 adpt_led		  : out	 std_logic;
	 trig_monitor	  : out	 std_logic;
	 -----------------------------SelfAdpt----------------------------------------------
	 
    PHY_RXD         : in    std_logic_vector(3 downto 0);
    PHY_RXC         : in    std_logic;
    PHY_RXDV        : in    std_logic;
    PHY_TXD_o       : out   std_logic_vector(3 downto 0);
    PHY_GTXclk_quar : out   std_logic;
    PHy_txen_quar   : out   std_logic;
    phy_txer_o      : out   std_logic;

    TX_src_MAC_addr : in  std_logic_vector(3 downto 0) := "0000";
    phy_rst_n_o     : out std_logic;
    clk_EXT_250M : in std_logic;
    Estmr_OQ_p        : out std_logic;
    Estmr_OQ_n        : out std_logic;


   ---------------------------------------------------------------------------
   qdriip_cq_p : IN std_logic_vector(0 to 0);
	qdriip_cq_n : IN std_logic_vector(0 to 0);
	qdriip_q : IN std_logic_vector(35 downto 0);         
	qdriip_k_p : OUT std_logic_vector(0 to 0);
	qdriip_k_n : OUT std_logic_vector(0 to 0);
	qdriip_d : OUT std_logic_vector(35 downto 0);
	qdriip_sa : OUT std_logic_vector(18 downto 0);
	qdriip_w_n : OUT std_logic;
	qdriip_r_n : OUT std_logic;
	qdriip_bw_n : OUT std_logic_vector(3 downto 0);
	qdriip_dll_off_n : OUT std_logic;
	cal_done : OUT std_logic
   ---------------------------------------------------------------------------              
    );
end ZJUprojects;

architecture Behavioral of ZJUprojects is
  signal clk2_cnt     : std_logic_vector(31 downto 0) := x"00000000";
-------------------------------------------------------------------------------
  signal cdce62005_en : std_logic;
  signal clk_spi      : std_logic;  --make clear what is the function of clk_spi
-------------------------------------------------------------------------------

  signal OSC_in                      : std_logic;
  signal CLK_200M                    : std_logic;
  signal CLK_250M                    : std_logic;
--   signal spi_mosi : std_logic;
-------------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  attribute keep                     : boolean;
  signal ADC_DOIA_1                  : std_logic_vector(7 downto 0);  -- ADC data receiver
  signal ADC_DOIA_2                  : std_logic_vector(7 downto 0);
  signal ADC_DOIB_1                  : std_logic_vector(7 downto 0);
  signal ADC_DOIB_2                  : std_logic_vector(7 downto 0);
  signal ADC_DOQA_1                  : std_logic_vector(7 downto 0);
  signal ADC_DOQA_2                  : std_logic_vector(7 downto 0);
  signal ADC_DOQB_1                  : std_logic_vector(7 downto 0);
  signal ADC_DOQB_2                  : std_logic_vector(7 downto 0);
  signal ADC_DOIA_1_out              : std_logic_vector(7 downto 0);
  signal ADC_DOIA_2_out              : std_logic_vector(7 downto 0);
  signal ADC_DOIB_1_out              : std_logic_vector(7 downto 0);
  signal ADC_DOIB_2_out              : std_logic_vector(7 downto 0);
  signal ADC_DOQA_1_out              : std_logic_vector(7 downto 0);
  signal ADC_DOQA_2_out              : std_logic_vector(7 downto 0);
  signal ADC_DOQB_1_out              : std_logic_vector(7 downto 0);
  signal ADC_DOQB_2_out              : std_logic_vector(7 downto 0);
  signal ADC_DOIA                    : std_logic_vector(7 downto 0);
  signal ADC_DOIB                    : std_logic_vector(7 downto 0);
  signal ADC_DOQA                    : std_logic_vector(7 downto 0);
  signal ADC_DOQB                    : std_logic_vector(7 downto 0);
  signal ADC_clkoi_inv               : std_logic;
  signal ADC_clkoq_inv               : std_logic;
  signal ADC_doqa_delay              : std_logic_vector(7 downto 0);
  signal ADC_doqb_delay              : std_logic_vector(7 downto 0);
  signal ADC_DOQA_1_d                : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOQA_1_d     : signal is true;
  signal ADC_DOQA_2_d                : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOQA_2_d     : signal is true;
  signal ADC_DOQB_1_d                : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOQB_1_d     : signal is true;
  signal ADC_DOQB_2_d                : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOQB_2_d     : signal is true;
  signal ADC_CLKOI                   : std_logic;
  attribute keep of ADC_CLKOI        : signal is true;
  signal ADC_CLKOQ                   : std_logic;
  signal rst_n                       : std_logic;
  signal rst_n_a                     : std_logic;
  signal clear_frame_cnt             : std_logic;
  signal ram_i_doutb_sim             : std_logic_vector(7 downto 0);
  attribute IODELAY_GROUP            : string;
  signal cmd_ADC_gain_adj            : std_logic_vector(18 downto 0);
  -----------------------------------------------------------------------------
  signal CLK_125M                    : std_logic;
  signal CLK_125M_quar               : std_logic;
  signal CLK_out4                    : std_logic;
  attribute keep of CLK_out4         : signal is true;
  signal ethernet_Rd_clk             : std_logic;
  signal ethernet_Rd_en              : std_logic;
  signal ethernet_Rd_addr            : std_logic_vector(13 downto 0);
  signal ethernet_frm_valid          : std_logic;
  signal frm_valid_d                 : std_logic;
  signal ethernet_rd_data            : std_logic_vector(7 downto 0);
  attribute keep of ethernet_Rd_data : signal is true;
  signal ethernet_fifo_upload_data   : std_logic_vector(7 downto 0);
  signal ethernet_rst_n_gb_i         : std_logic;
  signal cmd_frm_length              : std_logic_vector(15 downto 0);
  signal cmd_frm_type                : std_logic_vector(15 downto 0);
  signal phy_rxc_g                   : std_logic;
  -----------------------------------------------------------------------------
  signal ram_doutb                   : std_logic_vector(7 downto 0);  --ram control
  attribute keep of ram_doutb        : signal is true;
  signal ram_Q_doutb                 : std_logic_vector(7 downto 0);
  signal ram_q_rden                  : std_logic;
  signal ram_Q_dina                  : std_logic_vector(31 downto 0);
  signal ram_Q_clka                  : std_logic;
  signal ram_Q_clkb                  : std_logic;
  signal ram_q_full                  : std_logic;
  signal ram_q_last                  : std_logic;
  signal clr_n_ram                   : std_logic;
  -- signal ram_last : std_logic;


  signal ram_rst              : std_logic;
  attribute keep of ram_rst   : signal is true;
  signal ram_start            : std_logic;
  signal upload_trig_ethernet : std_logic;
  signal ram_wren             : std_logic;
  signal ram_rden             : std_logic;
  signal ram_full             : std_logic;

  signal ram_i_full                   : std_logic;
  -----------------------------------------------------------------------------
  signal ram_i_doutb                  : std_logic_vector(7 downto 0);
  attribute keep of ram_i_doutb       : signal is true;
  signal ram_i_dina                   : std_logic_vector(31 downto 0);
  signal ram_i_last                   : std_logic;
  signal Ram_I_rden                   : std_logic;
  signal ram_i_clka                   : std_logic;
  signal ram_i_clkb                   : std_logic;
  signal ram_i_rstb                   : std_logic;
  signal ram_i_ena                    : std_logic;
  signal ram_i_enb                    : std_logic;
  signal ram_i_wea                    : std_logic_vector(0 downto 0);
  signal ram_i_addra                  : std_logic_vector(12 downto 0);  --edit at 9.6
  signal ram_i_addrb                  : std_logic_vector(14 downto 0);  --edit at 9.6
  signal ram_i_rst                    : std_logic;
  signal ADC_doia_delay               : std_logic_vector(7 downto 0);
  signal ADC_doib_delay               : std_logic_vector(7 downto 0);
  signal ADC_DOiA_1_d                 : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOiA_1_d      : signal is true;
  signal ADC_DOiA_2_d                 : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOiA_2_d      : signal is true;
  signal ADC_DOiB_1_d                 : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOiB_1_d      : signal is true;
  signal ADC_DOiB_2_d                 : std_logic_vector(7 downto 0);
  attribute keep of ADC_DOiB_2_d      : signal is true;
  signal ram_switch                   : std_logic_vector(2 downto 0);
  signal SRCC1_n_upload_sma_trigin_d  : std_logic;
  signal SRCC1_n_upload_sma_trigin_d2 : std_logic;
  signal upload_trig_ethernet_d       : std_logic;
  signal upload_trig_ethernet_d2      : std_logic;
  signal ram_i_doutb_d                : std_logic_vector(7 downto 0);
  signal posedge_sample_trig          : std_logic;
  signal user_pushbutton_g            : std_logic;
  signal data_test_pin                : std_logic;
  signal TX_dst_MAC_addr              : std_logic_vector(47 downto 0);
  signal cmd_smpl_en                  : std_logic;
  signal sample_en                    : std_logic;
  signal sample_trig_cnt              : std_logic_vector(11 downto 0);
  signal cmd_smpl_en_d                : std_logic;
  signal cmd_smpl_en_d2               : std_logic;
  signal cmd_smpl_depth               : std_logic_vector(15 downto 0);
  signal cmd_smpl_trig_cnt            : std_logic_vector(23 downto 0);
  signal cmd_pstprc_IQ_sw             : std_logic_vector(1 downto 0)  := "10";
  signal cmd_demowinln                : std_logic_vector(14 downto 0) := "000"&x"096";
  signal cmd_demowinstart             : std_logic_vector(14 downto 0) := "000"&x"096";
  signal cmd_Pstprc_dps_en            : std_logic;
  signal cmd_Pstprc_dps               : std_logic_vector(dds_phase_width downto 0);  --
  --MSB reprensent the polarity of frequency
  signal cmd_adc_reconfig             : std_logic;
  signal cmd_pstprc_num_en            : std_logic;
  signal cmd_Pstprc_num               : std_logic_vector(3 downto 0);
  -----------------------------------------------------------------------------
  
  signal self_adpt_en                 : std_logic;
  signal sram_cal_done                : std_logic;
  signal dcm1_locked                  : std_logic;
  signal dcm1_locked_d                : std_logic;
  signal dcm1_locked_d2               : std_logic;
  signal lck_rst_n                    : std_logic;
  signal div_sclk                     : std_logic;
  signal div_sclk_cnt                 : std_logic_vector(31 downto 0);
  -----------------------------------------------------------------------------
  -- signal fft_ce_I : std_logic;
  -- signal fft_sclr_I : std_logic;
  -- signal fft_start_I : std_logic;
  -- signal fft_xn_re_I : std_logic_vector(7 downto 0);
  -- signal fft_xn_im_I : std_logic_vector(7 downto 0);
  -- signal fft_scale_sch_I : std_logic_vector(13 downto 0);
  -- signal fft_rfd_I : std_logic;
  -- signal fft_xn_index_I : std_logic_vector(13 downto 0);
  -- signal fft_busy_I : std_logic;
  -- signal fft_edone_I : std_logic;
  -- signal fft_done_I : std_logic;
  -- signal fft_dv_I : std_logic;
  -- signal fft_xk_index_I : std_logic_vector(13 downto 0);
  -- signal fft_xk_re_I : std_logic_vector(7 downto 0);
  -- signal fft_xk_im_I : std_logic_vector(7 downto 0);
  -- signal fft_ovflo_I : std_logic;
  -----------------------------------------------------------------------------
  signal tx_rdy : std_logic;
  signal upld_finish                  : std_logic;
  signal CW_CH_flag                   : std_logic_vector(7 downto 0);
  signal ch_stat                      : std_logic_vector(1 downto 0);
  signal data_strobe                  : std_logic;
  signal sw_ram_last                  : std_logic;
  signal CW_mult_frame_en             : std_logic;
  signal cw_ether_trig                : std_logic;
  signal CM_Ram_I_rden                : std_logic;
  signal CM_Ram_Q_rden                : std_logic;
  signal CW_Pstprc_fifo_rden          : std_logic;
  signal CW_wave_smpl_trig            : std_logic;
  signal CW_demo_smpl_trig            : std_logic;
  -----------------------------------------------------------------------------
  signal pstprc_ram_wren              : std_logic;
  signal Pstprc_RAMQ_clka             : std_logic;
  signal Pstprc_RAMQ_clkb             : std_logic;
  signal Pstprc_RAMI_clka             : std_logic;
  signal Pstprc_RAMI_clkb             : std_logic;
  signal Pstprc_RAMx_rden             : std_logic;

  signal Pstprc_RAMQ_dina : std_logic_vector(31 downto 0);
  signal Pstprc_RAMI_dina : std_logic_vector(31 downto 0);

  signal demowinln    : std_logic_vector(14 downto 0) := "000"&x"096";
  signal demowinstart : std_logic_vector(14 downto 0) := "000"&x"096";

  -----------------------------------------------------------------------------
  signal Pstprc_fifo_din     : std_logic_vector(63 downto 0);
  signal Pstprc_DPS_en       : std_logic;
  signal Pstprc_finish       : std_logic;
  signal Pstprc_finish_out   : std_logic;
  signal Pstprc_fifo_wren    : std_logic;
  -- signal pstprc_rs : std_logic;
  signal pstprc_fifo_dout    : std_logic_vector(7 downto 0);
  signal Pstprc_fifo_pempty  : std_logic;
  signal Pstprc_fifo_valid   : std_logic;
  signal Pstprc_IQ_seq_o     : std_logic_vector(63 downto 0);
  signal Pstprc_fifo_rden    : std_logic;
  signal pstprc_fifo_alempty : std_logic;
  -----------------------------------------------------------------------------
  signal cmd_Estmr_num_en    : std_logic;
  signal is_counter    : std_logic;
  signal wait_cnt_set       : std_logic_vector(23 downto 0);
  signal cmd_Estmr_num       : std_logic_vector(3 downto 0);
  signal cmd_Estmr_A             : std_logic_vector(31 downto 0);
  signal cmd_Estmr_B             : std_logic_vector(31 downto 0);
  signal cmd_Estmr_C             : std_logic_vector(63 downto 0);
  signal cmd_Estmr_sync_en       : std_logic;
  signal REF_SRAM            : std_logic;
  signal CLK_SRAM            : std_logic;
  signal clk_500M            : std_logic;
  signal clk_ext_500m : std_logic;
  signal clk_EXT_250M_g : std_logic;
  signal clk_EXT_250M_R : std_logic;
  signal clk_EXT_500M_R : std_logic;
  signal Estmr_OQ : std_logic;
  -----------------------------------------------------------------------------
  signal sys_rst_n_in    : std_logic;
  signal sys_clk         : std_logic;
  signal clk_adc         : std_logic;
  signal clk_eth_r       : std_logic;
  signal clk_eth_t       : std_logic;
  signal clk_data_proc   : std_logic;
  signal clk_data   : std_logic;
  signal clk_feedback    : std_logic;
  signal rst_data_n : std_logic;
  signal rst_adc_n       : std_logic;
  signal rst_eth_r_n     : std_logic;
  signal rst_eth_t_n     : std_logic;
  signal rst_data_proc_n : std_logic;
  signal rst_feedback_n  : std_logic;
  signal rst_config_n : std_logic;
  -----------------------------------------------------------------------------
  signal SRCC1_p_trigout : std_logic;
  signal cmd_adpt 		 : std_logic;
  signal SelfAdpt_trig 	 : std_logic;
  -----------------------------------------------------------------------------
  	COMPONENT sys_reset_proc
	PORT(
		sys_rst_n_in : IN std_logic;
		sram_cal_done : IN std_logic;
		sys_clk : IN std_logic;
                clk_config : in std_logic;
		clk_adc : IN std_logic;
		clk_eth_r : IN std_logic;
		clk_eth_t : IN std_logic;
                clk_data : in std_logic;
		clk_data_proc : IN std_logic;
		clk_feedback : IN std_logic;
                rst_data_n : out std_logic;
                rst_config_n : out std_logic;
		rst_adc_n : OUT std_logic;
		rst_eth_r_n : OUT std_logic;
                rst_eth_t_n : OUT std_logic;
		rst_data_proc_n : OUT std_logic;
		rst_feedback_n : OUT std_logic
		);
	END COMPONENT;
  -----------------------------------------------------------------------------
  component CDCE62005_interface
    port(
      clk         : in  std_logic;
      rst_n       : in  std_logic;
      spi_miso    : in  std_logic;
      spi_clk     : out std_logic;
      spi_mosi    : out std_logic;
      spi_le      : out std_logic;
      spi_syn     : out std_logic;
      spi_powerdn : out std_logic;
      spi_revdata : out std_logic_vector(31 downto 0);
      cfg_finish  : out std_logic
      );
  end component;
  -------------------------------------------------------------------------------
  component ADC_interface
    port(
      CLK1            : in  std_logic;
      user_pushbutton : in  std_logic;
      ADC_Mode        : out std_logic;
      ADC_sclk_OUT    : out std_logic;
      ADC_sldn_OUT    : out std_logic;
      ADC_gain_adj    : in  std_logic_vector(18 downto 0);
      ADC_reconfig    : in  std_logic;
      ADC_sdata       : out std_logic_vector(0 to 0)
      );
  end component;
-------------------------------------------------------------------------------
--   COMPONENT fft
--   PORT (
--     clk : IN STD_LOGIC;
--     ce : IN STD_LOGIC;
--     sclr : IN STD_LOGIC;
--     start : IN STD_LOGIC;
--     xn_re : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--     xn_im : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--     fwd_inv : IN STD_LOGIC;
--     fwd_inv_we : IN STD_LOGIC;
--     scale_sch : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
--     scale_sch_we : IN STD_LOGIC;
--     rfd : OUT STD_LOGIC;
--     xn_index : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
--     busy : OUT STD_LOGIC;
--     edone : OUT STD_LOGIC;
--     done : OUT STD_LOGIC;
--     dv : OUT STD_LOGIC;
--     xk_index : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
--     xk_re : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--     xk_im : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--     ovflo : OUT STD_LOGIC
--   );
-- END COMPONENT;
  -----------------------------------------------------------------------------
  component G_ethernet_top
    port(
      -- rst_n_gb_i                : in     std_logic;
      rst_eth_r_n         : in  std_logic;
      rst_eth_t_n         : in  std_logic;
      fifo_upload_data    : in  std_logic_vector(7 downto 0);
      Rd_clk              : in  std_logic;
      Rd_en               : in  std_logic;
      Rd_Addr             : in  std_logic_vector(13 downto 0);
      PHY_RXD             : in  std_logic_vector(3 downto 0);
      PHY_RXC             : in  std_logic;
      PHY_RXDV            : in  std_logic;
      CLK_125M            : in  std_logic;
      CLK_125M_quar       : in  std_logic;
      PHY_TXD_o           : out std_logic_vector(3 downto 0);
      PHY_GTXclk_quar     : out std_logic;
      phy_txen_quar       : out std_logic;
      phy_txer_o          : out std_logic;
      rst_n_o             : out std_logic;
      Rd_data             : out std_logic_vector(7 downto 0);
      Frm_valid           : out std_logic;
      -- ram_wren            : buffer std_logic;
      ram_rden            : out std_logic;
      -- ram_start                 : in     std_logic;
      -- srcc1_p_trigin            : in     std_logic;
      -- ram_last                  : in     std_logic;
      -- SRCC1_n_upload_sma_trigin : in     std_logic;
      -- upload_trig_ethernet      : in     std_logic;
      clear_frame_cnt     : in  std_logic;
      TX_dst_MAC_addr     : in  std_logic_vector(47 downto 0);
      sample_en           : in  std_logic;
      TX_src_MAC_addr     : in  std_logic_vector(3 downto 0);
      CH_flag             : in  std_logic_vector(7 downto 0);
      -- ch_stat             : in     std_logic_vector(1 downto 0);
      mult_frame_en       : in  std_logic;
      sw_ram_last         : in  std_logic;
      data_strobe         : out std_logic;
      tx_rdy         : out std_logic;
      ether_trig          : in  std_logic
      );
  end component;
  -----------------------------------------------------------------------------
  component cmd_ana_top
    port(
      rd_clk               : in     std_logic;
      rst_n                : in     std_logic;
      ethernet_frm_valid   : in     std_logic;
      ethernet_rd_data     : in     std_logic_vector(7 downto 0);
      frm_length           : out    std_logic_vector(15 downto 0);
      frm_type             : out    std_logic_vector(15 downto 0);
      ram_start            : out    std_logic;
      self_adpt_en         : out    std_logic;
      upload_trig_ethernet : out    std_logic;
      ram_switch           : out    std_logic_vector(2 downto 0);
      TX_dst_MAC_addr      : out    std_logic_vector(47 downto 0);
      is_counter				: out    std_logic;
      wait_cnt_set         : out    std_logic_vector(23 downto 0);
      cmd_smpl_en          : out    std_logic;
      cmd_smpl_depth       : out    std_logic_vector(15 downto 0);
      cmd_smpl_trig_cnt    : out    std_logic_vector(23 downto 0);
      cmd_pstprc_IQ_sw     : out    std_logic_vector(1 downto 0);
      clear_frame_cnt      : out    std_logic;
      ethernet_Rd_en       : out    std_logic;
      ethernet_Rd_Addr     : out    std_logic_vector(13 downto 0);
      Cmd_demowinln        : out    std_logic_vector(14 downto 0);
      Cmd_demowinstart     : out    std_logic_vector(14 downto 0);
      cmd_ADC_gain_adj     : out    std_logic_vector(18 downto 0);
      cmd_ADC_reconfig     : buffer std_logic;
      cmd_pstprc_num_en    : out    std_logic;
      cmd_Pstprc_num       : out    std_logic_vector(3 downto 0);
      cmd_Pstprc_DPS       : out    std_logic_vector(dds_phase_width downto 0);
      cmd_Estmr_A          : out    std_logic_vector(31 downto 0);
      cmd_Estmr_B          : out    std_logic_vector(31 downto 0);
      cmd_Estmr_C          : out    std_logic_vector(63 downto 0);
      cmd_Estmr_sync_en    : out    std_logic;
      cmd_Estmr_num        : out    std_logic_vector(3 downto 0);
      cmd_Estmr_num_en     : out    std_logic
     -- cmd_Pstprc_dps_en : out std_logic
      );
  end component;
  -----------------------------------------------------------------------------
  component crg_dcms
    port(
      OSC_in_p          : in     std_logic;
      OSC_in_n          : in     std_logic;
      ADC_CLKOI_p       : in     std_logic;
      ADC_CLKOI_n       : in     std_logic;
      CLK_EXT_250M : in std_logic;
      PHY_RXC           : in     std_logic;
      ADC_CLKOI         : buffer std_logic;
      ADC_CLKOQ         : out    std_logic;
      PHY_RXC_g         : out    std_logic;
      ADC_clkoi_inv     : out    std_logic;
      ADC_clkoq_inv     : out    std_logic;
      REF_SRAM          : out    std_logic;
      CLK_SRAM          : out    std_logic;
      CLK_125M          : out    std_logic;
      CLK_200M          : out    std_logic;
--      CLK_250M          : out    std_logic;
--      CLK_500M : out std_logic;
      CLK_EXT_500M :out std_logic;
      CLK_125M_quar     : out    std_logic
      );
  end component;
-------------------------------------------------------------------------------
  component DATAin_IOB
    port(
      CLK_200M     : in  std_logic;
      ADC_CLKOI    : in  std_logic;
      ADC_CLKOQ    : in  std_logic;
      ADC_DOQB_p   : in  std_logic_vector(7 downto 0);
      ADC_DOQB_n   : in  std_logic_vector(7 downto 0);
      ADC_DOQA_p   : in  std_logic_vector(7 downto 0);
      ADC_DOQA_n   : in  std_logic_vector(7 downto 0);
      ADC_DOIB_p   : in  std_logic_vector(7 downto 0);
      ADC_DOIB_n   : in  std_logic_vector(7 downto 0);
      ADC_DOIA_p   : in  std_logic_vector(7 downto 0);
      ADC_DOIA_n   : in  std_logic_vector(7 downto 0);
      ADC_DOQB_2_d : out std_logic_vector(7 downto 0);
      ADC_DOQA_2_d : out std_logic_vector(7 downto 0);
      ADC_DOQB_1_d : out std_logic_vector(7 downto 0);
      ADC_DOQA_1_d : out std_logic_vector(7 downto 0);
      ADC_DOIB_2_d : out std_logic_vector(7 downto 0);
      ADC_DOIA_2_d : out std_logic_vector(7 downto 0);
      ADC_DOIB_1_d : out std_logic_vector(7 downto 0);
      ADC_DOIA_1_d : out std_logic_vector(7 downto 0)
      );
  end component;

  component TRIG_ctrl
    port(
      clk                   : in  std_logic;
      rst_n                 : in  std_logic;
      cmd_smpl_en           : in  std_logic;
      cmd_smpl_trig_cnt     : in  std_logic_vector(23 downto 0);
      trig_recv_cnt         : out  std_logic_vector(23 downto 0);
      ram_start             : in  std_logic;
      SRCC1_p_trigin        : in  std_logic;
      SRCC1_p_trigout 		 : out std_logic;
      posedge_sample_trig_o : out std_logic
      );
  end component;

  component Channel_switch
    port(
      rst_n                 : in  std_logic;
      CLK                   : in  std_logic;
      cmd_pstprc_IQ_sw      : in  std_logic_vector(1 downto 0);
      posedge_sample_trig   : in  std_logic;
      Ram_Q_last            : in  std_logic;
      Ram_I_last            : in  std_logic;
      Ram_I_doutb           : in  std_logic_vector(7 downto 0);
      Ram_Q_doutb           : in  std_logic_vector(7 downto 0);
      Ram_rden              : in  std_logic;
      pstprc_fifo_data      : in  std_logic_vector(7 downto 0);
      pstprc_fifo_pempty    : in  std_logic;
      pstprc_finish         : in  std_logic;
      CM_Ram_Q_rden_o       : out std_logic;
      CM_Ram_I_rden_o       : out std_logic;
      CW_Pstprc_fifo_rden_o : out std_logic;
      sw_RAM_last           : out std_logic;
      CW_ether_trig         : out std_logic;
      CW_mult_frame_en_o    : out std_logic;
      CW_demo_smpl_trig_o   : out std_logic;
      CW_wave_smpl_trig_o   : out std_logic;
      FIFO_upload_data      : out std_logic_vector(7 downto 0);
      CW_CH_flag            : out std_logic_vector(7 downto 0)
      );
  end component;
-------------------------------------------------------------------------------

  component RAM_top
    port(
      clk_125M            : in  std_logic;
      -- ram_wren            : in  std_logic;
      posedge_sample_trig : in  std_logic;
      rst_adc_n              : in  std_logic;
      rst_data_n             : in  std_logic;
      cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
      ram_Q_dina          : in  std_logic_vector(31 downto 0);
      ram_Q_clka          : in  std_logic;
      ram_Q_clkb          : in  std_logic;
      ram_Q_rden          : in  std_logic;
      ram_I_dina          : in  std_logic_vector(31 downto 0);
      ram_I_clka          : in  std_logic;
      ram_I_clkb          : in  std_logic;
      ram_I_rden          : in  std_logic;
      ram_Q_doutb         : out std_logic_vector(7 downto 0);
      ram_Q_last          : out std_logic;
      ram_Q_full          : out std_logic;
      ram_I_doutb         : out std_logic_vector(7 downto 0);
      ram_I_last          : out std_logic;
      ram_I_full          : out std_logic
      );
  end component;
-------------------------------------------------------------------------------

  component Dmod_Seg
    port(
      clk                 : in  std_logic;
      -- pstprc_ram_wren : IN std_logic;
      posedge_sample_trig : in  std_logic;
      rst_data_proc_n     : in  std_logic;
      rst_adc_n           : in std_logic;
      rst_feedback_n      : in  std_logic;
      cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
      Pstprc_RAMQ_dina    : in  std_logic_vector(31 downto 0);
      Pstprc_RAMQ_clka    : in  std_logic;
      Pstprc_RAMQ_clkb    : in  std_logic;
      Pstprc_RAMI_dina    : in  std_logic_vector(31 downto 0);
      Pstprc_RAMI_clka    : in  std_logic;
      Pstprc_RAMI_clkb    : in  std_logic;
      demoWinln_twelve    : in  std_logic_vector(14 downto 0);
      demoWinstart_twelve : in  std_logic_vector(14 downto 0);
      -- Pstprc_dps_en       : in std_logic;
      Pstprc_DPS_twelve   : in  std_logic_vector(dds_phase_width downto 0);
      Pstprc_IQ_seq_o     : out std_logic_vector(63 downto 0);
      pstprc_fifo_wren    : out std_logic;
      Pstprc_finish       : out std_logic;
      is_counter       : in  std_logic;
      pstprc_num_en       : in  std_logic;
      pstprc_num          : in  std_logic_vector(3 downto 0);
      Estmr_A_eight       : in  std_logic_vector(31 downto 0);
      Estmr_B_eight       : in  std_logic_vector(31 downto 0);
      Estmr_C_eight       : in  std_logic_vector(63 downto 0);
      Estmr_num_en        : in  std_logic;
      Estmr_num           : in  std_logic_vector(3 downto 0);
      Estmr_sync_en       : in  std_logic;
      clk_Estmr           : in  std_logic;  --clk250M
      clk_Oserdes         : in  std_logic;  --clk500M
      Estmr_OQ            : out std_logic   --Oserdes output
      );
  end component;
  -----------------------------------------------------------------------------
  component Pstprc_fifo_top
    port(
	   ui_clk_in : IN std_logic;
	   clk_200M : IN std_logic;
		clk_125M : IN std_logic;
		qdriip_cq_p : IN std_logic_vector(0 to 0);
		qdriip_cq_n : IN std_logic_vector(0 to 0);
		qdriip_q : IN std_logic_vector(35 downto 0);         
		qdriip_k_p : OUT std_logic_vector(0 to 0);
		qdriip_k_n : OUT std_logic_vector(0 to 0);
		qdriip_d : OUT std_logic_vector(35 downto 0);
		qdriip_sa : OUT std_logic_vector(18 downto 0);
		qdriip_w_n : OUT std_logic;
		qdriip_r_n : OUT std_logic;
		qdriip_bw_n : OUT std_logic_vector(3 downto 0);
		qdriip_dll_off_n : OUT std_logic;
		cal_done : OUT std_logic;
      rst_n               : in  std_logic;
      Pstprc_fifo_wr_clk  : in  std_logic;
      Pstprc_fifo_rd_clk  : in  std_logic;
      wait_cnt_set     : in  std_logic_vector(23 downto 0);
      Pstprc_fifo_din     : in  std_logic_vector(63 downto 0);
      Pstprc_fifo_wren    : in  std_logic;
      Pstprc_fifo_rden    : in  std_logic;
      tx_rdy    : in  std_logic;
      Pstprc_finish_in     : in  std_logic;
      Pstprc_finish_out    : out  std_logic;
      -- prog_empty_thresh   : in  std_logic_vector(6 downto 0);
      Pstprc_fifo_dout    : out std_logic_vector(7 downto 0);
      Pstprc_fifo_valid   : out std_logic;
      Pstprc_fifo_pempty  : out std_logic;
      pstprc_fifo_alempty : out std_logic
      );
  end component;
  -----------------------------------------------------------------------------
  component SelfAdpt
    port(
      clk250              : in  std_logic;
      clk200  				  : in  std_logic;
      rst_n  				  : in  std_logic;
      RDY          		  : in  std_logic;
      cmd_adpt     		  : in  std_logic;
      trig_input    		  : in  std_logic;--trig signal from DA board
		trig_from_trig_ctrl : in  std_logic;
      trig_output    	  : out std_logic;--trig signgal after IODELAY
      adpt_led    		  : out std_logic--the Self-adaption completion mark
      );
  end component; 
-------------------------------------------------------------------------------
-- component SRAM_interface
--   generic (
--     REFCLK_FREQ                : integer := 200.0;
--                                           --Iodelay Clock Frequency
--     MMCM_ADV_BANDWIDTH        : string  := "LOW";
--                                          -- MMCM programming algorithm
--     CLKFBOUT_MULT_F           : real  := 11.0;      -- write PLL VCO multiplier
--     CLKOUT_DIVIDE             : integer := 11;      -- VCO output divisor for fast (memory) clocks
--     DIVCLK_DIVIDE             : integer := 1;      -- write PLL VCO divisor
--     CLK_PERIOD                : integer := 16000;   -- Double the Memory Clk Period (in ps)
--     DEBUG_PORT                : string  := "OFF";  -- Enable debug port
--     CLK_STABLE                : integer := 2048;   -- Cycles till CQ/CQ# is stable
--     ADDR_WIDTH                : integer := 19;     -- Address Width
--     DATA_WIDTH                : integer := 36;     -- Data Width
--     BW_WIDTH                  : integer := 4;      -- Byte Write Width
--     BURST_LEN                 : integer := 4;      -- Burst Length
--     NUM_DEVICES               : integer := 1;      -- No. of Connected Memories
--     FIXED_LATENCY_MODE        : integer := 0;      -- Enable Fixed Latency
--     PHY_LATENCY               : integer := 0;      -- Expected Latency
--     SIM_CAL_OPTION            : string := "NONE"; -- Skip various calibration steps
--     SIM_INIT_OPTION           : string  := "NONE"; -- Simulation only. "NONE", "SIM_MODE"
--     PHASE_DETECT              : string := "OFF";   -- Enable Phase detector
--     IBUF_LPWR_MODE            : string := "OFF";  -- Input buffer low power mode
--     IODELAY_HP_MODE           : string := "ON";   -- IODELAY High Performance Mode
--     TCQ                       : integer := 1;   -- Simulation Register Delay
--     INPUT_CLK_TYPE        : string  := "DIFFERENTIAL"; -- # of clock type
--     IODELAY_GRP    : string  := "IODELAY_MIG";
--     RST_ACT_LOW           : integer := 1           -- Active Low Reset
--     );
--   port (
--     sys_clk_p                  : in std_logic;  --differential system clocks
--     sys_clk_n                  : in std_logic;
--     clk_ref_p                  : in std_logic;     --differential iodelayctrl clk
--     clk_ref_n                  : in std_logic;
--     qdriip_cq_p                : in std_logic_vector(NUM_DEVICES-1 downto 0); --Memory Interface
--     qdriip_cq_n                : in std_logic_vector(NUM_DEVICES-1 downto 0);
--     qdriip_q                   : in std_logic_vector(DATA_WIDTH-1 downto 0);
--     qdriip_k_p                 : out std_logic_vector(NUM_DEVICES-1 downto 0);
--     qdriip_k_n                 : out std_logic_vector(NUM_DEVICES-1 downto 0);
--     qdriip_d                   : out std_logic_vector(DATA_WIDTH-1 downto 0);
--     qdriip_sa                  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
--     qdriip_w_n                 : out std_logic;
--     qdriip_r_n                 : out std_logic;
--     qdriip_bw_n                : out std_logic_vector(BW_WIDTH-1 downto 0);
--     qdriip_dll_off_n           : out std_logic;
--     cal_done                   : out std_logic;
--     user_wr_cmd0               : in std_logic;      --User interface
--     user_wr_addr0              : in std_logic_vector(ADDR_WIDTH-1 downto 0);
--     user_rd_cmd0               : in std_logic;
--     user_rd_addr0              : in std_logic_vector(ADDR_WIDTH-1 downto 0);
--     user_wr_data0              : in std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
--     user_wr_bw_n0              : in std_logic_vector(BW_WIDTH*BURST_LEN-1 downto 0);
--     ui_clk                     : out std_logic;
--     ui_clk_sync_rst            : out std_logic;
--     user_rd_valid0             : out std_logic;
--     user_rd_data0              : out std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
--     sys_rst          : in std_logic
--     );
-- end component SRAM_interface;
---------------------------------------------------------------------------------primitive instantiation       
begin

  Inst_sys_reset_proc: sys_reset_proc PORT MAP(
    sys_rst_n_in => user_pushbutton ,
    sram_cal_done => sram_cal_done ,
    sys_clk => CLK_125M,
    clk_adc => ADC_CLKOI,
    clk_eth_r => PHY_RXC_g,
    clk_eth_t => CLK_125M,
    clk_data_proc => CLK_125M,
    clk_feedback => CLK_EXT_250M_R,
    clk_config=>clk_125M,
    clk_data => clk_125M,
    rst_data_n=>rst_data_n,
    rst_config_n=>rst_config_n,
    rst_adc_n => rst_adc_n,
    rst_eth_r_n => rst_eth_r_n,
    rst_eth_t_n => rst_eth_t_n,
    rst_data_proc_n =>rst_data_proc_n, 
    rst_feedback_n => rst_feedback_n
    );

  Inst_crg_dcms : crg_dcms port map(
    OSC_in_p          => OSC_in_p,
    OSC_in_n          => OSC_in_n,
    ADC_CLKOI_p       => ADC_CLKOI_p,
    ADC_CLKOI_n       => ADC_CLKOI_n,
    CLK_EXT_250M =>CLK_EXT_250M,
    PHY_RXC           => PHY_RXC,
    ADC_CLKOI         => ADC_CLKOI,
    ADC_CLKOQ         => ADC_CLKOQ,
    PHY_RXC_g         => PHY_RXC_g,
    ADC_clkoi_inv     => ADC_clkoi_inv,
    ADC_clkoq_inv     => ADC_clkoq_inv,
    REF_SRAM          => REF_SRAM,
    CLK_SRAM          => CLK_SRAM,
    CLK_125M          => CLK_125M,
    CLK_200M          => CLK_200M,
--    CLK_250M          => CLK_250M,
--    CLK_500M          => CLK_500M,
    CLK_EXT_500M => CLK_EXT_500M,
    CLK_125M_quar     => CLK_125M_quar
    );

  -- IBUFG_inst : IBUFG
  --   generic map (
  --     IBUF_LOW_PWR => false,  -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
  --     IOSTANDARD   => "DEFAULT")
  --   port map (
  --     O => user_pushbutton_g,           -- Clock buffer output
  --     I => user_pushbutton  -- Clock buffer input (connect directly to top-level port)
  --     );

  Inst_DATAin_IOB : DATAin_IOB port map(
    CLK_200M     => CLK_200M,
    ADC_CLKOI    => ADC_CLKOI,
    ADC_CLKOQ    => ADC_CLKOQ,
    ADC_DOQB_p   => ADC_DOQB_p,
    ADC_DOQB_n   => ADC_DOQB_n,
    ADC_DOQA_p   => ADC_DOQA_p,
    ADC_DOQA_n   => ADC_DOQA_n,
    ADC_DOIB_p   => ADC_DOIB_p,
    ADC_DOIB_n   => ADC_DOIB_n,
    ADC_DOIA_p   => ADC_DOIA_p,
    ADC_DOIA_n   => ADC_DOIA_n,
    ADC_DOQB_2_d => ADC_DOQB_2_d,
    ADC_DOQA_2_d => ADC_DOQA_2_d,
    ADC_DOQB_1_d => ADC_DOQB_1_d,
    ADC_DOQA_1_d => ADC_DOQA_1_d,
    ADC_DOIB_2_d => ADC_DOIB_2_d,
    ADC_DOIA_2_d => ADC_DOIA_2_d,
    ADC_DOIB_1_d => ADC_DOIB_1_d,
    ADC_DOIA_1_d => ADC_DOIA_1_d
    );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
  Inst_ADC_interface : ADC_interface port map(
    ADC_Mode        => ADC_Mode,
    user_pushbutton => rst_config_n,
    ADC_sclk_OUT    => ADC_sclk_OUT,
    ADC_sldn_OUT    => ADC_sldn_OUT,
    ADC_sdata       => ADC_sdata,
    ADC_gain_adj    => cmd_ADC_gain_adj,
    ADC_reconfig    => cmd_ADC_reconfig,
    clk1            => CLK_125M
    );
-------------------------------------------------------------------------------

  Inst_CDCE62005_interface : CDCE62005_interface port map(
    clk         => CLK_125M,
    rst_n       => rst_config_n,
    spi_clk     => spi_clk,
    spi_mosi    => spi_mosi,
    spi_miso    => spi_miso,
    spi_le      => spi_le,
    spi_syn     => spi_syn,
    spi_powerdn => spi_powerdn,
    spi_revdata => spi_revdata,
    cfg_finish  => cfg_finish
    );
-------------------------------------------------------------------------------
  -- fft_I : fft
  -- PORT MAP (
  --   clk => CLK_125M,
  --   ce => fft_ce_I,
  --   sclr => fft_sclr_I,
  --   start => fft_start_I,
  --   xn_re => fft_xn_re_I,
  --   xn_im => fft_xn_im_I,
  --   fwd_inv => '1',
  --   fwd_inv_we => '1',
  --   scale_sch =>fft_scale_sch_I,
  --   scale_sch_we => '1',
  --   rfd => fft_rfd_I,
  --   xn_index => fft_xn_index_I,
  --   busy => fft_busy_I,
  --   edone => fft_edone_I,
  --   done => fft_done_I,
  --   dv => fft_dv_I,
  --   xk_index => fft_xk_index_I,
  --   xk_re => fft_xk_re_I,
  --   xk_im => fft_xk_im_I,
  --   ovflo => fft_ovflo_I
  -- );
  -- fft_xn_im_I<=x"00";
  -- fft_xn_re_I<=ram_i_doutb;
  -- fft_ce_I<='1';
  -- fft_sclr_I<='0';
  -- fft_start_I<=ram_rden;
  -- fft_scale_sch_I<="01010101010101";        --14bit,7bit scaling factor=128 
  ------------------------------------------------------------------------------ 
  Inst_TRIG_ctrl : TRIG_ctrl port map(
    clk                   => ADC_CLKOI,
    rst_n                 => rst_adc_n,
    cmd_smpl_en           => cmd_smpl_en,
    cmd_smpl_trig_cnt     => cmd_smpl_trig_cnt,
    trig_recv_cnt         => open,
    ram_start             => ram_start,
    SRCC1_p_trigin        => SelfAdpt_trig,--trig from IODELAYE1
    SRCC1_p_trigout       => SRCC1_p_trigout,--trig from IODELAYE1
    posedge_sample_trig_o => posedge_sample_trig
    );

-------------------------------------------------------------------------------
  Inst_G_ethernet_top : G_ethernet_top port map(
    -- rst_n_gb_i => ethernet_rst_n_gb_i,
    PHY_TXD_o           => PHY_TXD_o,
    PHY_GTXclk_quar     => PHY_GTXclk_quar,
    phy_txen_quar       => phy_txen_quar,
    phy_txer_o          => phy_txer_o,
    rst_eth_r_n     => rst_eth_r_n,
    rst_eth_t_n     => rst_eth_t_n,
    rst_n_o             => phy_rst_n_o,
    fifo_upload_data    => ethernet_fifo_upload_data,
    Rd_clk              => ethernet_Rd_clk,
    Rd_en               => ethernet_Rd_en,
    Rd_Addr             => ethernet_Rd_Addr,
    PHY_RXD             => PHY_RXD,
    PHY_RXC             => phy_rxc_g,
    PHY_RXDV            => PHY_RXDV,
    Rd_data             => ethernet_Rd_data,
    Frm_valid           => ethernet_Frm_valid,
    CLK_125M            => CLK_125M,
    CLK_125M_quar       => CLK_125M_quar,
    -- ram_wren            => ram_wren,
    ram_rden            => ram_rden,
    clear_frame_cnt     => clear_frame_cnt,
    TX_dst_MAC_addr     => TX_dst_MAC_addr,
    TX_src_MAC_addr     => TX_src_MAC_addr,
    sample_en           => sample_en,
    CH_flag             => CW_CH_flag,
    -- ch_stat             => ch_stat,
    mult_frame_en       => CW_mult_frame_en,
    sw_ram_last         => sw_ram_last,
    Data_strobe         => data_strobe,
    tx_rdy         => tx_rdy,
    ether_trig          => CW_ether_trig
    );
-------------------------------------------------------------------------------
  Inst_cmd_ana_top : cmd_ana_top port map(
    rd_clk               => ethernet_Rd_clk,
    frm_length           => cmd_frm_length,
    frm_type             => cmd_frm_type,
    ram_start            => ram_start,
    upload_trig_ethernet => upload_trig_ethernet,
    clear_frame_cnt      => clear_frame_cnt,
    rst_n                => rst_data_n,
    TX_dst_MAC_addr      => TX_dst_MAC_addr,
    cmd_smpl_en          => cmd_smpl_en,
    cmd_smpl_depth       => cmd_smpl_depth,
    cmd_smpl_trig_cnt    => cmd_smpl_trig_cnt,
    cmd_pstprc_IQ_sw     => cmd_pstprc_IQ_sw,
	 
    is_counter  => is_counter,    
    wait_cnt_set  => wait_cnt_set,    
    self_adpt_en       	 => self_adpt_en,
    ethernet_Rd_en       => ethernet_Rd_en,
    ethernet_Rd_Addr     => ethernet_Rd_Addr,
    ethernet_frm_valid   => ethernet_frm_valid,
    ethernet_rd_data     => ethernet_rd_data,
    cmd_demowinln        => cmd_demowinln,
    cmd_demowinstart     => cmd_demowinstart,
    cmd_ADC_gain_adj     => cmd_ADC_gain_adj,
    cmd_ADC_reconfig     => cmd_ADC_reconfig,
    cmd_Pstprc_num       => cmd_Pstprc_num,
    cmd_Pstprc_num_en    => cmd_Pstprc_num_en,
    cmd_Pstprc_DPS       => cmd_Pstprc_DPS,
    cmd_Estmr_num        => cmd_Estmr_num,
    cmd_Estmr_num_en     => cmd_Estmr_num_en,
    cmd_Estmr_A          => cmd_Estmr_A,
    cmd_Estmr_B          => cmd_Estmr_B,
    cmd_Estmr_C          => cmd_Estmr_C,
    cmd_Estmr_sync_en    => cmd_Estmr_sync_en
   -- cmd_Pstprc_DPS_en => cmd_Pstprc_DPS_en
    );
  -----------------------------------------------------------------------------
  Inst_Channel_switch : Channel_switch port map(
    rst_n                 => rst_data_n,
    CLK                   => CLK_125M,
    cmd_pstprc_IQ_sw      => cmd_pstprc_IQ_sw,
    posedge_sample_trig   => posedge_sample_trig,
    Ram_Q_last            => Ram_Q_last,
    Ram_I_last            => Ram_I_last,
    Ram_I_doutb           => Ram_I_doutb,
    Ram_Q_doutb           => Ram_Q_doutb,
    Ram_rden              => Ram_rden,
    pstprc_fifo_data      => pstprc_fifo_dout,
    Pstprc_fifo_pempty    => pstprc_fifo_pempty,
    pstprc_finish         => Pstprc_finish_out,
    CM_Ram_Q_rden_o       => CM_Ram_Q_rden,
    CM_Ram_I_rden_o       => CM_Ram_I_rden,
    CW_Pstprc_fifo_rden_o => CW_Pstprc_fifo_rden,
    sw_RAM_last           => sw_RAM_last,
    CW_ether_trig         => CW_ether_trig,
    CW_mult_frame_en_o    => CW_mult_frame_en,
    CW_demo_smpl_trig_o   => CW_demo_smpl_trig,
    CW_wave_smpl_trig_o   => CW_wave_smpl_trig,
    FIFO_upload_data      => ethernet_FIFO_upload_data,
    CW_CH_flag            => CW_CH_flag
    );

-- -------------------------------------------------------------------------------
--   inst_SRAM : SRAM_interface
--   generic map(
--     REFCLK_FREQ                => REFCLK_FREQ,
--     MMCM_ADV_BANDWIDTH         => MMCM_ADV_BANDWIDTH,
--     CLKFBOUT_MULT_F            => CLKFBOUT_MULT_F,
--     CLKOUT_DIVIDE              => CLKOUT_DIVIDE,
--     DIVCLK_DIVIDE              => DIVCLK_DIVIDE,
--     CLK_PERIOD                 => CLK_PERIOD,
--     DEBUG_PORT                 => DEBUG_PORT,
--     CLK_STABLE                 => CLK_STABLE,
--     ADDR_WIDTH                 => ADDR_WIDTH,
--     DATA_WIDTH                 => DATA_WIDTH,
--     BW_WIDTH                   => BW_WIDTH,
--     BURST_LEN                  => BURST_LEN,
--     NUM_DEVICES                => NUM_DEVICES,
--     FIXED_LATENCY_MODE         => FIXED_LATENCY_MODE,
--     PHY_LATENCY                => PHY_LATENCY,
--     SIM_CAL_OPTION             => SIM_CAL_OPTION,
--     SIM_INIT_OPTION            => SIM_INIT_OPTION,
--     PHASE_DETECT               => PHASE_DETECT,
--     IBUF_LPWR_MODE             => IBUF_LPWR_MODE,
--     IODELAY_HP_MODE            => IODELAY_HP_MODE,
--     TCQ                        => TCQ,
--     INPUT_CLK_TYPE     => INPUT_CLK_TYPE,
--     IODELAY_GRP => IODELAY_GRP,
--     RST_ACT_LOW        => RST_ACT_LOW
--     )
--   port map(
--     sys_clk_p                  => sys_clk_p,
--     sys_clk_n                  => sys_clk_n,
--     clk_ref_p                  => clk_ref_p,
--     clk_ref_n                  => clk_ref_n,
--     qdriip_cq_p                => qdriip_cq_p,
--     qdriip_cq_n                => qdriip_cq_n,
--     qdriip_q                   => qdriip_q,
--     qdriip_k_p                 => qdriip_k_p,
--     qdriip_k_n                 => qdriip_k_n,
--     qdriip_d                   => qdriip_d,
--     qdriip_sa                  => qdriip_sa,
--     qdriip_w_n                 => qdriip_w_n,
--     qdriip_r_n                 => qdriip_r_n,
--     qdriip_bw_n                => qdriip_bw_n,
--     qdriip_dll_off_n           => qdriip_dll_off_n,
--     cal_done                   => cal_done,
--     user_wr_cmd0               => user_wr_cmd0,
--     user_wr_addr0              => user_wr_addr0,
--     user_rd_cmd0               => user_rd_cmd0,
--     user_rd_addr0              => user_rd_addr0,
--     user_wr_data0              => user_wr_data0,
--     user_wr_bw_n0              => user_wr_bw_n0,
--     ui_clk                     => ui_clk,
--     ui_clk_sync_rst            => ui_clk_sync_rst,
--     user_rd_valid0             => user_rd_valid0,
--     user_rd_data0              => user_rd_data0,
--     sys_rst                => sys_rst
--     );

  -----------------------------------------------------------------------------
  Inst_RAM_top : RAM_top port map(
    clk_125m            => clk_125m,
    -- ram_wren            => ram_wren,
    posedge_sample_trig => CW_wave_smpl_trig,
    rst_adc_n           => rst_adc_n,
    rst_data_n          => rst_data_n,
    cmd_smpl_depth      => cmd_smpl_depth,
    ram_Q_dina          => ram_Q_dina,
    ram_Q_clka          => ram_Q_clka,
    ram_Q_clkb          => ram_Q_clkb,
    ram_Q_rden          => CM_Ram_Q_rden,
    ram_Q_doutb         => ram_Q_doutb,
    ram_Q_last          => ram_Q_last,
    ram_Q_full          => ram_Q_full,
    ram_I_dina          => ram_I_dina,
    ram_I_clka          => ram_I_clka,
    ram_I_clkb          => ram_I_clkb,
    ram_I_rden          => CM_Ram_I_rden,
    ram_I_doutb         => ram_I_doutb,
    ram_I_last          => ram_I_last,
    ram_I_full          => ram_I_full
    );
  ram_Q_dina <= ADC_DOQB_2_d&ADC_DOQA_2_d&ADC_DOQB_1_d&ADC_DOQA_1_d;
  ram_I_dina <= ADC_DOiB_2_d&ADC_DOiA_2_d&ADC_DOiB_1_d&ADC_DOiA_1_d;
  ram_Q_clkb <= CLK_125M;
  ram_I_clkb <= CLK_125M;
  ram_Q_clka <= ADC_clkoq;
  ram_I_clka <= ADC_clkoi;
-----------------------------------------------------------------------------
  Inst_Dmod_Seg : Dmod_Seg port map(
    clk                 => CLK_125M,
    clk_Estmr           => CLK_EXT_250M_R,
    clk_Oserdes         => CLK_EXT_500M_R,
    -- pstprc_ram_wren     => pstprc_ram_wren,
    posedge_sample_trig => CW_demo_smpl_trig,
    rst_data_proc_n     => rst_data_proc_n,
    rst_adc_n           => rst_adc_n,
    rst_feedback_n      => rst_feedback_n,
    cmd_smpl_depth      => cmd_smpl_depth,
    Pstprc_RAMQ_dina    => Pstprc_RAMQ_dina,
    Pstprc_RAMQ_clka    => Pstprc_RAMQ_clka,
    Pstprc_RAMQ_clkb    => Pstprc_RAMQ_clkb,
    Pstprc_RAMI_dina    => Pstprc_RAMI_dina,
    Pstprc_RAMI_clka    => Pstprc_RAMI_clka,
    Pstprc_RAMI_clkb    => Pstprc_RAMI_clkb,
    demoWinln_twelve    => cmd_demoWinln,
    demoWinstart_twelve => cmd_demoWinstart,
    is_counter => is_counter,
    -- Pstprc_dps_en       => cmd_Pstprc_dps_en,
    Pstprc_DPS_twelve   => cmd_Pstprc_DPS,
    Pstprc_IQ_seq_o     => Pstprc_IQ_seq_o,
    Pstprc_finish       => Pstprc_finish,
    pstprc_fifo_wren    => pstprc_fifo_wren,
    pstprc_num_en       => cmd_pstprc_num_en,
    pstprc_num          => cmd_Pstprc_num,
    Estmr_num_en        => cmd_Estmr_num_en,
    Estmr_num           => cmd_Estmr_num,
    Estmr_A_eight       => cmd_Estmr_A,
    Estmr_B_eight       => cmd_Estmr_B,
    Estmr_C_eight       => cmd_Estmr_C,
    Estmr_sync_en       => cmd_Estmr_sync_en,
    Estmr_OQ            => Estmr_OQ

    );
  Pstprc_RAMQ_clka <= ADC_clkoq;
  Pstprc_RAMQ_clkb <= CLK_125M;
  Pstprc_RAMI_clka <= ADC_clkoi;
  Pstprc_RAMI_clkb <= CLK_125M;
  Pstprc_RAMQ_dina <= ADC_DOQB_2_d&ADC_DOQA_2_d&ADC_DOQB_1_d&ADC_DOQA_1_d;
  Pstprc_RAMI_dina <= ADC_DOiB_2_d&ADC_DOiA_2_d&ADC_DOiB_1_d&ADC_DOiA_1_d;
  pstprc_ram_wren  <= ram_wren;
  cal_done  <= sram_cal_done;
  
  -----------------------------------------------------------------------------
  Inst_Pstprc_fifo_top : Pstprc_fifo_top port map(
    rst_n               => rst_data_proc_n,
	 ---------------------------------------------------
	 ui_clk_in                   => CLK_SRAM,
	 CLK_125M                   => clk_125M,
    CLK_200M                   => REF_SRAM,
    qdriip_cq_p                => qdriip_cq_p,
    qdriip_cq_n                => qdriip_cq_n,
    qdriip_q                   => qdriip_q,
    qdriip_k_p                 => qdriip_k_p,
    qdriip_k_n                 => qdriip_k_n,
    qdriip_d                   => qdriip_d,
    qdriip_sa                  => qdriip_sa,
    qdriip_w_n                 => qdriip_w_n,
    qdriip_r_n                 => qdriip_r_n,
    qdriip_bw_n                => qdriip_bw_n,
    qdriip_dll_off_n           => qdriip_dll_off_n,
    cal_done                   => sram_cal_done,
	 ---------------------------------------------------
    tx_rdy  => tx_rdy,    --same with the clk in dmog_seg
    wait_cnt_set  => wait_cnt_set,    --same with the clk in dmog_seg
    Pstprc_finish_in  => Pstprc_finish,    --same with the clk in dmog_seg
    Pstprc_finish_out  => Pstprc_finish_out,    --same with the clk in dmog_seg
    Pstprc_fifo_wr_clk  => clk_125M,    --same with the clk in dmog_seg
    Pstprc_fifo_rd_clk  => clk_125M,    --same with the clk in pstprc
    Pstprc_fifo_din     => Pstprc_IQ_seq_o,
    Pstprc_fifo_wren    => Pstprc_fifo_wren,
    Pstprc_fifo_rden    => CW_Pstprc_fifo_rden,
    -- prog_empty_thresh   => "0000011",   --modify the repetitation byte 
    Pstprc_fifo_dout    => Pstprc_fifo_dout,
    Pstprc_fifo_valid   => Pstprc_fifo_valid,
    Pstprc_fifo_pempty  => Pstprc_fifo_pempty,
    pstprc_fifo_alempty => pstprc_fifo_alempty
    );
  ------------------------------------------------------------------------------
  Inst_SelfAdpt : SelfAdpt port map(
	 clk250					=>ADC_CLKOI,
	 clk200					=>CLK_200M,
	 rst_n					=>rst_adc_n,
	 RDY						=>sram_cal_done,
	 cmd_adpt				=>cmd_adpt,
	 trig_input				=>SRCC1_p_trigin,--trig from DA board
	 trig_from_trig_ctrl	=>SRCC1_p_trigout,--trig from Trig_ctrl
	 trig_output			=>SelfAdpt_trig,--trig from IODELAYE1
	 adpt_led				=>adpt_led
	 );
	 
	 cmd_adpt <= self_adpt_en;
  ------------------------------------------------------------------------------
  -- SRCC1_p         <= CLK_250M;     --j12



  -- BUFG_inst : BUFG
  --   port map (
  --     O => rst_n,                       -- 1-bit output: Clock buffer output
  --     I => rst_n_a                      -- 1-bit input: Clock buffer input
  --     );

-------------------------------------------------------------------------------
     OBUFDS_inst : OBUFDS
   generic map (
      IOSTANDARD => "DEFAULT")
   port map (
      O => Estmr_OQ_p,     -- Diff_p output (connect directly to top-level port)
      OB => Estmr_OQ_n,   -- Diff_n output (connect directly to top-level port)
      I => Estmr_OQ      -- Buffer input 
      );
  
  ethernet_rd_clk <= CLK_125M;
  trig_monitor    <= SRCC1_p_trigout;
  
    -- BUFG_inst2 : BUFG
    -- port map (
    --   O => clk_EXT_250M_g,                       -- 1-bit output: Clock buffer output
    --   I => clk_EXT_250M                      -- 1-bit input: Clock buffer input
  --   );

     BUFR_inst0 : BUFR
   generic map (
      BUFR_DIVIDE => "4", -- Values: "BYPASS", "1", "2", "3", "4", "5", "6", "7", "8" 
      SIM_DEVICE => "VIRTEX6"  -- Must be set to "VIRTEX6" 
   )
   port map (
      O => clk_EXT_250M_R,     -- 1-bit output: Clock buffer output
      CE => '1',   -- 1-bit input: Active high clock enable input
      CLR => '0', -- 1-bit input: Active high reset input
      I => CLK_EXT_500M      -- 1-bit input: Clock buffer input driven by an IBUFG, MMCM or local interconnect
      );
  
       BUFR_inst1 : BUFR
   generic map (
      BUFR_DIVIDE => "2", -- Values: "BYPASS", "1", "2", "3", "4", "5", "6", "7", "8" 
      SIM_DEVICE => "VIRTEX6"  -- Must be set to "VIRTEX6" 
   )
   port map (
      O => clk_EXT_500M_R,     -- 1-bit output: Clock buffer output
      CE => '1',   -- 1-bit input: Active high clock enable input
      CLR => '0', -- 1-bit input: Active high reset input
      I => CLK_EXT_500M      -- 1-bit input: Clock buffer input driven by an IBUFG, MMCM or local interconnect
   );
--注释掉clk_ext_250M的bufG后需要把mmcm的配置 输入端改成普通IO
-----------------------------------------------------------------------------
-- SRCC1_p <= clk_250M;
-- SRCC1_n <= ram_Q_clka;
-- MRCC1_p <=ram_I_clka;
-- MRCC1_n <= ram_wren;
end Behavioral;



