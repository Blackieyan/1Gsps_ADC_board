----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:20:15 12/07/2016 
-- Design Name: 
-- Module Name:    RAM_I - Behavioral 
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

entity RAM_I is
  port (
    rst_data_n          : in  std_logic;
    rst_adc_n           : in  std_logic;
    ram_wren            : in  std_logic;
    posedge_sample_trig : in  std_logic;
    cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
    ---------------------------------------------------------------------------
    ram_I_dina          : in  std_logic_vector(31 downto 0);
    ram_I_clka          : in  std_logic;
    ram_I_clkb          : in  std_logic;
    ram_I_rden          : in  std_logic;
    ram_I_doutb         : out std_logic_vector(7 downto 0);
    ram_I_last          : out std_logic;
    ram_I_full_o        : out std_logic
    );
end RAM_I;

architecture Behavioral of RAM_I is
  signal ram_I_addra : std_logic_vector(12 downto 0);
  signal ram_I_addrb : std_logic_vector(14 downto 0);
  signal ram_I_ena   : std_logic;
  signal ram_I_enb   : std_logic;
  signal ram_I_wea   : std_logic_vector(0 downto 0);
  signal ram_I_rstb  : std_logic;
  signal clr_n_ram   : std_logic;
  signal ram_I_full : std_logic;
  
  component ram_data_i
    port (
      clka  : in  std_logic;
      ena   : in  std_logic;
      wea   : in  std_logic_vector(0 downto 0);
      addra : in  std_logic_vector(12 downto 0);
      dina  : in  std_logic_vector(31 downto 0);
      clkb  : in  std_logic;
      rstb  : in  std_logic;
      enb   : in  std_logic;
      addrb : in  std_logic_vector(14 downto 0);
      doutb : out std_logic_vector(7 downto 0)
      );
  end component;

begin

  ram_I_inst : ram_data_i
    port map (
      clka  => ram_I_clka,
      ena   => '1',
      wea   => ram_I_wea,
      addra => ram_I_addra,
      dina  => ram_I_dina,
      clkb  => ram_I_clkb,
      rstb  => ram_I_rstb,
      enb   => '1',
      addrb => ram_I_addrb,
      doutb => ram_I_doutb
      );

  ram_I_enb    <= ram_I_rden;
  ram_I_ena    <= ram_wren and (not ram_I_full);
  ram_I_wea(0) <= ram_wren and (not ram_I_full);
  ram_I_rstb   <= not rst_data_n;
  ram_I_full_o <= ram_I_full;

  ram_I_addra_ps : process (ram_I_clka, rst_adc_n, posedge_sample_trig) is
  begin  -- process addra_ps
    if rst_adc_n = '0' then             -- asynchronous reset (active low)
      ram_I_addra <= (others => '0');
    elsif ram_I_clka'event and ram_I_clka = '1' then      -- rising clock edge
      if posedge_sample_trig = '1' then
        ram_I_addra <= (others => '0');
      elsif ram_wren = '1' then
        if ram_I_addra < cmd_smpl_depth(14 downto 2)then  --cmd_smpl_depth/4
          ram_I_addra <= ram_I_addra+1;
        end if;
      end if;
    end if;
  end process ram_I_addra_ps;

  ram_I_full_ps : process (ram_I_clka, rst_adc_n, posedge_sample_trig) is
  begin  -- process addra_ps
    if rst_adc_n = '0' then             -- asynchronous reset (active low)
      ram_I_full <= '0';
    elsif ram_I_clka'event and ram_I_clka = '1' then      -- rising clock edge
      if posedge_sample_trig = '1' then
        ram_I_full <= '0';
      elsif ram_wren = '1' then
        if ram_I_addra < cmd_smpl_depth(14 downto 2)then  --cmd_smpl_depth/4
          ram_I_full <= '0';
        elsif ram_I_addra >= cmd_smpl_depth(14 downto 2) then
          ram_I_full <= '1';
        end if;
      end if;
    end if;
  end process ram_I_full_ps;

  ram_I_addrb_ps : process (rst_data_n, clr_n_ram) is
  begin  -- process addrb_ps
    if clr_n_ram = '0' then
      ram_I_addrb <= (others => '0');
    elsif rst_data_n'event and rst_data_n = '1' then       -- rising clock edge
      if posedge_sample_trig = '1' then
        ram_I_addrb <= (others => '0');  --edit at 8.25 for a bug
      elsif ram_I_rden = '1' then
        -- if ram_addrb<x"9c37" then
        if ram_I_addrb < cmd_smpl_depth(14 downto 0) then  --edit at 9.5
          ram_I_addrb <= ram_I_addrb+1;
        end if;
      end if;
    end if;
  end process ram_I_addrb_ps;

  ram_I_last_ps : process (rst_data_n, clr_n_ram) is
  begin  -- process addrb_ps
    if clr_n_ram = '0' then
      ram_I_last <= '1';
    elsif rst_data_n'event and rst_data_n = '1' then       -- rising clock edge
      if posedge_sample_trig = '1' then
        ram_I_last <= '0';                                 --edit at 11.9
      elsif ram_I_rden = '1' then
        -- if ram_addrb<x"9c37" then
        if ram_I_addrb < cmd_smpl_depth(14 downto 0) then  --edit at 9.5
          ram_I_last <= '0';
        elsif ram_I_addrb >= cmd_smpl_depth(14 downto 0) then
          ram_I_last <= '1';
        end if;
      end if;
    end if;
  end process ram_I_last_ps;



end Behavioral;

