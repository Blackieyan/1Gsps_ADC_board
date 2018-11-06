


----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:44:59 02/28/2017 
-- Design Name: 
-- Module Name:    Dmod_Seg - Behavioral 
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
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Dmod_Seg is
  generic (
    mult_accum_s_width : integer := 32;
    dds_phase_width    : integer := 24;
    pstprc_ch_num      : integer := 8;
    upload_freq_cnt    : std_logic_vector(3 downto 0) := x"8"

    );
  port(
    clk                 : in  std_logic;
    posedge_sample_trig : in  std_logic;
    rst_adc_n           : in std_logic;
    rst_data_proc_n     : in  std_logic;
    rst_feedback_n      : in  std_logic;
    is_counter          : in  std_logic;
    cmd_smpl_en          : in  std_logic;
    cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
    Pstprc_RAMQ_dina    : in  std_logic_vector(31 downto 0);
    Pstprc_RAMQ_clka    : in  std_logic;
    Pstprc_RAMQ_clkb    : in  std_logic;
    ---------------------------------------------------------------------------
    Pstprc_RAMI_dina    : in  std_logic_vector(31 downto 0);
    Pstprc_RAMI_clka    : in  std_logic;
    Pstprc_RAMI_clkb    : in  std_logic;
    ---------------------------------------------------------------------------
    demoWinln_twelve    : in  std_logic_vector(14 downto 0);
    demoWinstart_twelve : in  std_logic_vector(14 downto 0);
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    pstprc_IQ_seq_o     : out std_logic_vector(63 downto 0);
    Pstprc_finish       : out std_logic;
    -- Pstprc_fifo_rden :  in std_logic;
    -- Pstprc_fifo_rs : out std_logic_vector(7 downto 0);
    -- Pstprc_fifo_rdclk : in std_logic;   -- same with the ethernet txclk
    Pstprc_DPS_twelve   : in  std_logic_vector(dds_phase_width downto 0);
    pstprc_num_en       : in  std_logic;
    Pstprc_num          : in  std_logic_vector(3 downto 0);
    pstprc_fifo_wren    : out std_logic;
    ---------------------------------------------------------------------------
    Estmr_A_eight : in std_logic_vector(31 downto 0);
    Estmr_B_eight : in std_logic_vector(31 downto 0);
    Estmr_C_eight : in std_logic_vector(63 downto 0);
    Estmr_num_en : in std_logic;
    Estmr_num : in std_logic_vector(3 downto 0);
    Estmr_sync_en : in std_logic;
    clk_Estmr :in std_logic;            --clk250M
    clk_Oserdes : in std_logic;          --clk500M
    Estmr_OQ : out std_logic            --Oserdes output


   -- Pstprc_dps_en : in std_logic
    );
end Dmod_Seg;

architecture Behavioral of Dmod_Seg is
  signal q_data                  : std_logic_vector(63 downto 0);
  signal i_data                  : std_logic_vector(63 downto 0);
  signal Pstprc_RAMQ_doutb       : std_logic_vector(63 downto 0);
  signal Pstprc_RAMI_doutb       : std_logic_vector(63 downto 0);
  signal Pstprc_RAMq_rden        : std_logic;
  signal Pstprc_RAMq_rden_d      : std_logic;
  signal Pstprc_en               : std_logic;
  signal Pstprc_RAMq_rden_stp    : std_logic;
--  signal Pstprc_RAMq_rden_stp_d  : std_logic;
--  signal Pstprc_RAMq_rden_stp_d2 : std_logic;
  signal adder_en                : std_logic;
  signal adder_en_d              : std_logic;
  signal adder_en_d2             : std_logic;
  signal Pstprc_en_d             : std_logic;
  signal Pstprc_add_stp          : std_logic;
  signal ini_pstprc_RAMx_addra   : std_logic_vector(12 downto 0);
  signal ini_pstprc_RAMx_addrb   : std_logic_vector(11 downto 0);
  signal Pstprc_RAMx_rden_ln     : std_logic_vector(11 downto 0);
  signal RECV_CNT     : std_logic_vector(31 downto 0);
  attribute KEEP : string;
attribute KEEP of RECV_CNT: signal is "TRUE";
--  signal Pstprc_fifo_din    : std_logic_vector(63 downto 0);
  signal Pstprc_finish_seq  : std_logic_vector(pstprc_ch_num-1 downto 0);
  signal Pstprc_add_stp_seq : std_logic_vector(pstprc_ch_num-1 downto 0);
