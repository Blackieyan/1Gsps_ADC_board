-- TestBench Template 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity inst_Dmod_Seg_TB is
end inst_Dmod_Seg_TB;

architecture behavior of inst_Dmod_Seg_TB is

  component Dmod_Seg is
    generic (
      mult_accum_s_width : integer := 32;
      dds_phase_width    : integer := 24;
      pstprc_ch_num      : integer := 12);
    port (
      clk                 : in  std_logic;
      posedge_sample_trig : in  std_logic;
      rst_n               : in  std_logic;
      cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
      Pstprc_RAMQ_dina    : in  std_logic_vector(31 downto 0);
      Pstprc_RAMQ_clka    : in  std_logic;
      Pstprc_RAMQ_clkb    : in  std_logic;
      Pstprc_RAMI_dina    : in  std_logic_vector(31 downto 0);
      Pstprc_RAMI_clka    : in  std_logic;
      Pstprc_RAMI_clkb    : in  std_logic;
      demoWinln_twelve    : in  std_logic_vector(14 downto 0);
      demoWinstart_twelve : in  std_logic_vector(14 downto 0);
      pstprc_IQ_seq_o     : out std_logic_vector(63 downto 0);
      Pstprc_finish       : out std_logic;
      Pstprc_DPS_twelve   : in  std_logic_vector(dds_phase_width downto 0);
      pstprc_num_en       : in  std_logic;
      Pstprc_num          : in  std_logic_vector(3 downto 0);
      pstprc_fifo_wren    : out std_logic;
      Estmr_A_eight       : in  std_logic_vector(31 downto 0);
      Estmr_B_eight       : in  std_logic_vector(31 downto 0);
      Estmr_C_eight       : in  std_logic_vector(64 downto 0);
      Estmr_num_en        : in  std_logic;
      Estmr_num           : in  std_logic_vector(3 downto 0);
      Estmr_sync_en       : in  std_logic;
      clk_Estmr           : in  std_logic;
      clk_Oserdes         : in  std_logic;
      Estmr_OQ            : out std_logic);
  end component Dmod_Seg;

  -- constant mult_accum_s_width : integer := 32;
  -- constant add_period_cnt : integer := 8;
  signal clk                       : std_logic;
  signal posedge_sample_trig       : std_logic;
  signal rst_n                     : std_logic;
  signal cmd_smpl_depth            : std_logic_vector(15 downto 0) := x"07d0";
  signal Pstprc_RAMQ_dina          : std_logic_vector(31 downto 0);
  signal Pstprc_RAMQ_clka          : std_logic;
  signal Pstprc_RAMQ_clkb          : std_logic;
  signal Pstprc_RAMI_dina          : std_logic_vector(31 downto 0);
  signal Pstprc_RAMI_clka          : std_logic;
  signal Pstprc_RAMI_clkb          : std_logic;
  signal demoWinln_twelve          : std_logic_vector(14 downto 0) := "000"&x"5DC";
  signal demoWinstart_twelve       : std_logic_vector(14 downto 0) := "000"&x"004";
  signal pstprc_IQ_seq_o           : std_logic_vector(63 downto 0);
  signal Pstprc_finish             : std_logic;
  signal Pstprc_DPS_twelve         : std_logic_vector(24 downto 0);
  signal pstprc_num_en             : std_logic;
  signal Pstprc_num                : std_logic_vector(3 downto 0);
  signal pstprc_fifo_wren          : std_logic;
  signal Estmr_A_eight             : std_logic_vector(31 downto 0);
  signal Estmr_B_eight             : std_logic_vector(31 downto 0);
  signal Estmr_C_eight             : std_logic_vector(64 downto 0);
  signal Estmr_num_en              : std_logic;
  signal Estmr_num                 : std_logic_vector(3 downto 0);
  signal Estmr_sync_en             : std_logic;
  signal clk_Estmr                 : std_logic;
  signal clk_Oserdes               : std_logic;
  signal Estmr_OQ                  : std_logic;
  constant clk_period              : time                          := 8 ns;
  constant Pstprc_RAMQ_clka_period : time                          := 4 ns;
  constant clk_Estmr_period        : time                          := 4 ns;
  constant clk_Oserdes_period      : time                          := 2 ns;
  constant mult_accum_s_width : integer := 32;
  constant dds_phase_width    : integer := 24;
  constant pstprc_ch_num      : integer := 12;
