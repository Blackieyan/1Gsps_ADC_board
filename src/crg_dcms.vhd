----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:21:17 12/08/2016 
-- Design Name: 
-- Module Name:    crg_dcms - Behavioral 
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

entity crg_dcms is
  port(
    OSC_in_p: in std_logic;
    OSC_in_n: in std_logic;
    ADC_CLKOI_p : in std_logic;
    ADC_CLKOI_n : in std_logic;
    CLK_EXT_250M : in std_logic;
    -- ADC_CLKOQ_p : in std_logic;
    -- ADC_CLKOQ_n : in std_logic;
    PHY_RXC : in std_logic;
    ADC_CLKOI : buffer std_logic;
    ADC_CLKOQ : out std_logic;
    PHY_RXC_g : out std_logic;
    ADC_clkoi_inv : out std_logic;
    ADC_clkoq_inv : out std_logic;
    lck_rst_n : buffer std_logic;
    user_pushbutton_g : in std_logic;
    CLK_125M : out std_logic;
    CLK_200M : out std_logic;
    CLK_250M : out std_logic;
    CLK_500M : out std_logic;
    CLK_EXT_500M : out std_logic;
    CLK_125M_quar : out std_logic
    );
end crg_dcms;

architecture Behavioral of crg_dcms is
  signal dcm1_locked_d : std_logic;
  signal dcm1_locked_d2 : std_logic;
  signal dcm1_locked : std_logic;
  signal clk1 : std_logic;
  signal clk2 : std_logic;
  signal clk3 : std_logic;
  signal clk4 : std_logic;
  signal clk5 : std_logic;
  signal lck_rst_cnt : std_logic_vector(7 downto 0);
  component dcm_adc_clkoi
    port
      (                                 -- Clock in ports
        CLK_IN1_P     : in  std_logic;
        CLK_IN1_N     : in  std_logic;
        -- Clock out ports
        ADC_clkoi     : out std_logic;
        ADC_clkoi_inv : out std_logic
        );
  end component;

  component dcm_adc_clkoq
    port
      (                                 -- Clock in ports
        CLK_IN1_P     : in  std_logic;
        CLK_IN1_N     : in  std_logic;
        -- Clock out ports
        ADC_clkoq     : out std_logic;
        ADC_clkoq_inv : out std_logic
        );
  end component;
  component dcm_rxc
    port
      (                                 -- Clock in ports
        CLK_IN1  : in  std_logic;
        -- Clock out ports
        CLK_OUT1 : out std_logic
        );
  end component;

  component dcm_125MHz
    port
      (                                 -- Clock in ports
        CLK_IN1_P : in  std_logic;
        CLK_IN1_N : in  std_logic;
        -- Clock out ports
        CLK_OUT1  : out std_logic;
        CLK_OUT2  : out std_logic;
        clk_out3  : out std_logic;
        CLK_OUT4          : out    std_logic;
        CLK_OUT5 : out std_logic;
        locked    : out std_logic
        );
  end component;

component dcm_ext_dac
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- CLKFB_IN          : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic
  -- CLKFB_OUT         : out    std_logic
 );
end component;
-------------------------------------------------------------------------------
begin
  CLK_125M<=CLK1;
  CLK_125M_quar<=CLK2;
  CLK_200M<=CLK3;
  CLK_250M<=CLK4;
  CLK_500M<=CLK5;
  
  dcm2 : dcm_adc_clkoi
    port map
    (                                   -- Clock in ports
      CLK_IN1_P     => ADC_CLKOI_p,
      CLK_IN1_N     => ADC_CLKOI_n,
      -- Clock out ports
      ADC_clkoi     => ADC_clkoi,
      ADC_clkoi_inv => ADC_clkoi_inv);

  -- dcm3 : dcm_adc_clkoq
  --   port map
  --   (                                   -- Clock in ports
  --     CLK_IN1_P     => ADC_CLKOQ_p,
  --     CLK_IN1_N     => ADC_CLKOQ_n,
  --     -- Clock out ports
  --     ADC_clkoq     => ADC_clkoq,
  --     ADC_clkoq_inv => ADC_clkoq_inv);
  -----------------------------------------------------------------------------
  ADC_CLKOQ <= ADC_CLKOI;

  -----------------------------------------------------------------------------

  dcm_global : dcm_125MHz
    port map
    (                                   -- Clock in ports
      CLK_IN1_P => OSC_in_p,
      CLK_IN1_N => OSC_in_n,
      -- Clock out ports
      CLK_OUT1  => CLK1,
      CLK_OUT2  => CLK2,
      CLK_OUT3  => CLK3,
      CLK_OUT4  => CLK4,
      CLK_OUT5 => CLK5,                 --500MHz for Oserdes in Estmr module 
      locked    => dcm1_locked
      );

  dcm_rxc_inst : dcm_rxc
    port map
    (                                   -- Clock in ports
      CLK_IN1  => PHY_RXC,
      -- Clock out ports
      CLK_OUT1 => PHY_RXC_g);

  dcm_ext_dac_inst : dcm_ext_dac
  port map
    (-- Clock in ports
     -- CLKFB_IN1 => CLKFB_IN,
    CLK_IN1 => CLK_EXT_250M,
    -- Clock out ports
    CLK_OUT1 => CLK_EXT_500M
    -- CLKFB_OUT => CLKFB_OUT
    );
-------------------------------------------------------------------------------
  dcm1_locked_d_ps : process (CLK1) is
  begin  -- process dcm1_locked_d_ps
    if CLK1'event and CLK1 = '1' then  -- rising clock edge
      dcm1_locked_d  <= dcm1_locked;
      dcm1_locked_d2 <= dcm1_locked_d;
    end if;
  end process dcm1_locked_d_ps;

  lck_rst_n_ps : process (CLK1, user_pushbutton_g) is
  begin  -- process reset_n_ps
    if user_pushbutton_g = '0' then     -- asynchronous reset (active low)
      lck_rst_n <= '1';
    elsif CLK1'event and CLK1 = '1' then  -- rising clock edge
        if dcm1_locked_d = '1' and dcm1_locked_d2 = '0' then
          lck_rst_n <= '0';
        else
          lck_rst_n <= '1';
        end if;
      end if;
  end process lck_rst_n_ps;

  -- lck_rst_cnt_ps: process (clk1, user_pushbutton_g) is
  -- begin  -- process lck_rst_cnt_ps
  --   if user_pushbutton_g = '0' then     -- asynchronous reset (active low)
  --     lck_rst_cnt<=(others => '0');
  --   elsif clk1'event and clk1 = '1' then  -- rising clock edge
  --     if lck_rst_n<='0' then
  --       lck_rst_cnt<=lck_rst_cnt+1;
  --     elsif lck_rst_n<='1' then
  --       lck_rst_cnt<=(others => '0');
  --     end if;
  --   end if;
  -- end process lck_rst_cnt_ps;

end Behavioral;

