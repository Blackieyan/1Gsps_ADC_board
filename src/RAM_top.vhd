----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:14:00 12/07/2016 
-- Design Name: 
-- Module Name:    RAM_top - Behavioral 
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

entity RAM_top is
  port (

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
    ram_Q_full          : out std_logic;
    ---------------------------------------------------------------------------
    ram_I_dina          : in  std_logic_vector(31 downto 0);
    ram_I_clka          : in  std_logic;
    ram_I_clkb          : in  std_logic;
    ram_I_rden          : in  std_logic;
    ram_I_doutb         : out std_logic_vector(7 downto 0);
    ram_I_last          : out std_logic;
    ram_I_full          : out std_logic
   ---------------------------------------------------------------------------
    );
end RAM_top;

architecture Behavioral of RAM_top is
  signal clr_n_ram   : std_logic;
-------------------------------------------------------------------------------


  component RAM_I
    port(
      rst_n               : in  std_logic;
      ram_wren            : in  std_logic;
      posedge_sample_trig : in  std_logic;
      cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
      ram_I_dina          : in  std_logic_vector(31 downto 0);
      ram_I_clka          : in  std_logic;
      ram_I_clkb          : in  std_logic;
      ram_I_rden          : in  std_logic;
      ram_I_doutb         : out std_logic_vector(7 downto 0);
      ram_I_last          : out std_logic;
      ram_I_full_o          : out std_logic
      );
  end component;
  component RAM_Q
    port(
      ram_wren            : in  std_logic;
      posedge_sample_trig : in  std_logic;
      rst_n               : in  std_logic;
      cmd_smpl_depth      : in  std_logic_vector(15 downto 0);
      ram_Q_dina          : in  std_logic_vector(31 downto 0);
      ram_Q_clka          : in  std_logic;
      ram_Q_clkb          : in  std_logic;
      ram_Q_rden          : in  std_logic;
      ram_Q_doutb         : out std_logic_vector(7 downto 0);
      ram_Q_last          : out std_logic;
      ram_Q_full_o          : out std_logic
      );
  end component;


begin

  Inst_RAM_I : RAM_I port map(
    rst_n               => rst_n,
    ram_wren            => ram_wren,
    posedge_sample_trig => posedge_sample_trig,
    cmd_smpl_depth      => cmd_smpl_depth,
    ram_I_dina          => ram_I_dina,
    ram_I_clka          => ram_I_clka,
    ram_I_clkb          => ram_I_clkb,
    ram_I_rden          => ram_I_rden,
    ram_I_doutb         => ram_I_doutb,
    ram_I_last          => ram_I_last,
    ram_I_full_o          => ram_I_full
    );

  Inst_RAM_Q : RAM_Q port map(
    ram_wren            => ram_wren,
    posedge_sample_trig => posedge_sample_trig,
    rst_n               => rst_n,
    cmd_smpl_depth      => cmd_smpl_depth,
    ram_Q_dina          => ram_Q_dina,
    ram_Q_clka          => ram_Q_clka,
    ram_Q_clkb          => ram_Q_clkb,
    ram_Q_rden          => ram_Q_rden,
    ram_Q_doutb         => ram_Q_doutb,
    ram_Q_last          => ram_Q_last,
    ram_Q_full_o          => ram_Q_full
    );

end Behavioral;

