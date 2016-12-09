----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:28:00 12/07/2016 
-- Design Name: 
-- Module Name:    RAM_Q - Behavioral 
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

entity RAM_Q is
  port(
    ram_wren            : in  std_logic;
    posedge_sample_trig : in  std_logic;
    rst_n               : in  std_logic;
    cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
    ---------------------------------------------------------------------------
    ram_Q_dina          : in  std_logic_vector(31 downto 0);
    ram_Q_clka          : in  std_logic;
    ram_Q_clkb          : in  std_logic;
    ram_Q_rden          : in  std_logic;
    ram_Q_doutb         : out std_logic_vector(7 downto 0);
    ram_Q_last          : out std_logic;
    ram_Q_full_o        : out std_logic

    );
end RAM_Q;


architecture Behavioral of RAM_Q is
  signal ram_Q_addra : std_logic_vector(12 downto 0);
  signal ram_Q_addrb : std_logic_vector(14 downto 0);
  signal ram_Q_ena : std_logic;
  signal ram_Q_enb : std_logic;
  signal ram_Q_wea : std_logic_vector(0 downto 0);
  signal ram_Q_rstb : std_logic;
  signal clr_n_ram : std_logic;
  signal ram_Q_full : std_logic;
  
  COMPONENT ram_data
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    rstb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

begin

  ram_Q_inst : ram_data
    port map (
      clka  => ram_Q_clka,
      ena   => '1',
      wea   => ram_Q_wea,
      addra => ram_Q_addra,
      dina  => ram_Q_dina,
      clkb  => ram_Q_clkb,
      rstb  => ram_Q_rstb,
      enb   => '1',
      addrb => ram_Q_addrb,
      doutb => ram_Q_doutb
      );


  ram_Q_enb    <= ram_Q_rden;
  ram_Q_ena    <= ram_wren and (not ram_q_full);
  ram_Q_wea(0) <= ram_wren and (not ram_q_full);
  ram_Q_rstb   <= not rst_n;
  clr_n_ram    <= rst_n;
  ram_Q_full_o <=ram_Q_full;
  
  ram_Q_addra_ps : process (ram_Q_clka, clr_n_ram, posedge_sample_trig) is
  begin  -- process addra_ps
    if clr_n_ram = '0' then             -- asynchronous reset (active low)
      ram_Q_addra <= (others => '0');
    elsif ram_Q_clka'event and ram_Q_clka = '1' then      -- rising clock edge
      if posedge_sample_trig = '1' then
        ram_Q_addra <= (others => '0');
      elsif ram_wren = '1' then
        if ram_Q_addra < cmd_smpl_depth(14 downto 2)then  --cmd_smpl_depth/4
          ram_Q_addra <= ram_Q_addra+1;
        end if;
      end if;
    end if;
  end process ram_Q_addra_ps;
  
  ram_Q_full_ps : process (ram_Q_clka, clr_n_ram, posedge_sample_trig) is
  begin  -- process addra_ps
    if clr_n_ram = '0' then             -- asynchronous reset (active low)
      ram_Q_full  <= '0';
    elsif ram_Q_clka'event and ram_Q_clka = '1' then      -- rising clock edge
      if posedge_sample_trig = '1' then
        ram_Q_full  <= '0';
      elsif ram_wren = '1' then
        if ram_Q_addra < cmd_smpl_depth(14 downto 2)then  --cmd_smpl_depth/4
          ram_Q_full  <= '0';
        elsif ram_Q_addra >= cmd_smpl_depth(14 downto 2) then
          ram_Q_full <= '1';
        end if;
      end if;
    end if;
  end process ram_Q_full_ps;
  
  ram_Q_addrb_ps : process (ram_Q_clkb, clr_n_ram) is
  begin  -- process addrb_ps
    if clr_n_ram = '0' then
      ram_Q_addrb <= (others => '0');
    elsif ram_Q_clkb'event and ram_Q_clkb = '1' then           -- rising clock edge
      if posedge_sample_trig = '1' then
        ram_Q_addrb <= (others => '0');  --edit at 8.25 for a bug
      elsif ram_Q_rden = '1' then
        -- if ram_addrb<x"9c37" then
        if ram_Q_addrb < cmd_smpl_depth(14 downto 0) then  --edit at 9.5
          ram_Q_addrb <= ram_Q_addrb+1;
        end if;
      end if;
    end if;
  end process ram_Q_addrb_ps;

    ram_Q_last_ps : process (ram_Q_clkb, clr_n_ram) is
  begin  -- process addrb_ps
    if clr_n_ram = '0' then
      ram_Q_last  <= '1';
    elsif ram_Q_clkb'event and ram_Q_clkb = '1' then           -- rising clock edge
      if posedge_sample_trig = '1' then
        ram_Q_last  <= '0';             --edit at 11.9
      elsif ram_Q_rden = '1' then
        -- if ram_addrb<x"9c37" then
        if ram_Q_addrb < cmd_smpl_depth(14 downto 0) then  --edit at 9.5
          ram_Q_last  <= '0';
        elsif ram_Q_addrb >= cmd_smpl_depth(14 downto 0) then
          ram_Q_last <= '1';
        end if;
      end if;
    end if;
  end process ram_Q_last_ps;
  
end Behavioral;

