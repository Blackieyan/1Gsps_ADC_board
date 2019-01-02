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
  ---DDS的控制设计
  ---使能信号的上升沿到来时，数据已经配置进DDS，所以在上升沿到来，使能CE， sclr置高一个周期使DDS按设定的相位开始输出
  ---在rdy信号为高时DDS数据才输出到端口，此时数据才可以写入RAM
  -- 写入前一段0【可选的】
  ---计数RDY有效数，直到软件设置的DDS数据个数达到要求
  -- 写入后一段0【可选的】
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
  generic(
    dds_phase_width : integer := 24;
    dds_output_width : integer :=12
    );
  port(
    dds_clk         : in  std_logic;
    dds_sclr        : in  std_logic;
    dds_en          : in  std_logic;
    dds_phase_shift : in  std_logic_vector(dds_phase_width downto 0);
    -- MSB 1 represents the negetive frequency 0 represents positive frequency
    -- ,default 0
	 
    use_test_IQ_data : in std_logic;
    Pstprc_num_frs : in std_logic;
	 	--- host set DDS ram signal
	 weight_ram_addr 		: in STD_LOGIC_vector(15 downto 0); --上位机设置DDS数据开关
	 weight_ram_data 		: in STD_LOGIC_vector(11 downto 0);  --数据
	 weight_ram_data_en 	: in STD_LOGIC;                     --数据写使能
	 host_set_ram_switch	: in STD_LOGIC;                     --上位机设置DDS数据开关   
	 weight_ram_sel 		: in STD_LOGIC_vector(3 downto 0); --通道选择
	 ---
    cos_I_x_out         : out std_logic_vector(dds_output_width*8-1 downto 0);
    sin_Q_x_out         : out std_logic_vector(dds_output_width*8-1 downto 0);
    cos_Q_x_out         : out std_logic_vector(dds_output_width*8-1 downto 0);
    sin_I_x_out         : out std_logic_vector(dds_output_width*8-1 downto 0);
    dds_data_start : in std_logic_vector(14 downto 0);
    dds_data_len : in std_logic_vector(14 downto 0);
    cmd_smpl_depth : in std_logic_vector(15 downto 0)
    );
end DDS_top;

architecture Behavioral of DDS_top is
  
--  signal dds_reg_select     : std_logic;
  signal dds_ram_wren_zero_pre_d1             : std_logic;
  signal dds_ram_wren_zero_pre             : std_logic;
  signal dds_ram_wren_zero_end_d1             : std_logic;
  signal dds_ram_wren_zero_end             : std_logic;
  signal Pstprc_num_frs_d1             : std_logic;
  signal dds_sclr_int             : std_logic;
  signal dds_ce             : std_logic;
  signal dds_rdy_d1          : std_logic;
  signal dds_rdy            : std_logic;
  signal dds_rfd            : std_logic;
  signal dds_phase_out      : std_logic_vector(dds_phase_width-1 downto 0);
  signal dds_phase_shift_d  : std_logic_vector(dds_phase_width downto 0);
  signal dds_phase_shift_d2 : std_logic_vector(dds_phase_width downto 0);
  -- signal dps_en_cnt : std_logic_vector(11 downto 0);
  signal dds_ram_write_enable       : std_logic;
  signal dds_ram_wren_d1       : std_logic;
  signal dds_ram_wren       : std_logic;
  signal dds_data_cnt      : std_logic_vector(14 downto 0);
  signal dds_ram_addra      : std_logic_vector(14 downto 0);
  signal dds_ram_addrb      : std_logic_vector(11 downto 0);
  signal dds_cos            : std_logic_vector(dds_output_width-1 downto 0);
--  signal dds_cos_d            : std_logic_vector(dds_output_width-1 downto 0);
  signal dds_sin            : std_logic_vector(dds_output_width-1 downto 0);
  signal dds_ram_rden       : std_logic;
