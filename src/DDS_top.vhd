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
  signal dds_ce             : std_logic;
  signal dds_rdy            : std_logic;
  signal dds_rfd            : std_logic;
  signal dds_phase_out      : std_logic_vector(dds_phase_width-1 downto 0);
  signal dds_phase_shift_d  : std_logic_vector(dds_phase_width downto 0);
  signal dds_phase_shift_d2 : std_logic_vector(dds_phase_width downto 0);
  -- signal dps_en_cnt : std_logic_vector(11 downto 0);
  signal dds_ram_wren       : std_logic_vector(0 downto 0);
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
      sclr       => dds1_sclr,
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
--      addra => dds_ram_addra,
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
--      addra => dds_ram_addra,
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
	dds_ram_wren_I_x_sin(0) <= weight_ram_data_en when host_set_ram_switch = '1' else dds_ram_wren(0);
	dds_ram_wren_I_x_cos(0) <= weight_ram_data_en when host_set_ram_switch = '1' else dds_ram_wren(0);
	dds_ram_wren_Q_x_sin(0) <= weight_ram_data_en when host_set_ram_switch = '1' else dds_ram_wren(0);
	dds_ram_wren_Q_x_cos(0) <= weight_ram_data_en when host_set_ram_switch = '1' else dds_ram_wren(0);
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
		 dds_sin_mux_out<= dds_ram_addra(11 downto 0);
		 dds_cos_mux_out<= dds_ram_addrb(11 downto 0);
	 else
		 case ram_data_sw is
			when '0' =>
			  dds_cos_mux_out<=(others => '0');
			  dds_sin_mux_out<=(others => '0');
			when '1' =>
			  dds_sin_mux_out<= dds_sin;
			  dds_cos_mux_out<= dds_cos;
			when others => null;
		 end case;
	  end if;
  end if;
end process data_switch_ps;

-- purpose: generate dps_en to prepare the dps data with a ram and control the
-- dds output at the same time
-- type   : sequential
-- inputs : dds_clk, dds_sclr
-- outputs: 
  dds_ram_wren_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_ram_wren_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_wren <= "1";              --write ram after reset and power on
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if Pstprc_num_frs ='1' then
        dds_ram_wren <= "1";
      elsif dds_ram_addra =  cmd_smpl_depth(14 downto 0) then         --smpl_depth +1
        dds_ram_wren <= "0";
      end if;
    end if;
  end process dds_ram_wren_ps;

  wren_finish_ps : process (dds_clk, dds_sclr) is
  begin  -- process         finish_sclr_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      wren_finish <= '0';
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_ram_wren = "0" and dds_ram_wren_d = "1" then
        wren_finish <= '1';
      else
        wren_finish <= '0';
      end if;
    end if;
  end process wren_finish_ps;

  dds_ram_addra_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_ram_addra_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_addra <= (others => '0');
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_ram_wren = "0" then
        dds_ram_addra <= (others => '0');        -- Because the data on x"000" is all zero. 
      elsif dds_ram_wren = "1" then
        dds_ram_addra <= dds_ram_addra+1;
      end if;
    end if;
  end process dds_ram_addra_ps;  --actually cnt 4091

  dds_ce_ps: process (dds_clk, dds_sclr) is
  begin  -- process dds_ce_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ce<='0';
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_ram_addra = dds_data_start-4 then  --start must equal larger than "5"
        dds_ce<='1';
      elsif dds_ram_addra= dds_data_start+dds_data_len-1 then  --remain to be fixed
        dds_ce<='0';
      end if;
    end if;
  end process dds_ce_ps;

  ram_data_sw_ps: process (dds_clk, dds_sclr) is
  begin  -- process ram_data_sw_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      ram_data_sw<='0';
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      if dds_ram_addra = dds_data_start-2 then  --start must equal larger than "4"
        ram_data_sw<='1';
      elsif dds_ram_addra= dds_data_start+dds_data_len-1 then  --remain to be fixed
        ram_data_sw<='0';
      end if;
    end if;
  end process ram_data_sw_ps;

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

  dds_phase_shift_d_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_phase_shift_d_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_phase_shift_d  <= (others => '0');
      dds_phase_shift_d2 <= (others => '0');
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      dds_phase_shift_d  <= dds_phase_shift;
      dds_phase_shift_d2 <= dds_phase_shift_d;
    end if;
  end process dds_phase_shift_d_ps;

  dds_ram_wren_d_ps : process (dds_clk, dds_sclr) is
  begin  -- process dds_ram_wren_d_ps
    if dds_sclr = '1' then              -- asynchronous reset (active low)
      dds_ram_wren_d  <= (others => '0');
      wren_finish_d <='0';
    elsif dds_clk'event and dds_clk = '1' then  -- rising clock edge
      dds_ram_wren_d  <= dds_ram_wren;
      wren_finish_d <= wren_finish;
    end if;
  end process dds_ram_wren_d_ps;
  
  finish_sclr<=wren_finish or wren_finish_d;
  
end Behavioral;