--  signal pstprc_rs          : std_logic;
--  signal Pstprc_fifo_pempty : std_logic;
--  signal Pstprc_fifo_valid  : std_logic;
  type Pstprc_lnstart_array is array (pstprc_ch_num-1 downto 0) of std_logic_vector(14 downto 0);
  signal dds_data_len       : Pstprc_lnstart_array;
  signal dds_data_start     : Pstprc_lnstart_array;
  type Pstprc_DPS_array is array (pstprc_ch_num-1 downto 0) of std_logic_vector(dds_phase_width downto 0);
  signal Pstprc_DPS         : Pstprc_DPS_array;
  type Pstprc_DATA_array is array (pstprc_ch_num-1 downto 0) of std_logic_vector(31 downto 0);
  signal Pstprc_Qdata       : Pstprc_DATA_array;
  signal Pstprc_Idata       : Pstprc_DATA_array;
  signal IQ_seq_cnt         : std_logic_vector(3 downto 0);
  type Pstprc_IQ_array is array (pstprc_ch_num-1 downto 0) of std_logic_vector(63 downto 0);
  signal pstprc_IQ          : Pstprc_IQ_array;
  signal pstprc_num_frs     : std_logic_vector(pstprc_ch_num-1 downto 0);

  type Estmr_AB is array (7 downto 0) of std_logic_vector(31 downto 0);
  type Estmr_CC is array (7 downto 0) of std_logic_vector(63 downto 0);
  type Estmr_state is array (7 downto 0) of std_logic_vector(1 downto 0);
  signal stat_rdy : std_logic_vector(7 downto 0);
  signal Estmr_A : Estmr_AB;
  signal Estmr_B : Estmr_AB;
  signal Estmr_C : Estmr_CC;
  signal state : Estmr_state;
  signal Estmr_FSM_dout : std_logic_vector(3 downto 0);
  signal pstprc_IQ_seq_o_int : std_logic_vector(63 downto 0);
  signal Pstprc_add_stp_d : std_logic;
  signal Pstprc_add_stp_sig : std_logic;
  
  component Win_RAM_top
    port(
      posedge_sample_trig   : in     std_logic;
      rst_data_proc_n            : in     std_logic;
      rst_adc_n            : in     std_logic;
      cmd_smpl_depth        : in     std_logic_vector(15 downto 0);
      Pstprc_RAMq_dina      : in     std_logic_vector(31 downto 0);
      Pstprc_RAMq_clka      : in     std_logic;
      Pstprc_RAMq_clkb      : in     std_logic;
      Pstprc_RAMI_dina      : in     std_logic_vector(31 downto 0);
      Pstprc_RAMi_clka      : in     std_logic;
      Pstprc_RAMi_clkb      : in     std_logic;
      -- demoWinln            : in     std_logic_vector(14 downto 0);
      -- demoWinstart         : in     std_logic_vector(14 downto 0);
      Pstprc_RAMq_doutb     : out    std_logic_vector(63 downto 0);
      Pstprc_RAMI_doutb     : out    std_logic_vector(63 downto 0);
      Pstprc_RAMq_rden      : buffer std_logic;
      Pstprc_RAMq_rden_stp  : out    std_logic;
      ini_pstprc_RAMx_addra : in     std_logic_vector(12 downto 0);
      ini_pstprc_RAMx_addrb : in     std_logic_vector(11 downto 0);
      Pstprc_RAMx_rden_ln   : in     std_logic_vector(11 downto 0)
      );
  end component;


  component post_process
    port(
      clk                  : in  std_logic;
      rst_n                : in  std_logic;
      Q_data               : in  std_logic_vector(63 downto 0);
      I_data               : in  std_logic_vector(63 downto 0);
      DDS_phase_shift      : in  std_logic_vector (dds_phase_width downto 0);
      -- Pstprc_dps_en : in std_logic;
      Pstprc_en            : in  std_logic;
      Pstprc_RAMx_rden_stp : in  std_logic;
      Pstprc_finish        : out std_logic;
      Pstprc_Qdata         : out std_logic_vector(31 downto 0);
      Pstprc_Idata         : out std_logic_vector(31 downto 0);
      Pstprc_add_stp       : out std_logic;
      dds_data_start       : in  std_logic_vector(14 downto 0);
      dds_data_len         : in  std_logic_vector(14 downto 0);
      Pstprc_num_frs       : in  std_logic;
      cmd_smpl_depth       : in  std_logic_vector(15 downto 0)
     -- Pstprc_RAMx_rden_ln : in std_logic_vector(11 downto 0)
      );
  end component;

  component Estimator
    port(
      clk            : in  std_logic;
      rst_n          : in  std_logic;
      A              : in  std_logic_vector(31 downto 0);
      B              : in  std_logic_vector(31 downto 0);
      C              : in  std_logic_vector(63 downto 0);
      en             : in  std_logic;
      I              : in  std_logic_vector(31 downto 0);
      Q              : in  std_logic_vector(31 downto 0);
      Pstprc_add_stp : in  std_logic;
      state          : out std_logic_vector(1 downto 0);
      stat_rdy       : out std_logic
      );
  end component;

  	COMPONENT Sync_data_FSM
	PORT(
		clk : IN std_logic;
		rst_n : IN std_logic;
		stat_rdy : IN std_logic;
		sync_en : IN std_logic;
                state0 : IN std_logic_vector(1 downto 0);
		state1 : IN std_logic_vector(1 downto 0);
		state2 : IN std_logic_vector(1 downto 0);
		state3 : IN std_logic_vector(1 downto 0);
		state4 : IN std_logic_vector(1 downto 0);
		state5 : IN std_logic_vector(1 downto 0);
		state6 : IN std_logic_vector(1 downto 0);
		state7 : IN std_logic_vector(1 downto 0);
		dout : OUT std_logic_vector(3 downto 0)
		);
	END COMPONENT;

  	COMPONENT Oserdese
	PORT(
		rst_n : IN std_logic;
		clk : IN std_logic;
		clkdiv : IN std_logic;
		D1 : IN std_logic;
		D2 : IN std_logic;
		D3 : IN std_logic;
		D4 : IN std_logic;          
		OQ : OUT std_logic
		);
	END COMPONENT;
