----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:31:56 04/13/2017 
-- Design Name: 
-- Module Name:    Pstprc_fifo - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values

use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Pstprc_fifo_top is
 generic (
      DATA_WIDTH     : integer := 36;
      BURST_LEN     : integer := 4
      );
  port(
    ----sram interface------
	 clk_200M : IN std_logic;
	clk_125M : IN std_logic;
	ui_clk_in : IN std_logic;
	qdriip_cq_p : IN std_logic_vector(0 to 0);
	qdriip_cq_n : IN std_logic_vector(0 to 0);
	qdriip_q : IN std_logic_vector(35 downto 0);         
	qdriip_k_p : OUT std_logic_vector(0 to 0);
	qdriip_k_n : OUT std_logic_vector(0 to 0);
	qdriip_d : OUT std_logic_vector(35 downto 0);
	qdriip_sa : OUT std_logic_vector(18 downto 0);
	qdriip_w_n : OUT std_logic;
	qdriip_r_n : OUT std_logic;
	qdriip_bw_n : OUT std_logic_vector(3 downto 0);
	qdriip_dll_off_n : OUT std_logic;
	cal_done : OUT std_logic;
    ----sram interface------
  
    rst_n : IN STD_LOGIC;
    Pstprc_fifo_wr_clk : IN STD_LOGIC;
    Pstprc_fifo_rd_clk : IN STD_LOGIC;
    Pstprc_fifo_din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    Pstprc_fifo_wren : IN STD_LOGIC;
    Pstprc_fifo_rden : IN STD_LOGIC;
    Pstprc_finish_in : IN STD_LOGIC;
    tx_rdy : IN STD_LOGIC;
    -- prog_empty_thresh : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    Pstprc_fifo_dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    Pstprc_fifo_valid : OUT STD_LOGIC;
    Pstprc_fifo_pempty : OUT STD_LOGIC;
    Pstprc_finish_out : OUT STD_LOGIC;
    pstprc_fifo_alempty : out STD_LOGIC
);
end Pstprc_fifo_top;

architecture Behavioral of Pstprc_fifo_top is
  
  signal fifo1_empty : std_logic;
  signal fifo1_wr_en : std_logic;
  signal fifo1_rd_en : std_logic;
  signal fifo1_rd_vld : std_logic;
  signal fifo1_dout : std_logic_vector(65 downto 0);
  signal fifo1_in : std_logic_vector(65 downto 0);
  
  signal Pstprc_fifo_wren_pre : std_logic;
  signal Pstprc_finish_int : std_logic;
  signal Pstprc_finish_temp : std_logic;
  
  signal set_rd_buf_fifo : std_logic;
  signal rd_buf_fifo : std_logic;
  signal buf_fifo_rden : std_logic;
  signal buf_fifo_rd_vld : std_logic;
  signal buf_fifo_prog_full : std_logic;
  signal buf_fifo_empty : std_logic;
  signal buf_fifo_full : std_logic;
  signal buf_fifo_dout : std_logic_vector(65 downto 0);
  
  signal wr_cnt : std_logic_vector(18 downto 0);
  signal rd_cnt : std_logic_vector(18 downto 0);
  
  signal cal_done_i : std_logic;
  signal rst : std_logic;
  signal prog_full : std_logic;
  signal fifo2_wr_en : std_logic;
  signal full : std_logic;
  signal empty : std_logic;
  signal fifo2_din : std_logic_vector(63 downto 0);
  signal dout : std_logic_vector(7 downto 0);
  signal data_pre : std_logic_vector(31 downto 0);
  signal delta : std_logic_vector(31 downto 0);
  signal timeout_rst_cnt : std_logic_vector(19 downto 0);
  signal timeout_rst : std_logic;
--  attribute KEEP : string;
--attribute KEEP of data_pre: signal is "TRUE";
--attribute KEEP of delta: signal is "TRUE";
  signal empty_rst : std_logic;
  signal ui_clk : std_logic;
  signal ui_clk_sync_rst : std_logic;
  signal sram_fifo_empty : std_logic;
	signal user_rd_valid0_reg : std_logic;
	signal user_rd_valid0_reg1 : std_logic;
	signal user_rd_valid0 : std_logic;
	signal user_rd_data0_reg : std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
	signal user_rd_data0_reg1 : std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
	signal user_rd_data0 : std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
 	signal 	user_wr_cmd0_reg  : std_logic;
 	signal 	user_wr_cmd0_reg1  : std_logic;
 	signal 	user_wr_cmd0  : std_logic;
	signal 	user_wr_addr0_reg : std_logic_vector(18 downto 0);
	signal 	user_wr_addr0_reg1 : std_logic_vector(18 downto 0);
	signal 	user_wr_addr0 : std_logic_vector(18 downto 0);
	signal 	user_rd_cmd0_reg  : std_logic;
	signal 	user_rd_cmd0_reg1  : std_logic;
	signal 	user_rd_cmd0  : std_logic;
	signal 	user_rd_addr0_reg : std_logic_vector(18 downto 0);
	signal 	user_rd_addr0_reg1 : std_logic_vector(18 downto 0);
	signal 	user_rd_addr0 : std_logic_vector(18 downto 0);
	signal 	user_wr_data0_reg : std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
	signal 	user_wr_data0_reg1 : std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
	signal 	user_wr_data0 : std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
	signal 	user_wr_bw_n0 : std_logic_vector(BURST_LEN*4-1 downto 0);
