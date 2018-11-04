----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:57:41 12/07/2016 
-- Design Name: 
-- Module Name:    TRIG - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;
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

entity TRIG_ctrl is
  port (
    clk :in std_logic;
    CLK_125M :in std_logic;
    -- clk_adc : in std_logic;
    rst_n : in std_logic;
    cmd_smpl_en : in std_logic;
    cmd_smpl_trig_cnt : in std_logic_vector(23 downto 0);
    ram_start : in std_logic;           --force trig from ethernet
	 
	 trig_recv_cnt : out std_logic_vector(23 downto 0);
	 
    SRCC1_p_trigin : in std_logic;
    trig_recv_done : out std_logic;
    SRCC1_p_trigout : out std_logic;
    posedge_sample_trig_o : out std_logic;
    posedge_sample_trig_o_125M : out std_logic
    );
end TRIG_ctrl;

architecture Behavioral of TRIG_ctrl is
  
  signal trig_250M_lch : std_logic;
  signal trig_125M_trig : std_logic;
  
  signal ram_start_d : std_logic;
  signal ram_start_d2 : std_logic;
  signal trigin_d2 : std_logic;
  signal trigin_d : std_logic;
  signal sample_trig_cnt : std_logic_vector(23 downto 0);
  signal cmd_smpl_en_d : std_logic;
  signal cmd_smpl_en_d2 : std_logic;
  signal sample_en : std_logic;
  signal sample_en_d3 : std_logic;
  signal sample_en_d2 : std_logic;
  signal sample_en_d1 : std_logic;
  signal posedge_sample_trig : std_logic;
  signal posedge_sample_trig_f : std_logic;
  signal posedge_sample_trig_s : std_logic;
  
begin
  posedge_sample_trig_o<=posedge_sample_trig;
   posedge_sample_trig_f_ps: process (CLK, rst_n, ram_start_d, ram_start_d2, trigin_d2, trigin_d,sample_en) is
  begin  -- process posedge_upload_trig_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
     posedge_sample_trig_f<='0';
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      if (ram_start_d = '1' and ram_start_d2='0') or (trigin_d2 ='0' and trigin_d='1' and sample_en='1')  then
      posedge_sample_trig_f<='1';
      else
        posedge_sample_trig_f<='0';
      end if;
    end if;
  end process posedge_sample_trig_f_ps; 
    --重新写ram。
  --敏感命令为：
  -- 1.来自上位机的采数指令ram_start
  -- 2.来自外部触发的采数触发trigin

  sample_trig_cnt_ps: process (CLK, rst_n) is
  begin  -- process sample_trig_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      sample_trig_cnt<=x"0007d0";
		trig_recv_cnt  <= (others => '0');
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      if sample_en ='1' then
        if posedge_sample_trig_f='1' then  --为了缩短逻辑响应时间，就不用上升沿判断了。这里的trig一定要只有一个周期长度才行。所以上位机的命令触发也会被算入其中。
          sample_trig_cnt<=sample_trig_cnt+1;
        end if;
		  trig_recv_cnt <= sample_trig_cnt;
      elsif sample_en ='0' then
        sample_trig_cnt<=(others => '0');
      end if;
    end if;
  end process sample_trig_cnt_ps;
  -- sample_en置高后，每一个触发的上升沿记一次数。直到sample_en拉低，清零。
  
  sample_en_ps: process (CLK, rst_n) is
  begin  -- process sample_en_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      sample_en<='0';
    elsif CLK'event and CLK = '1' then  -- rising clock edge
      if sample_trig_cnt >=cmd_smpl_trig_cnt then   --2000个posedge_sample_trig
        sample_en<='0';
      elsif cmd_smpl_en_d ='1' and cmd_smpl_en_d2='0' then
        sample_en<='1';
      end if;
    end if;
  end process sample_en_ps;
