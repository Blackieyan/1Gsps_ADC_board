----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:13:51 08/09/2018 
-- Design Name: 
-- Module Name:    sys_reset_proc - Behavioral 
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

entity sys_reset_proc is
  port(
    sys_rst_n_in : in std_logic;
    sys_clk : in std_logic;
    sram_cal_done : in std_logic;
    clk_config : in std_logic;
    clk_adc : in std_logic;
    clk_eth_r : in std_logic;
    clk_eth_t : in std_logic;
    clk_data : in std_logic;
    clk_data_proc : in std_logic;
    clk_feedback : in std_logic;
    rst_config_n : out std_logic;
    rst_adc_n : out std_logic;
    rst_eth_r_n : out std_logic;
    rst_eth_t_n : out std_logic;
    rst_data_proc_n : out std_logic;
    rst_data_n : out std_logic;
    rst_feedback_n : out std_logic);

end sys_reset_proc;

architecture Behavioral of sys_reset_proc is
  
  signal rst_active_cnt : std_logic_vector(3 downto 0);
  signal rst_cnt : std_logic_vector(19 downto 0);
  signal rst_active : std_logic;
  signal sys_rst_data_n : std_logic;
  signal sys_rst_eth_r_n     : std_logic;
  signal sys_rst_eth_t_n     : std_logic;
  signal sys_rst_data_proc_n : std_logic;
  signal sys_rst_feedback_n  : std_logic;
  signal sys_rst_adc_n  : std_logic;
  signal sys_rst_config_n : std_logic;
  
  COMPONENT async_rst_sync_release
	PORT(
		clk : IN std_logic;
		async_rst_n_in : IN std_logic;          
		sync_rst_n_out : OUT std_logic
		);
	END COMPONENT;
begin
  	Inst_async_rst_sync_release_config: async_rst_sync_release PORT MAP(
		clk => clk_config,
		async_rst_n_in => sys_rst_config_n,
		sync_rst_n_out => rst_config_n
                );
        
	Inst_async_rst_sync_release_eth_r: async_rst_sync_release PORT MAP(
		clk => clk_eth_r,
		async_rst_n_in => sys_rst_eth_r_n,
		sync_rst_n_out => rst_eth_r_n
	);
	Inst_async_rst_sync_release_eth_t: async_rst_sync_release PORT MAP(
		clk =>clk_eth_t ,
		async_rst_n_in => sys_rst_eth_t_n,
		sync_rst_n_out => rst_eth_t_n 
	);
	Inst_async_rst_sync_release_adc: async_rst_sync_release PORT MAP(
		clk => clk_adc,
		async_rst_n_in => sys_rst_adc_n,
		sync_rst_n_out => rst_adc_n
        );
        Inst_async_rst_sync_release_data_proc: async_rst_sync_release PORT MAP(
		clk => clk_data,
		async_rst_n_in => sys_rst_data_n,
		sync_rst_n_out => rst_data_n
	);
	Inst_async_rst_sync_release_data: async_rst_sync_release PORT MAP(
		clk => clk_data_proc,
		async_rst_n_in => sys_rst_data_proc_n,
		sync_rst_n_out => rst_data_proc_n
	);
	Inst_async_rst_sync_release_feedback: async_rst_sync_release PORT MAP(
		clk => clk_feedback,
		async_rst_n_in => sys_rst_feedback_n,
		sync_rst_n_out => rst_feedback_n
	);



  sys_rst_n_in_ps : process (sys_clk, sys_rst_n_in) is
  begin  -- process sys_rst_n_in_ps
    if sys_rst_n_in = '0' then  -- asynchronous reset (active low)
      rst_cnt <= (others => '0');
		rst_active_cnt <= (others => '0');
    elsif sys_clk'event and sys_clk = '1' then  -- rising clock edge
      if rst_cnt(19)= '0' then
        rst_cnt <= rst_cnt+1;
		else
			if(rst_active_cnt < x"3") then
				rst_active_cnt <= rst_active_cnt + '1';
				rst_cnt <= (others => '0');