begin

  Dmod_Seg_1 : entity work.Dmod_Seg
    generic map (
      mult_accum_s_width => mult_accum_s_width,
      dds_phase_width    => dds_phase_width,
      pstprc_ch_num      => pstprc_ch_num)
    port map (
      clk                 => clk,
      posedge_sample_trig => posedge_sample_trig,
      rst_n               => rst_n,
      cmd_smpl_depth      => cmd_smpl_depth,
      Pstprc_RAMQ_dina    => Pstprc_RAMQ_dina,
      Pstprc_RAMQ_clka    => Pstprc_RAMQ_clka,
      Pstprc_RAMQ_clkb    => Pstprc_RAMQ_clkb,
      Pstprc_RAMI_dina    => Pstprc_RAMI_dina,
      Pstprc_RAMI_clka    => Pstprc_RAMI_clka,
      Pstprc_RAMI_clkb    => Pstprc_RAMI_clkb,
      demoWinln_twelve    => demoWinln_twelve,
      demoWinstart_twelve => demoWinstart_twelve,
      pstprc_IQ_seq_o     => pstprc_IQ_seq_o,
      Pstprc_finish       => Pstprc_finish,
      Pstprc_DPS_twelve   => Pstprc_DPS_twelve,
      pstprc_num_en       => pstprc_num_en,
      Pstprc_num          => Pstprc_num,
      pstprc_fifo_wren    => pstprc_fifo_wren,
      Estmr_A_eight       => Estmr_A_eight,
      Estmr_B_eight       => Estmr_B_eight,
      Estmr_C_eight       => Estmr_C_eight,
      Estmr_num_en        => Estmr_num_en,
      Estmr_num           => Estmr_num,
      Estmr_sync_en       => Estmr_sync_en,
      clk_Estmr           => clk_Estmr,
      clk_Oserdes         => clk_Oserdes,
      Estmr_OQ            => Estmr_OQ);

  sim_Data_I : process (PSTPRC_RAMQ_CLKA, rst_n) is
  begin  -- process sim_DOIA
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Pstprc_RAMI_dina <= (others => '0');
    elsif PSTPRC_RAMQ_CLKA'event and PSTPRC_RAMQ_CLKA = '1' then  -- rising clock edge
      Pstprc_RAMI_dina <= Pstprc_RAMI_dina+2;
    -- ADC_DOIA_p<=x"7f";
    end if;
  end process sim_data_I;

  sim_Data_Q : process (PSTPRC_RAMQ_CLKA, rst_n) is
  begin  -- process sim_DOIA
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Pstprc_RAMQ_dina <= (others => '0');
    elsif PSTPRC_RAMQ_CLKA'event and PSTPRC_RAMQ_CLKA = '1' then  -- rising clock edge
      Pstprc_RAMQ_dina <= Pstprc_RAMQ_dina+1;
    -- ADC_DOIA_p<=x"7f";
    end if;
  end process sim_data_Q;

  clk_process : process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;
  Pstprc_RAMQ_clkb <= clk;
  Pstprc_RAMI_clkb <= clk;

  Pstprc_RAMQ_clka_process : process
  begin
    Pstprc_RAMQ_clka <= '0';
    wait for Pstprc_RAMQ_clka_period/2;
    Pstprc_RAMQ_clka <= '1';
    wait for Pstprc_RAMQ_clka_period/2;
  end process;
  Pstprc_RAMI_clka <= Pstprc_RAMQ_clka;

    clk_Estmr_process : process
  begin
    clk_Estmr <= '0';
    wait for clk_Estmr_period/2;
    clk_Estmr <= '1';
    wait for clk_Estmr_period/2;
  end process;

  clk_Oserdes_process : process
  begin
    clk_Oserdes <= '0';
    wait for clk_Oserdes_period/2;
    clk_Oserdes <= '1';
    wait for clk_Oserdes_period/2;
  end process;
  --  Test Bench Statements
  tb : process
  begin
    rst_n               <= '0';
    wait for clk_period *125;  -- wait until global set/reset completes
    rst_n               <= '1';
    wait for clk_period *25;
    Pstprc_DPS_twelve   <= "0"&x"150000";
    wait for clk_period *1;
    Pstprc_num          <= "0001";
    Pstprc_num_en       <= '1';
    Estmr_sync_en<='1';
    Estmr_A_eight<=x"11111111";
    Estmr_B_eight<=x"00000001";
    Estmr_C_eight<="0"&x"0000000100000000";
    wait for clk_period *1;
    Estmr_num<="0001";
    Estmr_num_en<='1';
    wait for 10 ns;
    Pstprc_num_en       <= '0';
    -- Add user defined stimulus here
    wait for clk_period *2600;
    posedge_sample_trig <= '1';
    wait for clk_period *1;
    posedge_sample_trig <= '0';
    wait for clk_period *2600;
    posedge_sample_trig <= '1';
    wait for clk_period *1;
    posedge_sample_trig <= '0';

    wait;                               -- will wait forever
  end process tb;
  --  End Test Bench 

end;