--从上位机接受到命令并且解析出来后3个周期后 sample_en拉高。
-------------------------------------------------------------------------------  
   cmd_smpl_en_d_ps: process (CLK, rst_n) is
  begin  -- process cmd_smpl_en_d_ps
    if CLK'event and CLK = '1' then  -- rising clock edge
      cmd_smpl_en_d<=cmd_smpl_en;
      cmd_smpl_en_d2<=cmd_smpl_en_d;
    end if;
  end process cmd_smpl_en_d_ps;

  ram_start_d_ps: process (CLK) is
  begin  -- process ram_start_d_ps
    if CLK'event and CLK = '1' then  -- rising clock edge
      ram_start_d<=ram_start;
      ram_start_d2<=ram_start_d;
    end if;
  end process ram_start_d_ps;

    SRCC1_p_trigin_d_ps: process (CLK) is
  begin  -- process SRCC1_p_trigin_d_ps
    if CLK'event and CLK = '1' then  -- rising clock edge
       trigin_d<=SRCC1_p_trigin;
       trigin_d2<=trigin_d;
    end if;
  end process SRCC1_p_trigin_d_ps;
  
  

 posedge_sample_trig_ps: process (CLK) is
  begin  -- process SRCC1_p_trigin_d_ps
    if CLK'event and CLK = '1' then  -- rising clock edge
       posedge_sample_trig_s<=posedge_sample_trig_f;
    end if;
  end process  posedge_sample_trig_ps;

  posedge_sample_trig <= posedge_sample_trig_s or posedge_sample_trig_f;
  
  process (CLK) is
  begin  -- process SRCC1_p_trigin_d_ps
    if CLK'event and CLK = '1' then  -- rising clock edge
       if(posedge_sample_trig_f = '1') then
			trig_250M_lch	<= '1';
		 elsif trig_125M_trig = '1' then
		   trig_250M_lch	<= '0';
		 end if;
    end if;
  end process;
  SRCC1_p_trigout<=trigin_d2;
  posedge_sample_trig_o_125M	<= posedge_sample_trig_s or posedge_sample_trig_f;
--  posedge_sample_trig_o_125M	<= trig_125M_trig;
--  SRCC1_p_trigout	<= trig_125M_trig;
  process (CLK_125M) is
  begin  -- process SRCC1_p_trigin_d_ps
    if CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
       sample_en_d1	<= sample_en;
       sample_en_d2	<= sample_en_d1;
       sample_en_d3	<= sample_en_d2;
       trig_recv_done	<= sample_en_d3 and not sample_en_d2;
    end if;
  end process;

  process (CLK_125M) is
  begin  -- process SRCC1_p_trigin_d_ps
    if CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
       trig_125M_trig	<= trig_250M_lch;
    end if;
  end process;
  --    upload_trig_ethernet_d_ps: process (CLK, rst_n) isA
  -- begin  -- process trig_in_ps
  --   if rst_n = '0' then                 -- asynchronous reset (active low)
  --     upload_trig_ethernet_d<='0';
  --     upload_trig_ethernet_d2<='0';
  --   elsif CLK'event and CLK = '1' then  -- rising clock edge
  --     upload_trig_ethernet_d<=upload_trig_ethernet;
  --     upload_trig_ethernet_d2<=upload_trig_ethernet_d;
  --   end if;
  -- end process upload_trig_ethernet_d_ps;
  
  --   SRCC1_n_upload_sma_trigin_d_ps: process (CLK, rst_n) is
  -- begin  -- process trig_in_ps
  --   if rst_n = '0' then                 -- asynchronous reset (active low)
  --     SRCC1_n_upload_sma_trigin_d<='0';
  --     SRCC1_n_upload_sma_trigin_d2<='0';
  --   elsif CLK'event and CLK = '1' then  -- rising clock edge
  --     SRCC1_n_upload_sma_trigin_d<=SRCC1_n_upload_sma_trigin;
  --     SRCC1_n_upload_sma_trigin_d2<=SRCC1_n_upload_sma_trigin_d;
  --   end if;
  -- end process SRCC1_n_upload_sma_trigin_d_ps;
  
end Behavioral;

