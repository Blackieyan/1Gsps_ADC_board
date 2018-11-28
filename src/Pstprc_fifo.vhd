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
    ----configinterface------
    recved_frame_cnt : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    wait_cnt_set : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
	 host_rd_mode : IN STD_LOGIC;
	 host_rd_status : IN STD_LOGIC;
	 host_rd_enable : IN STD_LOGIC;
	 host_rd_start_addr : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
	 host_rd_length : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
	 host_rd_seg_len : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    status_ram_addr : OUT std_logic_vector(6 downto 0);
		status_ram_rd_en : OUT std_logic;          
		status_ram_data : IN std_logic_vector(63 downto 0);
		status_ram_data_vld : IN std_logic;
    rst_n : IN STD_LOGIC;
    Pstprc_fifo_wr_clk : IN STD_LOGIC;
    Pstprc_fifo_rd_clk : IN STD_LOGIC;
    Pstprc_fifo_din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    Pstprc_fifo_wren : IN STD_LOGIC;
    Pstprc_fifo_rden : IN STD_LOGIC;
    Pstprc_finish_in : IN STD_LOGIC;
    tx_rdy : IN STD_LOGIC;
    cmd_smpl_en : IN STD_LOGIC;
    trig_recv_done : IN STD_LOGIC;
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
  signal fifo1_dout : std_logic_vector(131 downto 0);
  signal fifo1_in : std_logic_vector(65 downto 0);
  signal Pstprc_fifo_din_d1 : std_logic_vector(63 downto 0);
  
  signal Pstprc_fifo_wren_d1 : std_logic;
  signal Pstprc_fifo_wren_d2 : std_logic;
  signal Pstprc_fifo_wren_d3 : std_logic;
  signal Pstprc_fifo_wren_d4 : std_logic;
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
  signal buf_fifo_din : std_logic_vector(131 downto 0);
  
  signal wr_cnt : std_logic_vector(18 downto 0);
  signal rd_cnt : std_logic_vector(18 downto 0);
  
  signal cal_done_i : std_logic;
  signal rst : std_logic;
  signal prog_full : std_logic;
  signal fifo2_wr_en : std_logic;
  signal empty : std_logic;
  signal status_ram_rd_addr_sig : std_logic_vector(7 downto 0);
  signal fifo2_din : std_logic_vector(63 downto 0);
  signal dout : std_logic_vector(7 downto 0);
  signal data_pre : std_logic_vector(31 downto 0);
  signal delta : std_logic_vector(31 downto 0);
  signal timeout_rst_cnt : std_logic_vector(23 downto 0);
  signal timeout_rst : std_logic;
  signal host_rd_status_d1 : std_logic;
  signal active_send_status : std_logic;
  signal status_ram_rd_en_sig : std_logic;
  
 	signal 	tx_rdy_d1  : std_logic;
 	signal 	tx_rdy_d2  : std_logic;
 	signal 	can_read_new_result  : std_logic;
	signal 	wait_cnt : std_logic_vector(23 downto 0);
  attribute KEEP : string;
attribute KEEP of data_pre: signal is "TRUE";
attribute KEEP of delta: signal is "TRUE";
  signal sram_init : std_logic;
  signal sram_init_d1 : std_logic;
  signal sram_init_r : std_logic;
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
	
	---------------------------------------------------------------
	---host read
	signal 	cmd_smpl_en_d : std_logic;
	signal 	cmd_smpl_en_r : std_logic;
	signal 	host_rd_enable_r : std_logic;
	signal 	frame_end : std_logic;
	signal 	frame_cnt : std_logic_vector(15 downto 0);
	signal 	host_rd_end_addr : std_logic_vector(18 downto 0);
	signal 	recved_frame_cnt_int : std_logic_vector(23 downto 0);
	signal 	host_rd_enable_d1 : std_logic;
	signal 	host_rd_enable_d2 : std_logic;
	signal 	host_rd_enable_lch : std_logic;
	signal 	host_rd_end : std_logic;
	
	-------------------------------------------------------------------
	
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
    dout : OUT STD_LOGIC_VECTOR(131 DOWNTO 0);
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
    din : IN STD_LOGIC_VECTOR(131 DOWNTO 0);
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
    prog_full : OUT STD_LOGIC;
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    almost_empty : OUT STD_LOGIC;
    prog_empty : OUT STD_LOGIC
  );
END COMPONENT;


begin
  host_rd_end_addr <= host_rd_start_addr + host_rd_length;
  cal_done <= cal_done_i;
  rst <= (not rst_n) or ui_clk_sync_rst;