-----------------------------------------------------------------------------
begin
  -- ini_pstprc_RAMx_addra <= demoWinstart(14 downto 2);  --15bit width for the
  --BRAM address
  ini_pstprc_RAMx_addra <= "0"&x"001";       --rdy='1' from addra =1 and begin
                                             --post processing
  -- ini_pstprc_RAMx_addrb <= demoWinstart(14 downto 3);
  ini_pstprc_RAMx_addrb <= (others => '0');  --read data from the beginning
  -- dds_data_start        <= demoWinstart;
  -- dds_data_len          <= demoWinln;

  Inst_Win_RAM_top : Win_RAM_top port map(
    posedge_sample_trig   => posedge_sample_trig,
    rst_data_proc_n            => rst_data_proc_n,
    rst_adc_n            => rst_adc_n,
    cmd_smpl_depth        => cmd_smpl_depth,
    Pstprc_RAMQ_dina      => Pstprc_RAMQ_dina,
    Pstprc_RAMQ_clka      => Pstprc_RAMQ_clka,
    Pstprc_RAMQ_clkb      => Pstprc_RAMQ_clkb,
    Pstprc_RAMQ_doutb     => Pstprc_RAMQ_doutb,
    Pstprc_RAMq_rden      => Pstprc_RAMq_rden,
    Pstprc_RAMI_clka      => Pstprc_RAMI_clka,
    Pstprc_RAMI_clkb      => Pstprc_RAMI_clkb,
    Pstprc_RAMI_dina      => Pstprc_RAMI_dina,
    Pstprc_RAMI_doutb     => Pstprc_RAMI_doutb,
    -- demoWinln            => demoWinln,
    -- demoWinstart         => demoWinstart,
    Pstprc_RAMq_rden_stp  => Pstprc_RAMq_rden_stp,
    ini_pstprc_RAMx_addra => ini_pstprc_RAMx_addra,
    ini_pstprc_RAMx_addrb => ini_pstprc_RAMx_addrb,
    Pstprc_RAMx_rden_ln   => Pstprc_RAMx_rden_ln
    );
	 

-------------------------------------------------------------------------------
 Pstprc_finish  <= Pstprc_finish_seq(0);  -- pstprc_finish_seq(pstprc_ch_num-1 downto 0) turn '1'                                        -- at the same time
 pstprc_add_stp <= Pstprc_add_stp_seq(0);

-------------------------------------------------------------------------------
  Post_process_insts : for i in 0 to pstprc_ch_num-1 generate