--  signal fifo_cos    : std_logic_vector(dds_output_width*8-1 downto 0);
--  signal fifo_sin    : std_logic_vector(dds_output_width*8-1 downto 0);
  signal finish_sclr : std_logic;
  signal wren_finish_d  : std_logic;
  signal wren_finish  : std_logic;
  signal dds_ram_wren_d : std_logic_vector(0 downto 0);
  signal ram_data_sw : std_logic;
  signal dds_sin_mux_out : std_logic_vector(dds_output_width-1 downto 0);
  signal dds_cos_mux_out : std_logic_vector(dds_output_width-1 downto 0);
--  signal pstprc_en_d : std_logic;
--  signal dds_rdy2            : std_logic;
--  signal dds_rfd2            : std_logic;
--  signal dds_phase_out2      : std_logic_vector(dds_phase_width-1 downto 0);
  signal dds_cos_out: std_logic_vector(dds_output_width-1 downto 0);
  signal dds_sin_out : std_logic_vector(dds_output_width-1 downto 0);
  
  ---------- for host switch
  signal dds_ram_ena_I_x_sin       : std_logic;
  signal dds_ram_ena_Q_x_cos       : std_logic;
  signal dds_ram_ena_Q_x_sin       : std_logic;
  signal dds_ram_ena_I_x_cos       : std_logic;
  signal dds_ram_wren_I_x_sin      : std_logic_vector(0 downto 0);
  signal dds_ram_wren_Q_x_cos      : std_logic_vector(0 downto 0);
  signal dds_ram_wren_Q_x_sin      : std_logic_vector(0 downto 0);
  signal dds_ram_wren_I_x_cos      : std_logic_vector(0 downto 0);
  signal dds_ram_addra_I_x_sin     : std_logic_vector(14 downto 0);
  signal dds_ram_addra_Q_x_cos     : std_logic_vector(14 downto 0);
  signal dds_ram_addra_Q_x_sin     : std_logic_vector(14 downto 0);
  signal dds_ram_addra_I_x_cos     : std_logic_vector(14 downto 0);
  signal dds_ram_dataa_I_x_sin 	 : std_logic_vector(dds_output_width-1 downto 0);
  signal dds_ram_dataa_Q_x_cos 	 : std_logic_vector(dds_output_width-1 downto 0);
  signal dds_ram_dataa_Q_x_sin 	 : std_logic_vector(dds_output_width-1 downto 0);
  signal dds_ram_dataa_I_x_cos 	 : std_logic_vector(dds_output_width-1 downto 0);
  
  signal cos_I_x         : std_logic_vector(dds_output_width*8-1 downto 0);
  signal sin_Q_x         : std_logic_vector(dds_output_width*8-1 downto 0);
  signal cos_Q_x         : std_logic_vector(dds_output_width*8-1 downto 0);
  signal sin_I_x         : std_logic_vector(dds_output_width*8-1 downto 0);
  
  signal dds1_sclr : std_logic;
  component DDS1
    port (
      reg_select : in  std_logic;
      clk        : in  std_logic;
      sclr       : in  std_logic;
      we         : in  std_logic;
      ce         : in  std_logic;
      data       : in  std_logic_vector(dds_phase_width-1 downto 0);
      rdy        : out std_logic;
      rfd        : out std_logic;
      cosine     : out std_logic_vector(dds_output_width-1 downto 0);
      sine       : out std_logic_vector(dds_output_width-1 downto 0);
      phase_out  : out std_logic_vector(dds_phase_width-1 downto 0));
  end component;

  component DDS2
	port (
	reg_select: in std_logic;
	ce: in std_logic;
	clk: in std_logic;
	sclr: in std_logic;
	we: in std_logic;
	data: in std_logic_vector(dds_phase_width-1 downto 0);
	rdy: out std_logic;
	rfd: out std_logic;
	sine: out std_logic_vector(dds_output_width-1 downto 0);
	phase_out: out std_logic_vector(dds_phase_width-1 downto 0));
