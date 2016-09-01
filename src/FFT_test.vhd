----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:37:20 12/04/2015 
-- Design Name: 
-- Module Name:    FFT_test - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FFT_test is
 port (
   clk_in : in std_logic;
   enable : in std_logic;
   rst_n : in std_logic);
    
end FFT_test;

architecture Behavioral of FFT_test is
signal addr_cnt : std_logic_vector(5 downto 0);
signal I_out : std_logic_vector(15 downto 0);
signal rsta : std_logic;
  -----------------------------------------------------------------------------
signal xn_re : std_logic_vector(15 downto 0);
signal xn_im : std_logic_vector(15 downto 0);
signal fwd_inv : std_logic;
signal fwd_inv_we : std_logic;
signal rfd : std_logic;
signal dv : std_logic;
signal done : std_logic;
signal busy : std_logic;
signal edone : std_logic;
signal xk_index : std_logic_vector(5 downto 0);
signal xn_index : std_logic_vector(5 downto 0);
signal xk_re : std_logic_vector(15 downto 0);
signal xk_im : std_logic_vector(15 downto 0);
signal scale_sch : std_logic_vector(5 downto 0);
signal scale_sch_we : std_logic;
signal sclr : std_logic;
signal blk_exp : std_logic_vector(4 downto 0);
-------------------------------------------------------------------------------
COMPONENT fft
  PORT (
    clk : IN STD_LOGIC;
    start : IN STD_LOGIC;
    xn_re : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    xn_im : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    fwd_inv : IN STD_LOGIC;
    fwd_inv_we : IN STD_LOGIC;
    scale_sch : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    scale_sch_we : IN STD_LOGIC;
    rfd : OUT STD_LOGIC;
    xn_index : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    busy : OUT STD_LOGIC;
    edone : OUT STD_LOGIC;
    done : OUT STD_LOGIC;
    dv : OUT STD_LOGIC;
    xk_index : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    xk_re : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    xk_im : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
end component;
COMPONENT sine_rom
  PORT (
    clka : IN STD_LOGIC;
    rsta : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;
-------------------------------------------------------------------------------
begin

xn_re<=  I_out;
xn_im<= x"0000";
sclr<= not rst_n;
rsta<= not rst_n;
-- addr_cnt<=xn_index;
fwd_inv_we<='1';
fwd_inv<='1';
scale_sch_we<='1';
 scale_sch<="010101";--scaling factor 8
-------------------------------------------------------------------------------
I_rom: sine_rom
  PORT MAP (
    clka => clk_in,
    rsta => rsta,
    ena => enable,
    addra => addr_cnt,
    douta =>I_out
  );

fft_test : fft
  PORT MAP (
    clk => clk_in,
    start => enable,
    xn_re => xn_re,
    xn_im => xn_im,
    fwd_inv => fwd_inv,
    fwd_inv_we => fwd_inv_we,
    scale_sch => scale_sch,
    scale_sch_we => scale_sch_we,
    rfd => rfd,
    xn_index => xn_index,
    busy => busy,
    edone => edone,
    done => done,
    dv => dv,
    xk_index => xk_index,
    xk_re => xk_re,
    xk_im => xk_im
  );

-- purpose: set a counter for rom_addr
-- type   : sequential
-- inputs : clk_in, rst
-- outputs: 
addr_counter: process (clk_in, rst_n) is
begin  -- process addr_counter
  if rst_n = '0' then                     -- asynchronous reset (active low)
    addr_cnt<=(others => '0');
  elsif clk_in'event and clk_in = '1' then  -- rising clock edge
    addr_cnt<=addr_cnt+1;
  end if;
end process addr_counter;

end Behavioral;

