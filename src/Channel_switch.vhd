----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:45:04 04/18/2017 
-- Design Name: 
-- Module Name:    Channel_switch - Behavioral 
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

entity Channel_switch is
  port (
    rst_n            : in std_logic;
    CLK              : in std_logic;
    cmd_pstprc_IQ_sw : in std_logic_vector(1 downto 0);  --switch criterion 

    CM_Ram_Q_rden_o       : out std_logic;  --switch_signal 000 output
    CM_Ram_I_rden_o       : out std_logic;  --switch_signal 001 output
    CW_Pstprc_fifo_rden_o : out std_logic;  ----switch_signal 01 output
    Ram_rden              : in  std_logic;  -- switch_signal 0 input

    Ram_Q_last         : in  std_logic;  ----switch_signal 100 input
    Ram_I_last         : in  std_logic;  ----switch_signal 101 input
    Pstprc_fifo_pempty : in  std_logic;  --switch_signal 11 input
    sw_RAM_last        : out std_logic;  ----switch_signal 1 output

    Ram_I_doutb      : in  std_logic_vector(7 downto 0);  -- switch_signal 201 input
    Ram_Q_doutb      : in  std_logic_vector(7 downto 0);  -- switch_signal 200 input
    pstprc_fifo_data : in  std_logic_vector(7 downto 0);  --switch_signal 21 input
    FIFO_upload_data : out std_logic_vector(7 downto 0);  --switch_signal 2 output

    pstprc_finish       : in  std_logic;  --switch_signal 31 input 
    posedge_sample_trig : in  std_logic;  --switch_signal 30 input
    CW_ether_trig       : out std_logic;  --switch_signal 3 output
    
    CW_mult_frame_en_o : out std_logic;  -- frame_en
    CW_demo_smpl_trig_o : out std_logic;
    CW_wave_smpl_trig_o : out std_logic;
    CW_CH_flag : out std_logic_vector(7 downto 0)
    );
end Channel_switch;

architecture Behavioral of Channel_switch is

  signal CM_RAM_rden          : std_logic;
-- signal CM_Ram_Q_rden_o    : std_logic;
-- signal CM_Ram_I_rden_o    : std_logic;
  signal CM_mult_frame_en_o   : std_logic;
  signal CM_CH_flag_o         : std_logic_vector(7 downto 0);
-- signal CM_CH_stat_o : std_logic_vector(1 downto 0);
  signal CM_RAM_QI_data_o     : std_logic_vector(7 downto 0);
  signal Pstprc_fifo_rden     : std_logic;
  signal CM_RAM_last_o        : std_logic;
  signal posedge_pempty       : std_logic;
  signal pstprc_fifo_pempty_d : std_logic;
  signal wave_smpl_trig : std_logic;
  signal demo_smpl_trig : std_logic;
  component Channel_multiplex
    port(
      clk              : in  std_logic;
      rst_n            : in  std_logic;
      ram_rden         : in  std_logic;
      Ram_Q_last       : in  std_logic;
      Ram_I_last       : in  std_logic;
      Ram_I_doutb      : in  std_logic_vector(7 downto 0);
      Ram_Q_doutb      : in  std_logic_vector(7 downto 0);
      CM_Ram_Q_rden_o  : out std_logic;
      CM_Ram_I_rden_o  : out std_logic;
      mult_frame_en_o  : out std_logic;
      CH_flag_o        : out std_logic_vector(7 downto 0);
      CM_RAM_QI_data_o : out std_logic_vector(7 downto 0);
      CM_RAM_last_o    : out std_logic
      );
  end component;

begin

  CW_Pstprc_fifo_rden_o <= Pstprc_fifo_rden;
  CW_demo_smpl_trig_o <=demo_smpl_trig;
    CW_wave_smpl_trig_o <=wave_smpl_trig;
  -- CH_stat_o <= CM_CH_stat_o;

  Inst_Channel_multiplex : Channel_multiplex port map(
    CLK              => clk,
    rst_n            => rst_n,
    Ram_rden         => CM_RAM_rden,
    Ram_Q_last       => Ram_Q_last,
    Ram_I_last       => Ram_I_last,
    Ram_I_doutb      => Ram_I_doutb,
    Ram_Q_doutb      => Ram_Q_doutb,
    CM_Ram_Q_rden_o  => CM_Ram_Q_rden_o,
    CM_Ram_I_rden_o  => CM_Ram_I_rden_o,
    mult_frame_en_o  => CM_mult_frame_en_o,
    CH_flag_o        => CM_CH_flag_o,
    -- CH_stat_o => CM_CH_stat_o,
    CM_RAM_QI_data_o => CM_RAM_QI_data_o,
    CM_RAM_last_o    => CM_RAM_last_o
    );