end component;

  component dds_ram
    port (
      clka  : in  std_logic;
      ena   : in  std_logic;
      wea   : in  std_logic_vector(0 downto 0);
      addra : in  std_logic_vector(14 downto 0);
      dina  : in  std_logic_vector(dds_output_width-1 downto 0);
      clkb  : in  std_logic;
      enb   : in  std_logic;
      addrb : in  std_logic_vector(dds_output_width-1 downto 0);
      doutb : out std_logic_vector(dds_output_width*8-1 downto 0)
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


  
begin

  DDS_inst : DDS1
    port map (
      reg_select => '0',
      clk        => dds_clk,
      sclr       => dds_sclr_int,
      we         => '1',
      ce         => dds_ce,             --pull up from the (demoWinstart -2)
      data       => dds_phase_shift(dds_phase_width-1 downto 0),    --fout = clk*data/2^N
      rdy        => dds_rdy,
      rfd        => dds_rfd,
      cosine     => dds_cos_out,
      sine       => dds_sin_out,
      phase_out  => dds_phase_out);
dds1_sclr<=dds_sclr or finish_sclr;
  

--  sin_ram_inst : dds_ram
--    port map (
--      clka  => dds_clk,
--      ena   => '1',
--      wea   => dds_ram_wren,
--      addra => dds_data_cnt,
--      dina  => dds_sin_mux_out,
--      clkb  => dds_clk,
--      enb   => dds_ram_rden,
--      addrb => dds_ram_addrb,
--      doutb => sin_out
--      );
--
--  cos_ram_inst : dds_ram
--    port map (
--      clka  => dds_clk,
--      ena   => '1',
--      wea   => dds_ram_wren,
--      addra => dds_data_cnt,
--      dina  => dds_cos_mux_out,
--      clkb  => dds_clk,
--      enb   => dds_ram_rden,
--      addrb => dds_ram_addrb,
--      doutb => cos_out
--      );
      
 weight_sin_I_x_ram_inst : dds_ram
    port map (
      clka  => dds_clk,
      ena   => dds_ram_ena_I_x_sin,
      wea   => dds_ram_wren_I_x_sin,
      addra => dds_ram_addra_I_x_sin,
      dina  => dds_ram_dataa_I_x_sin,
      clkb  => dds_clk,
      enb   => dds_ram_rden,
      addrb => dds_ram_addrb,
      doutb => sin_I_x
      );  
      
    weight_cos_I_x_ram_inst : dds_ram
    port map (
      clka  => dds_clk,
      ena   => dds_ram_ena_I_x_cos,
      wea   => dds_ram_wren_I_x_cos,
      addra => dds_ram_addra_I_x_cos,
      dina  => dds_ram_dataa_I_x_cos,
      clkb  => dds_clk,
      enb   => dds_ram_rden,
      addrb => dds_ram_addrb,
      doutb => cos_I_x
      );

    weight_sin_Q_x_ram_inst : dds_ram
    port map (
      clka  => dds_clk,
      ena   => dds_ram_ena_Q_x_sin,
      wea   => dds_ram_wren_Q_x_sin,
      addra => dds_ram_addra_Q_x_sin,
      dina  => dds_ram_dataa_Q_x_sin,
      clkb  => dds_clk,
      enb   => dds_ram_rden,
      addrb => dds_ram_addrb,
      doutb => sin_Q_x
      );  
      
    weight_cos_Q_x_ram_inst : dds_ram
    port map (
      clka  => dds_clk,
      ena   => dds_ram_ena_Q_x_cos,
      wea   => dds_ram_wren_Q_x_cos,
      addra => dds_ram_addra_Q_x_cos,
      dina  => dds_ram_dataa_Q_x_cos,
      clkb  => dds_clk,
      enb   => dds_ram_rden,
      addrb => dds_ram_addrb,
      doutb => cos_Q_x
      ); 
		
  dds_ram_rden <= dds_en;               --control by module input signal 
  
   dds_ram_ena_I_x_sin <= weight_ram_sel(0) when host_set_ram_switch = '1' else '1';
	dds_ram_ena_I_x_cos <= weight_ram_sel(1) when host_set_ram_switch = '1' else '1';
	dds_ram_ena_Q_x_sin <= weight_ram_sel(2) when host_set_ram_switch = '1' else '1';
	dds_ram_ena_Q_x_cos <= weight_ram_sel(3) when host_set_ram_switch = '1' else '1';
	dds_ram_wren_I_x_sin(0) <= weight_ram_data_en when host_set_ram_switch = '1' else dds_ram_write_enable;
	dds_ram_wren_I_x_cos(0) <= weight_ram_data_en when host_set_ram_switch = '1' else dds_ram_write_enable;
	dds_ram_wren_Q_x_sin(0) <= weight_ram_data_en when host_set_ram_switch = '1' else dds_ram_write_enable;
	dds_ram_wren_Q_x_cos(0) <= weight_ram_data_en when host_set_ram_switch = '1' else dds_ram_write_enable;
	dds_ram_addra_I_x_sin <= weight_ram_addr(14 downto 0) when host_set_ram_switch = '1' else dds_ram_addra;
	dds_ram_addra_I_x_cos <= weight_ram_addr(14 downto 0) when host_set_ram_switch = '1' else dds_ram_addra;
	dds_ram_addra_Q_x_sin <= weight_ram_addr(14 downto 0) when host_set_ram_switch = '1' else dds_ram_addra;
	dds_ram_addra_Q_x_cos <= weight_ram_addr(14 downto 0) when host_set_ram_switch = '1' else dds_ram_addra;
	dds_ram_dataa_I_x_sin <= weight_ram_data when host_set_ram_switch = '1' else dds_sin_mux_out;
	dds_ram_dataa_I_x_cos <= weight_ram_data when host_set_ram_switch = '1' else dds_cos_mux_out;
	dds_ram_dataa_Q_x_sin <= weight_ram_data when host_set_ram_switch = '1' else dds_sin_mux_out;
	dds_ram_dataa_Q_x_cos <= weight_ram_data when host_set_ram_switch = '1' else dds_cos_mux_out;
  
  -- 上位机设置通道切换
  cos_I_x_out   <= cos_I_x;-- when host_set_ram_switch = '1' else cos_out;  
  sin_Q_x_out   <= sin_Q_x;-- when host_set_ram_switch = '1' else sin_out;  
  cos_Q_x_out   <= cos_Q_x;-- when host_set_ram_switch = '1' else cos_out;  
  sin_I_x_out   <= sin_I_x;-- when host_set_ram_switch = '1' else sin_out;  
  
  -----------------------------------------------------------------------------
  -- purpose: when the frequency is negetive then switch the dds_sin to neg_sin
  -- type   : sequential
  -- inputs : dds_clk, dds_sclr
  -- outputs: 
  sine_polarity_ps: process (dds_clk, dds_sclr) is
  begin  -- process sine_polarity_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_sin<= (others => '0');
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_phase_shift(dds_phase_width)='1' then
        dds_sin<=not(dds_sin_out)+1;
      else
        dds_sin<=dds_sin_out;
      end if;
    end if;
  end process sine_polarity_ps;
  
  dds_cos_d_ps: process (dds_clk, dds_sclr) is
  begin  -- process dds_cos_d
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_cos<=(others => '0');
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      dds_cos<=dds_cos_out;
    end if;
  end process dds_cos_d_ps; 
  
data_switch_ps: process (dds_clk, dds_sclr) is
 begin  -- process data_switch_ps
  if dds_sclr = '1' then                -- asynchronous reset (active low)
    dds_sin_mux_out<=(others => '0');
    dds_cos_mux_out<=(others => '0');
  elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
  ---加入测试模式数据
    if(use_test_IQ_data = '1') then
		 dds_sin_mux_out<= dds_data_cnt(11 downto 0);
		 dds_cos_mux_out<= dds_data_cnt(11 downto 0);
	 elsif dds_ram_wren = '1' then
		-- dds_ram_wren比rdy晚一个周期，dds_cos比dds_cos_out晚一个周期，所以dds_ram_wren正好与dds_sin对齐
		-- dds ram写有效信号还要比dds_ram_wren晚一个周期
		dds_sin_mux_out<= dds_sin;
		dds_cos_mux_out<= dds_cos;
	 else
		dds_cos_mux_out<=(others => '0');
		dds_sin_mux_out<=(others => '0');
	  end if;
  end if;
end process data_switch_ps;

  --real_ram_write addr
  process (dds_clk) is
  begin
    if dds_clk'event and dds_clk = '1' then  -- rising clock edge
      dds_rdy_d1<=dds_rdy ;
      Pstprc_num_frs_d1<=Pstprc_num_frs;
      dds_ram_write_enable<=dds_ram_wren or dds_ram_wren_zero_pre or dds_ram_wren_zero_end;
      dds_ram_wren_d1<=dds_ram_wren;
      dds_ram_wren_zero_pre_d1<=dds_ram_wren_zero_pre;
      dds_ram_wren_zero_end_d1<=dds_ram_wren_zero_end;
    end if;
  end process;   
    --real_ram_write data
  process (dds_clk) is
  begin
    if dds_clk'event and dds_clk = '1' then  -- rising clock edge
	  if(Pstprc_num_frs = '1' and Pstprc_num_frs_d1 = '0')then
		dds_ram_addra <= (others => '0');
	  elsif(dds_ram_write_enable = '1') then
		dds_ram_addra <= dds_ram_addra + '1';
	  end if;
    end if;
  end process; 

-- purpose: generate dps_en to prepare the dps data with a ram and control the
-- dds output at the same time
-- type   : sequential
-- inputs : dds_clk, dds_sclr
-- outputs: 
  --rdy 上升沿数据使能
  --- 写地址到达设定深度，数据写禁止
  --- 先写入dds_data_start个0
  ---- 后写入有效的dds数据
  ---- 最后写入尾部的0
  
  --第一段 写入前面的0
  dds_ram_wren_pre_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_ram_wren_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_wren_zero_pre <= '0';              --write ram after reset and power on
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if(Pstprc_num_frs = '1' and Pstprc_num_frs_d1 = '0' and dds_data_start > 0) then
		--上升沿到来，写ram使能,写0
		dds_ram_wren_zero_pre <= '1';
	  elsif(dds_data_cnt = dds_data_start) then
		dds_ram_wren_zero_pre <= '0';
      end if;
    end if;
  end process dds_ram_wren_pre_ps;
  
  --第二段 写入中间的dds数据
  dds_ram_wren_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_ram_wren_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_wren <= '0';              --write ram after reset and power on
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_rdy ='1' and dds_rdy_d1 ='0' then
        dds_ram_wren <= '1';
      elsif dds_data_cnt =  dds_data_start + dds_data_len  then         --smpl_depth +1
        dds_ram_wren <= '0';
      end if;
    end if;
  end process dds_ram_wren_ps;
  
    --第三段 写入后面的0
  dds_ram_wren_end_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_ram_wren_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_wren_zero_end <= '0';              --write ram after reset and power on
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_data_cnt >=  cmd_smpl_depth  then         --smpl_depth +1
        dds_ram_wren_zero_end <= '0';
      elsif dds_ram_wren ='0' and dds_ram_wren_d1 ='1' then
        dds_ram_wren_zero_end <= '1';
      end if;
    end if;
  end process dds_ram_wren_end_ps;

--  wren_finish_ps : process (dds_clk, dds_sclr) is
--  begin  -- process         finish_sclr_ps
--    if dds_sclr = '1' then              -- asynchronous reset (active low)
--      wren_finish <= '0';
--    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
--      if dds_ram_wren = '0' and dds_ram_wren_d = '1' then
--        wren_finish <= '1';
--      else
--        wren_finish <= '0';
--      end if;
--    end if;
--  end process wren_finish_ps;
  
  --地址比dds_ram_wren
  dds_ram_addra_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_ram_addra_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_data_cnt <= (0=>'1', others => '0');
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if Pstprc_num_frs = '1' and Pstprc_num_frs_d1 = '0' then
        dds_data_cnt <= (0=>'1', others => '0');   -- Because the data on x"000" is all zero. 
      elsif dds_ram_wren = '1' or dds_ram_wren_zero_pre = '1' or dds_ram_wren_zero_end = '1' then
        dds_data_cnt <= dds_data_cnt+1;
      end if;
    end if;
  end process dds_ram_addra_ps;  --actually cnt 4091
  

  dds_ce_ps: process (dds_clk, dds_sclr) is
  begin  -- process dds_ce_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ce<='0';
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if Pstprc_num_frs = '1' and Pstprc_num_frs_d1 = '0' and dds_data_start = 0 then  --start must equal larger than "5"
        dds_ce<='1';
	  elsif(dds_ram_wren_zero_pre = '0' and dds_ram_wren_zero_pre_d1 = '1') then
		dds_ce<='1';
      elsif dds_data_cnt = dds_data_start+dds_data_len then  --remain to be fixed
        dds_ce<='0';
      end if;
    end if;
  end process dds_ce_ps;
  
  dds_sclr_ps: process (dds_clk, dds_sclr) is
  begin  -- process dds_ce_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_sclr_int <= '0';
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if Pstprc_num_frs = '1' and Pstprc_num_frs_d1 = '0' and dds_data_start = 0 then  --start must equal larger than "5"
        dds_sclr_int<='1';
	  elsif(dds_ram_wren_zero_pre = '0' and dds_ram_wren_zero_pre_d1 = '1') then
		dds_sclr_int<='1';
      else
        dds_sclr_int<='0';
      end if;
    end if;
  end process dds_sclr_ps;
  -- ram_data_sw_ps: process (dds_clk, dds_sclr) is
  -- begin  -- process ram_data_sw_ps
    -- if dds_sclr = '1' then              -- asynchronous reset (active low)
      -- ram_data_sw<='0';
    -- elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      -- if dds_data_cnt = dds_data_start-2 then  --start must equal larger than "4"
        -- ram_data_sw<='1';
      -- elsif dds_data_cnt= dds_data_start+dds_data_len-1 then  --remain to be fixed
        -- ram_data_sw<='0';
      -- end if;
    -- end if;
  -- end process ram_data_sw_ps;

  dds_ram_addrb_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_dds_ram_addrb_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_addrb <= (others => '0');
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_ram_rden = '0' then
        dds_ram_addrb <= (others => '0');
      elsif dds_ram_rden = '1' then
        dds_ram_addrb <= dds_ram_addrb+1;
      end if;
    end if;
  end process dds_ram_addrb_ps;  --actually cnt 4091
--
--  dds_phase_shift_d_ps : process (dds_clk, dds_sclr) is
--  begin  -- process dds_phase_shift_d_ps
--    if dds_sclr = '1' then              -- asynchronous reset (active low)
--      dds_phase_shift_d  <= (others => '0');
--      dds_phase_shift_d2 <= (others => '0');
--    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
--      dds_phase_shift_d  <= dds_phase_shift;
--      dds_phase_shift_d2 <= dds_phase_shift_d;
--    end if;
--  end process dds_phase_shift_d_ps;

--  dds_ram_wren_d_ps : process (dds_clk, dds_sclr) is
--  begin  -- process dds_ram_wren_d_ps
--    if dds_sclr = '1' then              -- asynchronous reset (active low)
--      dds_ram_wren_d  <= (others => '0');
--      wren_finish_d <='0';
--    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
--      dds_ram_wren_d  <= dds_ram_wren;
--      wren_finish_d <= wren_finish;
--    end if;
--  end process dds_ram_wren_d_ps;
  
--  finish_sclr<=wren_finish or wren_finish_d;
  

  
end Behavioral;

