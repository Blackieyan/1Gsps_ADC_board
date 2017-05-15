----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:39:06 12/13/2016 
-- Design Name: 
-- Module Name:    DDS_top - Behavioral 
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

entity DDS_top is
  port(
    dds_clk         : in  std_logic;
    dds_sclr        : in  std_logic;
    dds_en    : in  std_logic;
    dds_phase_shift : in  std_logic_vector(15 downto 0);
    -- pstprc_dps_en : in std_logic;
    cos_out         : out std_logic_vector(95 downto 0);
    sin_out         : out std_logic_vector(95 downto 0)
    );
end DDS_top;

architecture Behavioral of DDS_top is
  signal dds_reg_select    : std_logic;
  signal dds_ce            : std_logic;
  signal dds_rdy           : std_logic;
  signal dds_rfd           : std_logic;
  signal dds_phase_out     : std_logic_vector(15 downto 0);
  signal dds_phase_shift_d : std_logic_vector(15 downto 0);
  -- signal dps_en_cnt : std_logic_vector(11 downto 0);
  signal dds_ram_wren     : std_logic_vector(0 downto 0);
  signal dds_ram_addra : std_logic_vector(11 downto 0);
  signal dds_ram_addrb : std_logic_vector(8 downto 0);
  signal dds_cos : std_logic_vector(11 downto 0);
  signal dds_sin : std_logic_vector(11 downto 0);
  signal dds_ram_rden : std_logic;
  
  component DDS1
    port (
      reg_select : in  std_logic;
      clk        : in  std_logic;
      sclr       : in  std_logic;
      we         : in  std_logic;
      data       : in  std_logic_vector(15 downto 0);
      rdy        : out std_logic;
      rfd        : out std_logic;
      cosine     : out std_logic_vector(11 downto 0);
      sine       : out std_logic_vector(11 downto 0);
      phase_out  : out std_logic_vector(15 downto 0));
  end component;

  component dds_ram
    port (
      clka  : in  std_logic;
      ena   : in  std_logic;
      wea   : in  std_logic_vector(0 downto 0);
      addra : in  std_logic_vector(11 downto 0);
      dina  : in  std_logic_vector(11 downto 0);
      clkb  : in  std_logic;
      enb : in std_logic;
      addrb : in  std_logic_vector(8 downto 0);
      doutb : out std_logic_vector(95 downto 0)
      );
  end component;

  -- component dds_fifo
  --   port (
  --     rst         : in  std_logic;
  --     wr_clk      : in  std_logic;
  --     rd_clk      : in  std_logic;
  --     din         : in  std_logic_vector(11 downto 0);
  --     wr_en       : in  std_logic;
  --     rd_en       : in  std_logic;
  --     dout        : out std_logic_vector(95 downto 0);
  --     full        : out std_logic;
  --     almost_full : out std_logic;
  --     empty       : out std_logic
  --    -- valid : OUT STD_LOGIC
  --     );
  -- end component;

  signal fifo_cos : std_logic_vector(95 downto 0);
  signal fifo_sin : std_logic_vector(95 downto 0);


begin

  DDS_inst : DDS1
    port map (
      reg_select => '0',
      clk        => dds_clk,
      sclr       => dds_sclr,
      we         => dds_ram_wren(0),
      data       => dds_phase_shift,    --fout = clk*data/2^N
      rdy        => dds_rdy,
      rfd        => dds_rfd,
      cosine     => dds_cos,
      sine       => dds_sin,
      phase_out  => dds_phase_out);

  
  
  sin_ram_inst : dds_ram
    port map (
      clka  => dds_clk,
      ena   => '1',
      wea   => dds_ram_wren,
      addra => dds_ram_addra,
      dina  => dds_sin,
      clkb  => dds_clk,
      enb => dds_ram_rden,
      addrb => dds_ram_addrb,
      doutb => sin_out
      );

  cos_ram_inst : dds_ram
    port map (
      clka  => dds_clk,
      ena   => '1',
      wea   => dds_ram_wren,
      addra => dds_ram_addra,
      dina  => dds_cos,
      clkb  => dds_clk,
      enb => dds_ram_rden,
      addrb => dds_ram_addrb,
      doutb => cos_out
      );

 dds_ram_rden<= dds_en;                 --control by module input signal 
   
  -- sin_fifo_inst : dds_fifo
  --   port map (
  --     rst         => dds_sclr,
  --     wr_clk      => dds_clk,
  --     rd_clk      => dds_clk,
  --     din         => dds_sin,
  --     wr_en       => dds_fifo_wren,
  --     rd_en       => dds_fifo_rden,
  --     dout        => sin_out,
  --     full        => sin_fifo_full,
  --     almost_full => sin_fifo_alfull,
  --     empty       => sin_fifo_empty
  --    -- valid => valid
  --     );

  -- cos_fifo_inst : dds_fifo
  --   port map (
  --     rst         => dds_sclr,
  --     wr_clk      => dds_clk,
  --     rd_clk      => dds_clk,
  --     din         => dds_cos,
  --     wr_en       => dds_fifo_wren,
  --     rd_en       => dds_fifo_rden,
  --     dout        => cos_out,
  --     full        => cos_fifo_full,
  --     almost_full => cos_fifo_alfull,
  --     empty       => cos_fifo_empty
  --    -- valid => valid
  --     );

-- purpose: generate dps_en to prepare the dps data with a ram and control the
-- dds output at the same time
-- type   : sequential
-- inputs : dds_clk, dds_sclr
-- outputs: 
  dds_ram_wren_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_ram_wren_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_wren <= "1";             --write ram after reset and power on
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_phase_shift_d /= dds_phase_shift then
        dds_ram_wren <= "1";
      elsif dds_ram_addra = x"FFA" then     --4090
        dds_ram_wren <= "0";
      end if;
    end if;
  end process dds_ram_wren_ps;

  dds_ram_addra_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_ram_addra_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_addra <= (others => '0');
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_ram_wren = "0" then
        dds_ram_addra <= (others => '0');
      elsif dds_ram_wren = "1" then
        dds_ram_addra <= dds_ram_addra+1;
      end if;
    end if;
  end process dds_ram_addra_ps;  --actually cnt 4091

    dds_ram_addrb_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_dds_ram_addrb_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_addrb <= (others => '0');
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_ram_rden = '0' then
        dds_ram_addrb <= (others => '0');
      elsif dds_ram_rden = '1' then
        dds_ram_addrb <=dds_ram_addrb+1;
      end if;
    end if;
  end process dds_ram_addrb_ps;  --actually cnt 4091
  
  dds_phase_shift_d_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_phase_shift_d_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_phase_shift_d <= (others => '0');
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      dds_phase_shift_d <= dds_phase_shift;
    end if;
  end process dds_phase_shift_d_ps;


end Behavioral;