--attribute KEEP of user_rd_addr0: signal is "TRUE";
--attribute KEEP of user_wr_addr0: signal is "TRUE";	
COMPONENT post_pro_wr_fifo
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(65 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(65 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;
  
	COMPONENT sram_interface
	PORT(
		sys_clk : IN std_logic;
		ui_clk_in : IN std_logic;
		clk_ref : IN std_logic;
		qdriip_cq_p : IN std_logic_vector(0 to 0);
		qdriip_cq_n : IN std_logic_vector(0 to 0);
		qdriip_q : IN std_logic_vector(35 downto 0);
		user_wr_cmd0 : IN std_logic;
		user_wr_addr0 : IN std_logic_vector(18 downto 0);
		user_rd_cmd0 : IN std_logic;
		user_rd_addr0 : IN std_logic_vector(18 downto 0);
		user_wr_data0 : IN std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
		user_wr_bw_n0 : IN std_logic_vector(4*BURST_LEN-1 downto 0);
		sys_rst : IN std_logic;          
		qdriip_k_p : OUT std_logic_vector(0 to 0);
		qdriip_k_n : OUT std_logic_vector(0 to 0);
		qdriip_d : OUT std_logic_vector(35 downto 0);
		qdriip_sa : OUT std_logic_vector(18 downto 0);
		qdriip_w_n : OUT std_logic;
		qdriip_r_n : OUT std_logic;
		qdriip_bw_n : OUT std_logic_vector(4-1 downto 0);
		ui_clk : OUT std_logic;
		ui_clk_sync_rst : OUT std_logic;
		user_rd_valid0 : OUT std_logic;
		user_rd_data0 : OUT std_logic_vector(DATA_WIDTH*BURST_LEN-1 downto 0);
		qdriip_dll_off_n : OUT std_logic;
		cal_done : OUT std_logic
		);
	END COMPONENT;
COMPONENT post_pro_buf_fifo
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(65 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(65 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END COMPONENT; 
COMPONENT Pstprc_Fifo

  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    -- prog_empty_thresh : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    almost_empty : OUT STD_LOGIC;
    prog_empty : OUT STD_LOGIC
  );
END COMPONENT;


begin
  cal_done <= cal_done_i;
  rst <= (not rst_n) or ui_clk_sync_rst;
  fifo1_in <= Pstprc_fifo_wren & Pstprc_finish_int & Pstprc_fifo_din;
  fifo1_wr_en <= Pstprc_fifo_wren or Pstprc_finish_int;
  
  process (Pstprc_fifo_wr_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_wr_clk'event and Pstprc_fifo_wr_clk = '1' then  -- rising clock edge
      Pstprc_fifo_wren_pre <= Pstprc_fifo_wren;
      Pstprc_finish_int <= not Pstprc_fifo_wren and Pstprc_fifo_wren_pre;
    end if;
  end process;
  inst_post_pro_wr_fifo : post_pro_wr_fifo
  PORT MAP (
    rst => rst,
    wr_clk => Pstprc_fifo_wr_clk,
    rd_clk => ui_clk,
    din => fifo1_in,
    wr_en =>fifo1_wr_en,
    rd_en => fifo1_rd_en,
    dout => fifo1_dout,
    full => open,
    empty => fifo1_empty,
    valid => fifo1_rd_vld
  );
  
  -- read fifo1 while fifo is not empty
  -- this is for synchronization two clock
  process (ui_clk, ui_clk_sync_rst) is
  begin  -- process Pstprc_fifo_dout_ps
    if ui_clk_sync_rst = '1' then                 -- asynchronous reset (active low)
      fifo1_rd_en <= '0';
    elsif ui_clk'event and ui_clk = '1' then  -- rising clock edge
      fifo1_rd_en <= not fifo1_empty and cal_done_i and not fifo1_rd_en;
    end if;
  end process;
  
  ------- SRAM write ---------
  -- write data to SRAM
  process (ui_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if ui_clk'event and ui_clk = '1' then  -- rising clock edge
      user_wr_cmd0_reg1 <= user_wr_cmd0;
		user_wr_data0_reg1 <= user_wr_data0;
	   user_wr_addr0_reg1 <= user_wr_addr0;
		user_wr_cmd0_reg <= user_wr_cmd0_reg1;
		user_wr_data0_reg <= user_wr_data0_reg1;
	   user_wr_addr0_reg <= user_wr_addr0_reg1;
    end if;
  end process;
  
  process (ui_clk, rst) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst = '1' then                 -- asynchronous reset (active low)
      user_wr_cmd0 <= '0';
      user_wr_data0 <= (others => '0');
      user_wr_addr0 <= (others => '0');
    elsif ui_clk'event and ui_clk = '1' then  -- rising clock edge
      user_wr_cmd0 <= fifo1_rd_vld;
		user_wr_data0(65 downto 0) <= fifo1_dout;
		if user_wr_cmd0 = '1' then
			user_wr_addr0 <= user_wr_addr0 + 4;
		end if;
    end if;
  end process;
  
  
  
  inst_SRAM : SRAM_interface
  port map(
--    sys_clk_p                  => sys_clk_p,
--    sys_clk_n                  => sys_clk_n,
    ui_clk_in                  => ui_clk_in,
    sys_clk                  => CLK_125M,
    clk_ref                  => CLK_200M,
--    clk_ref_p                  => clk_ref_p,
--    clk_ref_n                  => clk_ref_n,
    qdriip_cq_p                => qdriip_cq_p,
    qdriip_cq_n                => qdriip_cq_n,
    qdriip_q                   => qdriip_q,
    qdriip_k_p                 => qdriip_k_p,
    qdriip_k_n                 => qdriip_k_n,
    qdriip_d                   => qdriip_d,
    qdriip_sa                  => qdriip_sa,
    qdriip_w_n                 => qdriip_w_n,
    qdriip_r_n                 => qdriip_r_n,
    qdriip_bw_n                => qdriip_bw_n,
    qdriip_dll_off_n           => qdriip_dll_off_n,
    cal_done                   => cal_done_i,
    user_wr_cmd0               => user_wr_cmd0_reg,
    user_wr_addr0              => user_wr_addr0_reg,
    user_rd_cmd0               => user_rd_cmd0_reg,
    user_rd_addr0              => user_rd_addr0_reg,
    user_wr_data0              => user_wr_data0_reg,
    user_wr_bw_n0              => user_wr_bw_n0(4*BURST_LEN-1 downto 0),
    ui_clk                     => ui_clk,
    ui_clk_sync_rst            => ui_clk_sync_rst,
    user_rd_valid0             => user_rd_valid0_reg,
    user_rd_data0              => user_rd_data0_reg,
    sys_rst                => rst_n
    );
  
  user_wr_bw_n0	<= (others => '0');
  process (ui_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if ui_clk'event and ui_clk = '1' then  -- rising clock edge
		if user_wr_addr0 < 10 then
			sram_fifo_empty <= '1';
		else
			sram_fifo_empty <= '0';
		end if;
    end if;
  end process;
  ------- SRAM read ---------
  -- 缓存FIFO有空间时才能读SRAM
  -- read sram fifo while sram is not empty
  process (ui_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if ui_clk'event and ui_clk = '1' then  -- rising clock edge
			user_rd_cmd0_reg1 <= user_rd_cmd0;
			user_rd_addr0_reg1 <= user_rd_addr0;
			user_rd_data0_reg1 <= user_rd_data0_reg;
			user_rd_valid0_reg1 <= user_rd_valid0_reg;
			user_rd_cmd0_reg <= user_rd_cmd0_reg1;
			user_rd_addr0_reg <= user_rd_addr0_reg1;
			user_rd_data0 <= user_rd_data0_reg1;
			user_rd_valid0 <= user_rd_valid0_reg1;
    end if;
  end process;
  
  process (ui_clk, rst) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst = '1' then                 -- asynchronous reset (active low)
      user_rd_cmd0 <= '0';
      user_rd_addr0 <= (others => '0');
    elsif ui_clk'event and ui_clk = '1' then  -- rising clock edge
	   if user_rd_cmd0 = '0' then
			if((user_wr_addr0 /= user_rd_addr0) and (buf_fifo_prog_full = '0') and (sram_fifo_empty = '0'))then
				user_rd_cmd0 <= '1';
			else
				user_rd_cmd0 <= '0';
			end if;
		else
			user_rd_cmd0 <= '0';
		end if;
		if user_rd_cmd0 = '1' then
			user_rd_addr0 <= user_rd_addr0+4;
		end if;
    end if;
  end process;
  
  Pstprc_buf_Fifo_inst : post_pro_buf_fifo
  PORT MAP (
    rst => rst,
    wr_clk => ui_clk,
    rd_clk => Pstprc_fifo_rd_clk,
    din => user_rd_data0(65 downto 0),
    wr_en =>user_rd_valid0,
    rd_en =>buf_fifo_rden,
    dout => buf_fifo_dout,
    full => buf_fifo_full,
    empty => buf_fifo_empty,
    valid => buf_fifo_rd_vld,
    prog_full => buf_fifo_prog_full
  );
  ------- buf fifo read ---------
  -- 输出FIFO为空，buf_fifo不空，且tx_RDY有效时才能启动读buf fifo
  -- 直到读出 Pstprc_finish 信号，停止当前读出，否则， 读buf fifo
  
  process (Pstprc_fifo_rd_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      if buf_fifo_rd_vld = '1' and buf_fifo_dout(65) = '1' then
		data_pre <= buf_fifo_dout(31 downto 0);
		delta <= buf_fifo_dout(31 downto 0) - data_pre;		
		end if;
    end if;
  end process; 
  
  set_rd_buf_fifo <= tx_rdy and (not rd_buf_fifo) and empty and (not buf_fifo_empty);
  process (Pstprc_fifo_rd_clk, rst) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst = '1' then                 -- asynchronous reset (active low)
      rd_buf_fifo <= '0';
    elsif Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      if set_rd_buf_fifo = '1' then
			rd_buf_fifo	<= '1';
		elsif(Pstprc_finish_temp = '1') then
			rd_buf_fifo	<= '0';
		end if;
    end if;
  end process; 
  
  Pstprc_finish_temp <= buf_fifo_dout(64) and buf_fifo_rd_vld;
  
  process (Pstprc_fifo_rd_clk, rst) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst = '1' then                 -- asynchronous reset (active low)
      buf_fifo_rden <= '0';
    elsif Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      if rd_buf_fifo = '1' then
--			buf_fifo_rden <= (not buf_fifo_rden) and (not Pstprc_finish_temp) and (not full);
			buf_fifo_rden <= not(buf_fifo_rden or Pstprc_finish_temp or full or buf_fifo_empty) ;
		else
			buf_fifo_rden	<= '0';
		end if;
    end if;
  end process; 
  
  process (Pstprc_fifo_rd_clk, rst) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst = '1' then  
		Pstprc_finish_out <= '0';
	 elsif Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
		if Pstprc_finish_temp = '1' then
			Pstprc_finish_out <= '1';
		elsif tx_rdy = '0' then
			Pstprc_finish_out <= '0';
		end if;
	end if;
  end process;
  
  process (Pstprc_fifo_rd_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      fifo2_wr_en <= buf_fifo_dout(65) and buf_fifo_rd_vld;
		fifo2_din   <= buf_fifo_dout(63 downto 0);
    end if;
  end process;
  empty_rst <= rst or timeout_rst;
  Pstprc_Fifo_inst : Pstprc_Fifo
  PORT MAP (
    rst => empty_rst,
    wr_clk => Pstprc_fifo_rd_clk,
    rd_clk => Pstprc_fifo_rd_clk,
    din => fifo2_din,
    wr_en =>fifo2_wr_en,
    rd_en =>Pstprc_fifo_rden,
    -- prog_empty_thresh => prog_empty_thresh,
    dout => dout,
    full => full,
    empty => empty,
    valid => Pstprc_fifo_valid,
    prog_empty => pstprc_fifo_pempty,
    almost_empty => pstprc_fifo_alempty
  );

  Pstprc_fifo_dout_ps: process (Pstprc_fifo_rd_clk, rst_n) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
        Pstprc_fifo_dout<=(others => '0');
    elsif Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      Pstprc_fifo_dout<= dout;
    end if;
  end process Pstprc_fifo_dout_ps;
  
  timeout_ps: process (Pstprc_fifo_rd_clk) is
  begin  -- process empty_rst_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      if empty='1' and buf_fifo_empty ='0' then
        timeout_rst_cnt <= timeout_rst_cnt + '1';
      else
        timeout_rst_cnt	<= (others => '0');
      end if;
		
		if timeout_rst_cnt > 10000 then
			timeout_rst <= '1';
		else
			timeout_rst <= '0';
		end if;
    end if;
  end process timeout_ps;
end Behavioral;

