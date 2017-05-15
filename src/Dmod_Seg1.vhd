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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Dmod_Seg is
  generic (
    mult_accum_s_width : integer := 32
    );
  port(
    clk                 : in std_logic;
    posedge_sample_trig : in std_logic;
    rst_n               : in std_logic;
    cmd_smpl_depth      : in std_logic_vector(15 downto 0);
    Pstprc_RAMQ_dina    : in std_logic_vector(31 downto 0);
    Pstprc_RAMQ_clka    : in std_logic;
    Pstprc_RAMQ_clkb    : in std_logic;
    ---------------------------------------------------------------------------
    Pstprc_RAMI_dina    : in std_logic_vector(31 downto 0);
    Pstprc_RAMI_clka    : in std_logic;
    Pstprc_RAMI_clkb    : in std_logic;
    ---------------------------------------------------------------------------
    demoWinln           : in std_logic_vector(14 downto 0);
    demoWinstart        : in std_logic_vector(14 downto 0);
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    Pstprc_IQ : out std_logic_vector(2*mult_accum_s_width-1 downto 0);
    Pstprc_finish : out std_logic;
    -- Pstprc_fifo_rden :  in std_logic;
    -- Pstprc_fifo_rs : out std_logic_vector(7 downto 0);
    -- Pstprc_fifo_rdclk : in std_logic;   -- same with the ethernet txclk
    Pstprc_DPS          : in std_logic_vector(15 downto 0)
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
  signal Pstprc_RAMq_rden_stp_d  : std_logic;
  signal Pstprc_RAMq_rden_stp_d2 : std_logic;
  signal adder_en                : std_logic;
  signal adder_en_d              : std_logic;
  signal adder_en_d2             : std_logic;
  signal Pstprc_add_stp          : std_logic;
  signal ini_pstprc_RAMx_addra   : std_logic_vector(12 downto 0);
  signal ini_pstprc_RAMx_addrb   : std_logic_vector(11 downto 0);
  signal Pstprc_RAMx_rden_ln     : std_logic_vector(11 downto 0);
  -- signal Pstprc_RAMQ_doutb : std_logic_vector(31 downto 0);
  -- signal Pstprc_RAMI_doutb : std_logic_vector(31 downto 0);
  signal Pstprc_Qdata            : std_logic_vector(mult_accum_s_width-1 downto 0);
  signal Pstprc_Idata            : std_logic_vector(mult_accum_s_width-1 downto 0);

  signal Pstprc_fifo_din : std_logic_vector(63 downto 0);
  -- signal Pstprc_finish : std_logic;
  signal Pstprc_fifo_wren : std_logic;
  signal pstprc_rs : std_logic;
  signal Pstprc_fifo_pempty : std_logic;
  signal Pstprc_fifo_valid : std_logic;
  -- signal Pstprc_IQ : std_logic_vector(2*mult_accum_s_width-1 downto 0);
  
  component Win_RAM_top
    port(
      posedge_sample_trig   : in     std_logic;
      rst_n                 : in     std_logic;
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
      DDS_phase_shift      : in  std_logic_vector (15 downto 0);
      -- Pstprc_dps_en : in std_logic;
      Pstprc_en            : in  std_logic;
      Pstprc_RAMx_rden_stp : in  std_logic;
      Pstprc_finish : out std_logic;
      Pstprc_Qdata : out std_logic_vector(mult_accum_s_width-1 downto 0);
      Pstprc_Idata : out std_logic_vector(mult_accum_s_width-1 downto 0)
      -- Pstprc_RAMx_rden_ln : in std_logic_vector(11 downto 0)
      );
  end component;

  -- component Pstprc_fifo_top
  --   port(
  --     rst_n              : in  std_logic;
  --     Pstprc_fifo_wr_clk : in  std_logic;
  --     Pstprc_fifo_rd_clk : in  std_logic;
  --     Pstprc_fifo_din    : in  std_logic_vector(63 downto 0);
  --     Pstprc_fifo_wren   : in  std_logic;
  --     Pstprc_fifo_rden   : in  std_logic;
  --     prog_empty_thresh  : in  std_logic_vector(6 downto 0);
  --     Pstprc_fifo_dout   : out std_logic_vector(7 downto 0);
  --     Pstprc_fifo_valid  : out std_logic;
  --     Pstprc_fifo_pempty : out std_logic
  --     );
  -- end component;
-----------------------------------------------------------------------------
begin
  ini_pstprc_RAMx_addra <= demoWinstart(14 downto 2);  --15bit width for the
                                                       --BRAM address
  ini_pstprc_RAMx_addrb <= demoWinstart(14 downto 3);


  Inst_Win_RAM_top : Win_RAM_top port map(
    posedge_sample_trig   => posedge_sample_trig,
    rst_n                 => rst_n,
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

  Inst_Win_post_process : post_process port map(
    clk                  => clk,
    Q_data               => Q_data,
    I_data               => I_data,
    DDS_phase_shift      => Pstprc_DPS,
    -- Pstprc_dps_en => Pstprc_dps_en,
    rst_n                => rst_n,
    Pstprc_en            => Pstprc_en,
    Pstprc_RAMx_rden_stp => Pstprc_RAMq_rden_stp,
    Pstprc_finish => Pstprc_finish,
    Pstprc_Idata     => Pstprc_Idata,
    Pstprc_Qdata     => Pstprc_Qdata
    );

  -- Inst_Pstprc_fifo_top : Pstprc_fifo_top port map(
  --   rst_n              => rst_n,
  --   Pstprc_fifo_wr_clk => clk,
  --   Pstprc_fifo_rd_clk => Pstprc_fifo_rdclk,
  --   Pstprc_fifo_din    => Pstprc_IQ,
  --   Pstprc_fifo_wren   => Pstprc_finish,
  --   Pstprc_fifo_rden   => Pstprc_fifo_rden,
  --   prog_empty_thresh  => "0001000",
  --   Pstprc_fifo_dout   => Pstprc_fifo_rs,
  --   Pstprc_fifo_valid  => Pstprc_fifo_valid,
  --   Pstprc_fifo_pempty => Pstprc_fifo_pempty
  --   );
  ----------------------------------------------------------------------------
    Pstprc_RAMx_rden_ln_ps: process (clk, rst_n) is
  begin  -- process   Pstprc_RAMx_rden_ln_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Pstprc_RAMx_rden_ln<=(others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
        Pstprc_RAMx_rden_ln  <= demoWinln(14 downto 3) + 1;
    end if;
  end process Pstprc_RAMx_rden_ln_ps;
  -----------------------------------------------------------------------------
rs_combine_ps: process (clk, rst_n) is
begin  -- process rs_combine_ps
  if rst_n = '0' then                   -- asynchronous reset (active low)
    Pstprc_IQ<=(others => '0');
  elsif clk'event and clk = '1' then    -- rising clock edge
    Pstprc_IQ<=Pstprc_Idata&Pstprc_Qdata;  --mark 1 delay
  end if;
end process rs_combine_ps;

   -- Pstprc_IQ<=Pstprc_Idata&Pstprc_Qdata;
  -----------------------------------------------------------------------------
  Pstprc_RAMx_rden_d_ps : process (clk, rst_n) is
  begin  -- process Pstprc_RAMx_rden_d_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Pstprc_RAMq_rden_d <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      Pstprc_RAMq_rden_d <= Pstprc_RAMq_rden;
    end if;
  end process Pstprc_RAMx_rden_d_ps;

  Pstprc_en_d_ps : process (clk, rst_n) is
  begin  -- process Pstprc_en_d_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Adder_en_d  <= '0';
      Adder_en_d2 <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      Adder_en_d  <= Adder_en;
      Adder_en_d2 <= Adder_en_d;
    end if;
  end process Pstprc_en_d_ps;

  -- Pstprc_RAMq_rden_stp_d_ps : process (clk, rst_n) is
  -- begin  -- process Pstprc_RAMq_rden_stp_d    
  --   if clk'event and clk = '1' then     -- rising clock edge
  --     Pstprc_RAMq_rden_stp_d  <= Pstprc_RAMq_rden_stp;
  --     Pstprc_RAMq_rden_stp_d2 <= Pstprc_RAMq_rden_stp_d;
  --   end if;
  -- end process Pstprc_RAMq_rden_stp_d_ps;

  -- Pstprc_add_stp_ps : process (clk, rst_n) is
  -- begin  -- process Pstprc_add_stp_ps
  --   if rst_n = '0' then                 -- asynchronous reset (active low)
  --     Pstprc_add_stp <= '0';
  --   elsif clk'event and clk = '1' then  -- rising clock edge
  --     Pstprc_add_stp <= Pstprc_RAMq_rden_stp_d2;
  --   end if;
  -- end process Pstprc_add_stp_ps;

  Adder_en_ps : process (clk, rst_n) is
  begin  -- process Adder_en_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Adder_en <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      Adder_en <= Pstprc_en;
    end if;
  end process Adder_en_ps;

  Pstprc_en <= Pstprc_RAMq_rden_d or Pstprc_RAMq_rden;
-------------------------------------------------------------------------------
  Q_data    <= Pstprc_RAMQ_doutb;
  I_data    <= Pstprc_RAMI_doutb;

end Behavioral;