-------------------------------------------------------------------------------
-- purpose: to select the channel number and transfer the command when the signal pstprc_num_en comes
-- type   : sequential
-- inputs : clk, rst_data_proc_n
-- outputs: 
    pstprc_num_select_ps : process (clk, rst_data_proc_n) is
    begin  -- process pstprc_num_select_ps
      if rst_data_proc_n = '0' then                -- asynchronous reset (active low)
        Pstprc_dps(i) <= '0'&x"150000";  --default '0' reprensents positive
        dds_data_start(i) <= "000"&x"004";
        dds_data_len(i)   <= "000"&x"109";
      elsif clk'event and clk = '1' then  -- rising clock edge
        if i = pstprc_num and pstprc_num_en = '1' then
          Pstprc_dps(i)     <= Pstprc_DPS_twelve;
          dds_data_len(i)   <= demoWinln_twelve;
          dds_data_start(i) <= demoWinstart_twelve;
        else
          Pstprc_dps(i)     <= Pstprc_dps(i);
          dds_data_start(i) <= dds_data_start(i);
          dds_data_len(i)   <= dds_data_len(i);
        end if;
      end if;
    end process pstprc_num_select_ps;

    pstprc_num_frs_ps : process (clk, rst_data_proc_n) is  --用来trig载入dds数据
    begin  -- process pstprc_num_frs_ps
      if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
        pstprc_num_frs(i) <= '0';
      elsif clk'event and clk = '1' then  -- rising clock edge
        if i = Pstprc_num and Pstprc_num_en = '1' then
          Pstprc_num_frs(i) <= '1';
        else
          Pstprc_num_frs(i) <= '0';
        end if;
      end if;
    end process pstprc_num_frs_ps;

    rs_combine_ps : process (clk, rst_data_proc_n) is
    begin  -- process rs_combine_ps
      if rst_data_proc_n = '0' then               -- asynchronous reset (active low)
        Pstprc_IQ(i) <= (others => '0');
      elsif clk'event and clk = '1' then                  -- rising clock edge
        Pstprc_IQ(i) <= Pstprc_Idata(i)&Pstprc_Qdata(i);  --mark 1 delay
      end if;
    end process rs_combine_ps;  -- Pstprc_IQ<=Pstprc_Idata&Pstprc_Qdata;


    Inst_Win_post_process : post_process port map(
      clk                  => clk,
      Q_data               => Q_data,
      I_data               => I_data,
      DDS_phase_shift      => Pstprc_DPS(i),
      -- Pstprc_dps_en => Pstprc_dps_en,
      rst_n                => rst_data_proc_n,
      Pstprc_en            => Pstprc_en,  --for debugging the timing error
      pstprc_num_frs       => pstprc_num_frs(i),
      Pstprc_RAMx_rden_stp => Pstprc_RAMq_rden_stp,
      Pstprc_finish        => Pstprc_finish_seq(i),
      Pstprc_Idata         => Pstprc_Idata(i),
      Pstprc_Qdata         => Pstprc_Qdata(i),
      Pstprc_add_stp       => Pstprc_add_stp_seq(i),
      dds_data_start       => dds_data_start(i),
      dds_data_len         => dds_data_len(i),
      cmd_smpl_depth       => cmd_smpl_depth
      );

    Pstprc_add_stp_d_ps: process (clk, rst_data_proc_n) is
    begin  -- process Pstprc_add_stp_d_ps
      if rst_data_proc_n = '0' then               -- asynchronous reset (active low)
        Pstprc_add_stp_d<='0';
      elsif clk'event and clk = '1' then  -- rising clock edge
        Pstprc_add_stp_d<=Pstprc_add_stp;
      end if;
    end process Pstprc_add_stp_d_ps;    --for extension of the signal to next module