--			elsif(sram_cal_done = '0') then
--				rst_cnt <= (others => '0');
--				rst_active_cnt <= (others => '0');
			end if;
      end if;
    end if;
end process sys_rst_n_in_ps;

sys_rst_active_ps : process (sys_clk) is
begin  -- process sys_rst_active_ps
  if sys_clk'event and sys_clk = '1' then  -- rising clock edge
    if rst_cnt = x"10000" then
      rst_active <= '1';
    else
      rst_active <= '0';
    end if;
  end if;
end process sys_rst_active_ps;

sys_rst_eth_t_n_ps : process (sys_clk) is
begin  -- process sys_rst_eth_n_ps    
  if sys_clk'event and sys_clk = '1' then  -- rising clock edge
    if rst_cnt = x"20000" then
      sys_rst_eth_t_n <= '1';  --release rst_eth_n
    elsif rst_active = '1' then
      sys_rst_eth_t_n <= '0';  -- active rst_eth_n
    end if;
  end if;
end process sys_rst_eth_t_n_ps;

sys_rst_eth_r_n_ps : process (sys_clk) is
begin  -- process sys_rst_eth_n_ps    
  if sys_clk'event and sys_clk = '1' then  -- rising clock edge
    if rst_cnt = x"20000" then
      sys_rst_eth_r_n <= '1';  --release rst_eth_n
    elsif rst_active = '1' then
      sys_rst_eth_r_n <= '0';  -- active rst_eth_n
    end if;
  end if;
end process sys_rst_eth_r_n_ps;

sys_rst_config_n_ps : process (sys_clk) is
begin  -- process sys_rst_eth_n_ps    
  if sys_clk'event and sys_clk = '1' then  -- rising clock edge
    if rst_cnt = x"20000" then
      sys_rst_config_n <= '1';  --release rst_eth_n
    elsif rst_active = '1' then
      sys_rst_config_n <= '0';  -- active rst_eth_n
    end if;
  end if;
end process sys_rst_config_n_ps;

sys_rst_adc_n_ps : process (sys_clk) is
begin  -- process sys_rst_adc_n_ps    
  if sys_clk'event and sys_clk = '1' then  -- rising clock edge
    if rst_cnt = x"30000" then
      sys_rst_adc_n <= '1';
    elsif rst_active = '1' then
      sys_rst_adc_n <= '0';
    end if;
  end if;
end process sys_rst_adc_n_ps;

sys_rst_data_n_ps : process (sys_clk) is
begin  -- process sys_rst_adc_n_ps    
  if sys_clk'event and sys_clk = '1' then  -- rising clock edge
    if rst_cnt = x"38000" then
      sys_rst_data_n <= '1';  --release rst_data_proc_n
    elsif rst_active = '1' then
      sys_rst_data_n <= '0';  -- active rst_data_proc_n
    end if;
  end if;
end process sys_rst_data_n_ps;

sys_rst_data_proc_n_ps : process (sys_clk) is
begin  -- process sys_rst_adc_n_ps    
  if sys_clk'event and sys_clk = '1' then  -- rising clock edge
    if rst_cnt = x"40000" then
      sys_rst_data_proc_n <= '1';  --release rst_data_proc_n
    elsif rst_active = '1' then
      sys_rst_data_proc_n <= '0';  -- active rst_data_proc_n
    end if;
  end if;
end process sys_rst_data_proc_n_ps;

sys_rst_feedback_n_ps : process (sys_clk) is
begin  -- process sys_rst_adc_n_ps    
  if sys_clk'event and sys_clk = '1' then  -- rising clock edge
    if rst_cnt = x"50000" then
      sys_rst_feedback_n <= '1';  --release rst_data_n
    elsif rst_active = '1' then
      sys_rst_feedback_n <= '0';  -- active rst_data_n
    end if;
  end if;
end process sys_rst_feedback_n_ps;

end Behavioral;