-------------------------------------------------------------------------------
  rden_mux_ps : process (clk, rst_n) is
  begin  -- process rden_mux_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
          Pstprc_fifo_rden <= '0';
          CM_RAM_rden      <= Ram_rden;
    -- elsif clk'event and clk = '1' then  -- rising clock edge
    else
      case cmd_pstprc_IQ_sw is
        when "01" =>
          Pstprc_fifo_rden <= '0';
          CM_RAM_rden      <= Ram_rden;
        when "10" =>
          Pstprc_fifo_rden <= Ram_rden;
          CM_RAM_rden      <= '0';
        when others =>
          Pstprc_fifo_rden <= '0';
          CM_RAM_rden      <= Ram_rden;
      end case;
    end if;
  end process rden_mux_ps;

  data_mux_ps : process (clk, rst_n) is
  begin  -- process data_mux_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      FIFO_upload_data <= CM_RAM_QI_data_o;
    -- elsif clk'event and clk = '1' then  -- rising clock edge
    else
      case cmd_pstprc_IQ_sw is
        when "01" =>
          FIFO_upload_data <= CM_RAM_QI_data_o;
        when "10" =>
          FIFO_upload_data <= Pstprc_fifo_data;
        when others =>
          FIFO_upload_data <= CM_RAM_QI_data_o;
      end case;
    end if;
  end process data_mux_ps;

  state_mux_ps : process (clk, rst_n) is
  begin  -- process state_mux_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      CW_CH_flag <= CM_CH_flag_o;
    else
      -- elsif clk'event and clk = '1' then  -- rising clock edge
      case cmd_pstprc_IQ_sw is
        when "01" =>
          CW_CH_flag <= CM_CH_flag_o;
        when "10" =>
          CW_CH_flag <= x"22";
        when others =>
          CW_CH_flag <= CM_CH_flag_o;
      end case;
    end if;
  end process state_mux_ps;

  last_byte_mux_ps : process (clk, rst_n) is
  begin  -- process   last_byte_mux_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
          sw_ram_last <= CM_RAM_last_o;
    else
      -- elsif clk'event and clk = '1' then  -- rising clock edge
      case cmd_pstprc_IQ_sw is
        when "01" =>
          sw_ram_last <= CM_RAM_last_o;
        when "10" =>
          sw_ram_last <= posedge_pempty;
        when others =>
          sw_ram_last <= CM_RAM_last_o;
      end case;
    end if;
  end process last_byte_mux_ps;

  ether_trig_mux_ps : process (clk, rst_n) is
  begin  -- process ether_trig_mux_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
          CW_ether_trig <= posedge_sample_trig;
    else
      -- elsif clk'event and clk = '1' then  -- rising clock edge
      case cmd_pstprc_IQ_sw is
        when "01" =>
          CW_ether_trig <= posedge_sample_trig;
        when "10" =>
          CW_ether_trig <= Pstprc_finish;
        when others =>
          CW_ether_trig <= posedge_sample_trig;
      end case;
    end if;
  end process ether_trig_mux_ps;

  mult_frame_en_ps : process (clk, rst_n) is
  begin  -- process mult_frame_en_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      CW_mult_frame_en_o <= CM_mult_frame_en_o;
    else
      -- elsif clk'event and clk = '1' then  -- rising clock edge
      case cmd_pstprc_IQ_sw is
        when "01" =>
          CW_mult_frame_en_o <= CM_mult_frame_en_o;
        when "10" =>
          CW_mult_frame_en_o <= '0';
        when others =>
          CW_mult_frame_en_o <= CM_mult_frame_en_o;
      end case;
    end if;
  end process mult_frame_en_ps;

  Pstprc_fifo_pempty_d_ps : process (clk, rst_n) is
  begin  -- process Pstprc_fifo_pempty_d
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Pstprc_fifo_pempty_d <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      Pstprc_fifo_pempty_d <= Pstprc_fifo_pempty;
    end if;
  end process Pstprc_fifo_pempty_d_ps;

  posedge_pempty_ps : process (clk, rst_n) is
  begin  -- process posedge_pempty_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      posedge_pempty <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      if Pstprc_fifo_pempty = '1' and Pstprc_fifo_pempty_d = '0' then
        posedge_pempty <= '1';
      else
        posedge_pempty <= '0';
      end if;
    end if;
  end process posedge_pempty_ps;

  -- purpose: to switch the sample trig between two modes
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: 
  posedge_sample_trig_switch_ps : process (clk, rst_n) is
  begin  -- process posedge_sample_trig_switch_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      demo_smpl_trig <= '0';
      wave_smpl_trig <= posedge_sample_trig;
    else
      case cmd_pstprc_IQ_sw is
        when "01" =>
          demo_smpl_trig <= '0';
          wave_smpl_trig <= posedge_sample_trig;
        when "10" =>
          demo_smpl_trig <= posedge_sample_trig;
          wave_smpl_trig <= '0';
        when others =>
          demo_smpl_trig <= '0';
          wave_smpl_trig <= posedge_sample_trig;
      end case;
    end if;
  end process posedge_sample_trig_switch_ps;

end Behavioral;