-------------------------------------------------------------------------------
  end generate Post_process_insts;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
  Estimator_gs : for i in 0 to 7 generate
    -- purpose: 将上位机下传的信号赋值给指定通道
    -- type   : sequential
    -- inputs : clk, rst_data_proc_n
    -- outputs: 
    Estmr_args_trans_ps : process (clk, rst_data_proc_n) is
    begin  -- process Estmr_args_trans_ps
      if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
        Estmr_A(i) <= (others => '0');
        Estmr_B(i) <= (others => '0');  --default 
        Estmr_C(i) <= (others => '0');
      elsif clk'event and clk = '1' then  -- rising clock edge
        if Estmr_num = i and Estmr_num_en = '1' then
          Estmr_A(i) <= Estmr_A_eight;
          Estmr_B(i) <= Estmr_B_eight;
          Estmr_C(i) <= Estmr_C_eight;
        else
          Estmr_A(i) <= Estmr_A(i);
          Estmr_B(i) <= Estmr_B(i);
          Estmr_C(i) <= Estmr_C(i);
        end if;
      end if;
    end process Estmr_args_trans_ps;
	 
	 Pstprc_add_stp_sig <= Pstprc_add_stp or Pstprc_add_stp_d;
    Inst_Estimator : Estimator port map(
      clk            => clk_Estmr,        --250MHz clock
      rst_n          => rst_feedback_n,
      A              => Estmr_A(i),
      B              => Estmr_B(i),
      C              => Estmr_C(i),
      en             => '0',
      I              => pstprc_Idata(i),
      Q              => pstprc_Qdata(i),
      Pstprc_add_stp => Pstprc_add_stp_sig,
      state          => state(i),
      stat_rdy       => stat_rdy(i)
      );
    
  end generate Estimator_gs;
-----------------------------------------------------------------------------
	Inst_Sync_data_FSM: Sync_data_FSM PORT MAP(
		clk => clk_Estmr,
		rst_n => rst_feedback_n,
		stat_rdy => stat_rdy(0),        --至少要从第0通道开始使用
		sync_en => Estmr_sync_en,
                state0 => state(0),
		state1 => state(1),
		state2 => state(2),
		state3 =>  state(3),
		state4 =>  state(4),
		state5 =>  state(5),
		state6 =>  state(6),
		state7 =>  state(7),
		dout => Estmr_FSM_dout
        );
-----------------------------------------------------------------------------
  	Inst_Oserdese: Oserdese PORT MAP(
		rst_n => rst_feedback_n,
		clk => clk_Oserdes,     --500
		clkdiv => clk_Estmr,    --250
		D1 => Estmr_FSM_dout(0),
		D2 => Estmr_FSM_dout(1),
		D3 => Estmr_FSM_dout(2),
		D4 => Estmr_FSM_dout(3),                 --详情见设计文档,为了配合林金，修改了顺序。
		OQ => Estmr_OQ
	);
-----------------------------------------------------------------------------
  Pstprc_RAMx_rden_ln_ps : process (clk, rst_data_proc_n) is
  begin  -- process   Pstprc_RAMx_rden_ln_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      Pstprc_RAMx_rden_ln <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      Pstprc_RAMx_rden_ln <= cmd_smpl_depth(14 downto 3);
    end if;
  end process Pstprc_RAMx_rden_ln_ps;

-----------------------------------------------------------------------------
process (clk, rst_data_proc_n) is
  begin  -- process fifo_wren_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      RECV_CNT <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if Pstprc_add_stp_d = '1' then
        RECV_CNT <= RECV_CNT + '1';
      end if;
    end if;
  end process;
-------------------------------------------------------------------------------
process (clk, rst_data_proc_n) is
  begin  -- process fifo_wren_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      pstprc_IQ_seq_o_int <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      if(cmd_smpl_en = '1') then
			pstprc_IQ_seq_o_int <= (others => '0');
		elsif IQ_seq_cnt = upload_freq_cnt then
        pstprc_IQ_seq_o_int <= pstprc_IQ_seq_o_int;
      else
        pstprc_IQ_seq_o_int(63 downto 32) <= pstprc_IQ_seq_o_int(63 downto 32) + '1';
        pstprc_IQ_seq_o_int(31 downto 0) <= pstprc_IQ_seq_o_int(31 downto 0) + '1';
      end if;
    end if;
  end process;