--  fifo1_in <= Pstprc_fifo_wren & Pstprc_finish_int & Pstprc_fifo_din;
--  fifo1_wr_en <= Pstprc_fifo_wren or Pstprc_finish_int;
    
  ---sram init done 在fifo写时 如果不成功，则sram 复位
  process (Pstprc_fifo_wr_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_wr_clk'event and Pstprc_fifo_wr_clk = '1' then  -- rising clock edge
      sram_init <= not cal_done_i and Pstprc_fifo_wren;
      sram_init_d1 <= sram_init;
      sram_init_r <= not(sram_init and not sram_init_d1) and rst_n ;
    end if;
  end process;
  
  --数据写入要保持4的整数倍,最后一个数加入last标志
  Pstprc_finish_int <= fifo1_wr_en and not Pstprc_fifo_wren; --falling edge
  fifo1_in <= fifo1_wr_en & Pstprc_finish_int & Pstprc_fifo_din_d1;
  process (Pstprc_fifo_wr_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_wr_clk'event and Pstprc_fifo_wr_clk = '1' then  -- rising clock edge
      fifo1_wr_en         <= Pstprc_fifo_wren;
      Pstprc_fifo_din_d1  <= Pstprc_fifo_din;
    end if;
  end process;
  
  ---接收到的帧计数
  recved_frame_cnt <= recved_frame_cnt_int;
  process (Pstprc_fifo_wr_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_wr_clk'event and Pstprc_fifo_wr_clk = '1' then  -- rising clock edge
		cmd_smpl_en_d <= cmd_smpl_en;
		cmd_smpl_en_r <= not cmd_smpl_en_d and cmd_smpl_en;
      if Pstprc_finish_int = '1' then
			recved_frame_cnt_int <= recved_frame_cnt_int + '1';
		elsif cmd_smpl_en_r = '1' then --新采样任务的上升沿
			recved_frame_cnt_int <= (others => '0');
		end if;
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
      fifo1_rd_en <= not fifo1_empty and cal_done_i;
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
  
  ---fifo中有数就读出并写入SRAM，每写一次SRAM地址加1
  ---上位机读模式下，在读使能达到时，该地址清零，防止切换模式时读写SRAM地址不一致导致逻辑认为SRAM有数而向外主动发数
  ---
  process (ui_clk, rst) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst = '1' then                 -- asynchronous reset (active low)
      user_wr_cmd0 <= '0';
      user_wr_data0 <= (others => '0');
      user_wr_addr0 <= (others => '0');
    elsif ui_clk'event and ui_clk = '1' then  -- rising clock edge
      user_wr_cmd0 <= fifo1_rd_vld;
		user_wr_data0(65 downto 0) <= fifo1_dout(65 downto 0);
		user_wr_data0(137 downto 72) <= fifo1_dout(131 downto 66);
		if user_wr_cmd0 = '1' then
			user_wr_addr0 <= user_wr_addr0 + 1;
		elsif(host_rd_enable_r = '1' or cmd_smpl_en_r = '1') then
			user_wr_addr0 <= (others => '0');
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
    sys_rst                => sram_init_r
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
			if host_rd_mode = '1' then
				user_rd_data0(63 downto 0) <= user_rd_data0_reg1(63 downto 0);
				user_rd_data0(135 downto 65) <= user_rd_data0_reg1(135 downto 65);
				user_rd_data0(143 downto 137) <= user_rd_data0_reg1(143 downto 137);
				-- user_rd_data0(65) <= user_rd_data0_reg1(65);
				-- user_rd_data0(137) <= user_rd_data0_reg1(137);
				user_rd_data0(64) <= frame_end;
				user_rd_data0(136) <= '0';
			else
				user_rd_data0 <= user_rd_data0_reg1;
			end if;
			user_rd_valid0 <= user_rd_valid0_reg1;
    end if;
  end process;
  
  ---上位机读模式下，根据命令中的分段长度产生分段结束信号
  process (ui_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if ui_clk'event and ui_clk = '1' then  -- rising clock edge
			if host_rd_mode = '0' then
				frame_cnt <= (others => '0');
				frame_end <= '0';
			elsif user_rd_valid0_reg = '1' then
				if frame_cnt < host_rd_seg_len then
					frame_cnt <= frame_cnt + '1';
					frame_end <= '0';
				else
					frame_cnt <= (others => '0');
					frame_end <= '1';
				end if;
			else
				frame_end <= '0';
			end if;
    end if;
  end process;
  
  --上位机读模式下，读使能信号到来时锁存使能信号，直到当前次数据读完,同时要产生上升沿脉冲，用于读SRAM地址初始化
  process (ui_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if ui_clk'event and ui_clk = '1' then  -- rising clock edge
		host_rd_enable_d1 <= host_rd_enable;
		host_rd_enable_d2 <= host_rd_enable_d1;
		if(host_rd_enable_d2 = '0' and host_rd_enable_d1 = '1') then
			host_rd_enable_r <= '1';
			host_rd_enable_lch <= '1';
		elsif(host_rd_end = '1' ) then
			host_rd_enable_r <= '0';
			host_rd_enable_lch <= '0';	
		else
			host_rd_enable_r <= '0';
			if host_rd_mode = '0' then
				host_rd_enable_lch <= '0';	
			end if;
		end if;
			
    end if;
  end process;
  
    --上位机读模式下，产生读结束信号
  process (ui_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if ui_clk'event and ui_clk = '1' then  -- rising clock edge
			if(user_rd_addr0 = host_rd_end_addr) then
				host_rd_end <= '1';
			else
				host_rd_end <= '0';
			end if;
    end if;
  end process;
  
  --非上位机读模式，当buf fifo不满，且SRAM数据未读完时，发出读信号，为了方便判断，读信号不是连续发出的，而是间隔发出的
  --非上位机读模式，上位机每启动一次任务，将读地址和写地址清零，实现每次任务从0地址开始存储
  --sram_fifo_empty 的判断是希望SRAM中有足够的数据时才启动读，上位机读模式不需要这个判断
  --上位机读模式，在读使能上升沿设置起始地址，然后按照非上位机读模式读取数据，直到目标地址到达
  --上位机读模式下，帧结束标志不是由写入SRAM的数据决定的，而是由上位机读命令指令的长度（以SRAM地址为计数单位）
  process (ui_clk, rst) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst = '1' then                 -- asynchronous reset (active low)
      user_rd_cmd0 <= '0';
      user_rd_addr0 <= (others => '0');
    elsif ui_clk'event and ui_clk = '1' then  -- rising clock edge
      if(host_rd_mode = '0') then
        if user_rd_cmd0 = '0' then
          if((user_wr_addr0 > user_rd_addr0) and (buf_fifo_prog_full = '0') and (sram_fifo_empty = '0'))then
            user_rd_cmd0 <= '1';
          else
            user_rd_cmd0 <= '0';
          end if;
        else
          user_rd_cmd0 <= '0';
        end if;
        if user_rd_cmd0 = '1' then
          user_rd_addr0 <= user_rd_addr0+1;
        elsif cmd_smpl_en_r = '1' then
          user_rd_addr0 <= (others => '0');
        end if;
      elsif(host_rd_enable_lch = '1') then
        if(host_rd_enable_r = '1') then
          user_rd_addr0	<= host_rd_start_addr;
        elsif user_rd_cmd0 = '1' then
          user_rd_addr0 <= user_rd_addr0+1;
        end if;
        if user_rd_cmd0 = '0' then
          if((user_rd_addr0 /= host_rd_end_addr) and (buf_fifo_prog_full = '0'))then
            user_rd_cmd0 <= '1';
          else
            user_rd_cmd0 <= '0';
          end if;
        else
          user_rd_cmd0 <= '0';
        end if;
      else
        user_rd_addr0	<= (others => '0');
        user_rd_cmd0 <= '0';
      end if;
    end if;
  end process;
  
  buf_fifo_din <= user_rd_data0(137 downto 72) & user_rd_data0(65 downto 0);
  
  Pstprc_buf_Fifo_inst : post_pro_buf_fifo
  PORT MAP (
    rst => rst,
    wr_clk => ui_clk,
    rd_clk => Pstprc_fifo_rd_clk,
    din => buf_fifo_din,
    wr_en =>user_rd_valid0,
    rd_en =>buf_fifo_rden,
    dout => buf_fifo_dout,
    full => buf_fifo_full,
    empty => buf_fifo_empty,
    valid => buf_fifo_rd_vld,
    prog_full => buf_fifo_prog_full
  );
  
  process (Pstprc_fifo_rd_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      if buf_fifo_rd_vld = '1' and buf_fifo_dout(64) = '1' then
		data_pre <= data_pre+'1';
--		data_pre <= buf_fifo_dout(31 downto 0);
--		delta <= buf_fifo_dout(31 downto 0) - data_pre;		
		end if;
    end if;
  end process; 
  ------- buf fifo read ---------
  -- 输出FIFO为空，buf_fifo不空，且tx_RDY有效时才能启动读buf fifo
  -- 直到读出 Pstprc_finish 信号，停止当前读出，否则， 读buf fifo  
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
  
  --避免触发间隔小的时候网络帧间隔过小，强制等待上一帧数据发完后1us后才发送下一帧数据
  process (Pstprc_fifo_rd_clk) is
  begin  -- process Pstprc_fifo_dout_ps
	 if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      tx_rdy_d1 <= tx_rdy;
      tx_rdy_d2 <= tx_rdy_d1;
		if tx_rdy_d1 = '1' and tx_rdy_d2 = '0' and data_pre(9 downto 0) = "1111111111" then --每传1024帧结果，等待wait cnt
			wait_cnt <= wait_cnt_set;
		elsif wait_cnt /= 0 then
			wait_cnt <= wait_cnt - 1;
		end if;
    end if;
  end process; 
  --什么时候可以读呢？其中一个条件是逻辑向网络传输1024帧数据后，需要等一个计数器值减到0，该值可通过上位机设置
  process (Pstprc_fifo_rd_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      if wait_cnt = 0 then
		can_read_new_result <= not active_send_status; --上位机不在读状态
		else
			can_read_new_result <= '0';
		end if;
    end if;
  end process;
  
  --buf fifo的读取条件：
  -- 当前网络没有数据在发送
  -- 不连续读两次数据
  -- 当前帧数据没有读到最后一个
  -- 前端FIFO有空间
  -- buf fifo 有数据
  -- 等待计数器表示不在计数
  process (Pstprc_fifo_rd_clk, rst) is
  begin  -- process Pstprc_fifo_dout_ps
    if rst = '1' then                 -- asynchronous reset (active low)
      buf_fifo_rden <= '0';
    elsif Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      if rd_buf_fifo = '1' then
--			buf_fifo_rden <= (not buf_fifo_rden) and (not Pstprc_finish_temp) and (not full);
			buf_fifo_rden <= not(buf_fifo_rden or Pstprc_finish_temp or prog_full or buf_fifo_empty) and  can_read_new_result;
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
	 --都状态数据时，在最后一个地址发出数据包有效信号，持续到网络发送模块响应为止
		if Pstprc_finish_temp = '1' or status_ram_rd_addr_sig = x"7F" then
			Pstprc_finish_out <= '1';
		elsif tx_rdy = '0' then
			Pstprc_finish_out <= '0';
		end if;
	end if;
  end process;
  
  --写入前端fifo的数据的使能信号是封装在数据位的高位的
  process (Pstprc_fifo_rd_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
		if active_send_status = '1' then
			fifo2_wr_en <= status_ram_data_vld;
			fifo2_din   <= status_ram_data(63 downto 0);
		else
			fifo2_wr_en <= buf_fifo_dout(65) and buf_fifo_rd_vld;
			fifo2_din   <= buf_fifo_dout(63 downto 0);
		end if;
    end if;
  end process;
  
  --在发送状态数据包期间要生成状态数据包写入fifo的选通信号
  process (Pstprc_fifo_rd_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
		active_send_status <= status_ram_rd_en_sig or status_ram_data_vld;
    end if;
  end process;  
  --上位机主动发读状态命令或上位机读模式下逻辑接收到设定的触发个数，我们就启动一次读状态，将1024字节的状态数据从RAM读出
  status_ram_addr	<= status_ram_rd_addr_sig(6 downto 0);
  status_ram_rd_en <= status_ram_rd_en_sig;
  process (Pstprc_fifo_rd_clk) is
  begin  -- process Pstprc_fifo_dout_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
		host_rd_status_d1 <= host_rd_status;
		if (host_rd_status_d1 = '0' and host_rd_status = '1') or (trig_recv_done = '1' and host_rd_mode = '1') then
			status_ram_rd_addr_sig <= (others => '0');
			status_ram_rd_en_sig   <= '1';
		elsif status_ram_rd_addr_sig < x"80" then
			status_ram_rd_addr_sig <= status_ram_rd_addr_sig+1;
			status_ram_rd_en_sig   <= '1';
		else
			status_ram_rd_en_sig   <= '0';
		end if;
		
    end if;
  end process;
  
  empty_rst <= rst or timeout_rst;
  Pstprc_Fifo_inst : Pstprc_Fifo
  PORT MAP (
    rst => rst,
    wr_clk => Pstprc_fifo_rd_clk,
    rd_clk => Pstprc_fifo_rd_clk,
    din => fifo2_din,
    wr_en =>fifo2_wr_en,
    rd_en =>Pstprc_fifo_rden,
    -- prog_empty_thresh => prog_empty_thresh,
    dout => dout,
    full => open,
    prog_full => prog_full,
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
  
  --发送fifo有数据，而网络长时间没有响应时，清空这个fifo，否则可能出现死锁
  timeout_ps: process (Pstprc_fifo_rd_clk) is
  begin  -- process empty_rst_ps
    if Pstprc_fifo_rd_clk'event and Pstprc_fifo_rd_clk = '1' then  -- rising clock edge
      if empty='0' and tx_rdy ='1' then
        timeout_rst_cnt <= timeout_rst_cnt + '1';
      else
        timeout_rst_cnt	<= (others => '0');
      end if;
		
		if timeout_rst_cnt(23) = '1' then
			timeout_rst <= '1';
		else
			timeout_rst <= '0';
		end if;
    end if;
  end process timeout_ps;
end Behavioral;