----------------------------

  IQ_sequence_ps : process (clk, rst_data_proc_n) is
  begin  -- process IQ_sequence_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      pstprc_IQ_seq_o <= (others => '1');
    elsif clk'event and clk = '1' then  -- rising clock edge
		if is_counter = '1' then
			pstprc_IQ_seq_o <= pstprc_IQ_seq_o_int;
		else
			case IQ_seq_cnt is
			  when x"0" =>
				 pstprc_IQ_seq_o <= pstprc_IQ(0);
			  when x"1" =>
				 pstprc_IQ_seq_o <= pstprc_IQ(1);
			  when x"2" =>
				 pstprc_IQ_seq_o <= pstprc_IQ(2);
			  when x"3"=>
				 pstprc_IQ_seq_o <= pstprc_IQ(3);
			  when x"4" =>
				 pstprc_IQ_seq_o <= pstprc_IQ(4);
			  when x"5" =>
				 pstprc_IQ_seq_o <= pstprc_IQ(5);
			  when x"6" =>
				 pstprc_IQ_seq_o <= pstprc_IQ(6);
			  when x"7"=>
				 pstprc_IQ_seq_o <= pstprc_IQ(7);
			  when x"8" =>
				 pstprc_IQ_seq_o <= (others => '0');--pstprc_IQ(8);
			  when x"9" =>
				 pstprc_IQ_seq_o <= (others => '0');--pstprc_IQ(9);
			  when x"a" =>
				 pstprc_IQ_seq_o <= (others => '0');--pstprc_IQ(10);
			  when x"b"=>
				 pstprc_IQ_seq_o <= (others => '0');--pstprc_IQ(11);
			  when others => pstprc_IQ_seq_o <= (others => '0');
			end case;
		end if;
    end if;
  end process IQ_sequence_ps;

  IQ_seq_cnt_ps : process (clk, rst_data_proc_n) is
  begin  -- process IQ_seq_cnt_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      IQ_seq_cnt <= upload_freq_cnt;
    elsif clk'event and clk = '1' then  -- rising clock edge
      if Pstprc_add_stp = '1' then
        IQ_seq_cnt <= (others => '0');
      elsif IQ_seq_cnt < upload_freq_cnt then
        IQ_seq_cnt <= IQ_seq_cnt+1;
      else
        IQ_seq_cnt <= upload_freq_cnt;
      end if;
    end if;
  end process IQ_seq_cnt_ps;

  fifo_wren_ps : process (clk, rst_data_proc_n) is
  begin  -- process fifo_wren_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      pstprc_fifo_wren <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      if IQ_seq_cnt = upload_freq_cnt then
        pstprc_fifo_wren <= '0';
      else
        pstprc_fifo_wren <= '1';
      end if;
    end if;
  end process fifo_wren_ps;
-----------------------------------------------------------------------------

  Pstprc_RAMx_rden_d_ps : process (clk, rst_data_proc_n) is
  begin  -- process Pstprc_RAMx_rden_d_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      Pstprc_RAMq_rden_d <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      Pstprc_RAMq_rden_d <= Pstprc_RAMq_rden;
    end if;
  end process Pstprc_RAMx_rden_d_ps;

  Adder_en_d_ps : process (clk, rst_data_proc_n) is
  begin  -- process Pstprc_en_d_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      Adder_en_d  <= '0';
      Adder_en_d2 <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      Adder_en_d  <= Adder_en;
      Adder_en_d2 <= Adder_en_d;
    end if;
  end process Adder_en_d_ps;

-- Pstprc_RAMq_rden_stp_d_ps : process (clk, rst_data_proc_n) is
-- begin  -- process Pstprc_RAMq_rden_stp_d    
--   if clk'event and clk = '1' then     -- rising clock edge
--     Pstprc_RAMq_rden_stp_d  <= Pstprc_RAMq_rden_stp;
--     Pstprc_RAMq_rden_stp_d2 <= Pstprc_RAMq_rden_stp_d;
--   end if;
-- end process Pstprc_RAMq_rden_stp_d_ps;

-- Pstprc_add_stp_ps : process (clk, rst_data_proc_n) is
-- begin  -- process Pstprc_add_stp_ps
--   if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
--     Pstprc_add_stp <= '0';
--   elsif clk'event and clk = '1' then  -- rising clock edge
--     Pstprc_add_stp <= Pstprc_RAMq_rden_stp_d2;
--   end if;
-- end process Pstprc_add_stp_ps;

  Adder_en_ps : process (clk, rst_data_proc_n) is
  begin  -- process Adder_en_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      Adder_en <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      Adder_en <= Pstprc_en;
    end if;
  end process Adder_en_ps;

  Pstprc_en_d_ps : process (clk, rst_data_proc_n) is
  begin  -- process Pstprc_en_d_ps
    if rst_data_proc_n = '0' then                 -- asynchronous reset (active low)
      Pstprc_en_d <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      Pstprc_en_d <= Pstprc_en;
    end if;
  end process Pstprc_en_d_ps;

  Pstprc_en <= Pstprc_RAMq_rden_d or Pstprc_RAMq_rden;
-------------------------------------------------------------------------------
  Q_data    <= Pstprc_RAMQ_doutb;
  I_data    <= Pstprc_RAMI_doutb;

end Behavioral;

