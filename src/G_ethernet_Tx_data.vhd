----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:14:37 03/09/2016 
-- Design Name: 
-- Module Name:    G_ethernet_Tx_data - Behavioral 
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
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity G_ethernet_Tx_data is
  port (
    clk_125m :in std_logic;
    clk_125m_quar : in std_logic;
    rst_n_gb_i      : in  std_logic;
    PHY_TXD_o       : out std_logic_vector(3 downto 0);
    PHY_GTXclk_quar : out std_logic;
    phy_txen_quar   : out std_logic;
    phy_txer_o      : out std_logic;
    user_pushbutton : in  std_logic;
    rst_n_o         : out std_logic;    --for test,generate from Gcnt
    fifo_upload_data : in std_logic_vector(7 downto 0);
    ram_wren : buffer std_logic;
    ram_rden : out std_logic;
    ram_start : in std_logic;
    srcc1_p_trigin : in std_logic;
    SRCC1_n_upload_sma_trigin : in std_logic;
    upload_trig_ethernet : in std_logic;
    ram_last : in std_logic;
    posedge_upload_trig : in std_logic
    );
end G_ethernet_Tx_data;

architecture Behavioral of G_ethernet_Tx_data is
  type state_type is (ini_state,header_state,addr_state,frame_num_state1,frame_num_state2,data_state,end_state);
  signal current_state : state_type;
  signal next_state : state_type;
  attribute keep             : boolean;
  signal Busy                : std_logic:='0';
  signal Data_Strobe         : std_logic:='0';
  signal data_in             : std_logic_vector(7 downto 0):=x"00";
  signal wr_addr             : std_logic_vector(15 downto 0)  := x"0000";
  signal wr_data             : std_logic_vector(7 downto 0):=x"00";
  signal CLK_250M            : std_logic;
  attribute keep of CLK_250M : signal is true;
  signal Trig_i              : std_logic;
  signal last_byte           : std_logic;
  signal phy_txen_o          : std_logic;
-------------------------------------------------------------------------------
  signal rst_n               : std_logic;
  signal Gcnt                : std_logic_vector(11 downto 0) := x"000";
  signal clk_div_cnt         : std_logic_vector(7 downto 0):=x"00";
  signal GCLK                : std_logic;
  signal Gclk_d              : std_logic;
  signal Gclk_d2             : std_logic;
  signal O_Gcnt              : std_logic_vector(7 downto 0):=x"00";
  signal PHY_GTXCLK_o        : std_logic;
  constant Div_multi         : std_logic_vector(3 downto 0)  := "1010";
-------------------------------------------------------------------------------
  -- signal ram_wren : std_logic;
  signal fifo_upload_wren : std_logic;
  signal frame_num_en : std_logic;
  signal frame_cnt : std_logic_vector(15 downto 0);
  signal frame_cnt_cnt : std_logic_vector(0 downto 0);
  signal addr_en : std_logic;
  signal wait_frame : std_logic;
  signal header_cnt : integer range 0 to 255;
  signal  addr_cnt : integer range 0 to 255;
  signal data_ready : std_logic;
  signal data_test : std_logic_vector(7 downto 0);
  signal ram_start_cnt : std_logic_vector(11 downto 0);
  -- signal ram_start : std_logic;
  signal ram_start_d : std_logic;
  signal ram_start_d2 : std_logic;
  signal wren_reset : std_logic;
  signal wren_ethernet : std_logic;
  signal trigin_d : std_logic;
  signal trigin_d2 : std_logic;
  signal trigin_cnt : std_logic_vector(11 downto 0);
  signal wren_trigin : std_logic;
  signal upload_trig_ethernet_d : std_logic;
  signal upload_trig_ethernet_d2 : std_logic;
  signal SRCC1_n_upload_sma_trigin_d : std_logic;
  signal SRCC1_n_upload_sma_trigin_d2 : std_logic;
  signal ram_wren_d : std_logic;
  signal ram_wren_d2 : std_logic;
  signal upload_sma_trigin : std_logic;
  signal upload_sma_trigin_cnt : std_logic_vector(3 downto 0);
  signal upload_ethernet_trigin : std_logic;
  signal upload_ethernet_trigin_cnt : std_logic_vector(3 downto 0);
  signal upload_wren_trigin : std_logic;
  signal upload_wren_trigin_cnt : std_logic_vector(3 downto 0);
  signal busy_d : std_logic;
  signal busy_d2 : std_logic;
  signal trig_i_cnt : std_logic_vector(3 downto 0);
  signal frame_gap_cnt : std_logic_vector(12 downto 0);
  signal frame_gap : std_logic;
  signal frame_gap_d : std_logic;
  signal frame_gap_d2 : std_logic;
-------------------------------------------------------------------------------
  type array_header is array (7 downto 0) of std_logic_vector(7 downto 0);
  constant header : array_header := (x"d5",x"55",x"55",x"55",x"55",x"55",x"55",x"55");

  -- constant header(0) :=x"55";
  -- constant header(1) :=x"55";
  -- constant header(2) :=x"55";
  -- constant header(3) :=x"55";
  -- constant header(4) :=x"55";
  -- constant header(5) :=x"55";
  -- constant header(6) :=x"55";
  -- constant header(7) :=x"d5";
-------------------------------------------------------------------------------
 type array_address is array (13 downto 0) of std_logic_vector(7 downto 0);
   constant address : array_address := (x"55",x"AA",x"00",x"00",x"00",x"00",x"00",x"00",x"40",x"73",x"31",x"4C",x"A4",x"60");
  -- constant address : array_address := (x"0c",x"00",x"86",x"B1",x"00",x"67",x"10",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff");
      -- constant address : array_address := (x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");--能够点对点正常使用
  -- constant address(0) :std_logic_vector(7 downto 0):=x"ff";          --destination address
  --  constant address(1) :std_logic_vector(7 downto 0):=x"ff"; 
  --  constant address(2) :std_logic_vector(7 downto 0):=x"ff"; 
  --  constant address(3) :std_logic_vector(7 downto 0):=x"ff";
  --  constant address(4) :std_logic_vector(7 downto 0):=x"ff";
  --  constant address(5) :std_logic_vector(7 downto 0):=x"ff";
  
  --  constant address(6) :std_logic_vector(7 downto 0):=x"00";  --source address
  --  constant address(7) :std_logic_vector(7 downto 0):=x"10";
  --  constant address(8) :std_logic_vector(7 downto 0):=x"67";
  --  constant address(9)  :std_logic_vector(7 downto 0):=x"00";
  --  constant address(10) :std_logic_vector(7 downto 0):=x"B1";
  --  constant address(11) :std_logic_vector(7 downto 0):=x"86";
  
  --  constant address(12) :std_logic_vector(7 downto 0):=x"05";
  --  constant address(13) :std_logic_vector(7 downto 0):=x"04";
  -----------------------------------------------------------------------------
-- signal sending : std_logic;
-- signal TX_byte_cnt : std_logic;
-- signal last_byte_d : std_logic;
-- signal minByteSent : std_logic;
-- signal dataComplete : std_logic;
-- signal end_pulse : std_logic;
-- signal Send_DATA : std_logic;
  component Mac_TX
    port(
      clk          : in  std_logic;
      Reset_i      : in  std_logic;
      Trig_i       : in  std_logic;
      Data_in      : in  std_logic_vector(7 downto 0);
      Last_byte    : in  std_logic;
      Data_Strobe  : out std_logic;
      Busy         : out std_logic;
      PHY_TXEN_o   : out std_logic;
      PHY_GTXCLK_o : out std_logic;
      PHY_TXD_o    : out std_logic_vector(3 downto 0)
      );
  end component;


-------------------------------------------------------------------------------
begin
  phy_GTXclk_quar <= not CLK_125M_quar;
  data_in         <= wr_data;
  phy_txer_o      <= '0';
  rst_n_o         <= rst_n;
  rst_n           <= user_pushbutton;
  phy_txen_quar   <= phy_txen_o;
--  SRCC1_p <= PHY_TXD_o(0);
--  SRCC1_n <= PHY_TXD_o(1);
--  MRCC2_p <= PHY_TXD_o(2);
  -- MRCC2_n         <= CLK_125M;

  Inst_Mac_TX : Mac_TX port map(
    clk          => clk_125M,
    Reset_i      => not rst_n,
    Trig_i       => trig_i,
    Data_in      => data_in,
    Last_byte    => last_byte,
    Data_Strobe  => data_strobe,
    Busy         => busy,
    PHY_TXEN_o   => phy_txen_o,
    PHY_GTXCLK_o => phy_gtxclk_o,
    PHY_TXD_o    => phy_txd_o
    );


-------------------------------------------------------------------------------
  set_clk_div_cnt : process (CLK_125M) is
  begin  -- process set_clk_div_cnt
    -- if rst_n = '0' then                           -- asynchronous reset (active
    --   clk_div_cnt <= x"00";
    if CLK_125m'event and CLK_125m = '1' then  -- rising clock edge
      if clk_div_cnt <= Div_multi then
        clk_div_cnt <= clk_div_cnt+1;
      else
        clk_div_cnt <= x"00";
      end if;
    end if;
  end process set_clk_div_cnt;

  set_ADC_sclk : process (CLK_125M) is
  begin  -- process set_ADC_sclk
    if CLK_125m'event and CLK_125m = '1' then  -- rising clock edge
      if clk_div_cnt <= Div_multi(3 downto 1) then
        GCLK <= '0';
      else
        GCLK <= '1';
      end if;
    end if;
  end process set_ADC_sclk;

  Gclk_d_ps : process (clk_125m, rst_n) is
  begin  -- process Gclk_ps
    if rst_n ='0' then
      gclk_d<='0';
   elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      GCLK_d <= GCLK;
    end if;
  end process Gclk_d_ps;

  Gclk_d2_ps : process (clk_125m, rst_n) is
  begin  -- process Gclk_d2_ps
    if rst_n ='0' then
      gclk_d2<='0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      Gclk_d2 <= GCLK_d;
    end if;
  end process Gclk_d2_ps;

  Gcnt_ps : process (clk_125m, GCLK_d, GCLK_d2, rst_n) is
  begin
        if rst_n ='0' then
      gcnt<=(others => '0');
      elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
    if Gclk_d2 = '0' and Gclk_d = '1' then
    -- elsif GCLK'event and GCLK = '1' then
-- if Gcnt <= x"ffffffff" then
      Gcnt <= Gcnt+1;
    end if;
  end if;
-- end if;
  end process Gcnt_ps;



  O_Gcnt_ps : process (clk_125m, rst_n, GCLK_d, GCLK_d2) is
  begin  -- process O_Gcnt_ps
    if rst_n = '0' then
      O_Gcnt <= (others => '0');
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
    if Gclk_d2 = '0' and Gclk_d = '1' then
    -- elsif GCLK'event and GCLK = '1' then
      if Gcnt = x"ffff" and O_Gcnt <= x"F5" then
        O_Gcnt <= O_Gcnt+1;
      else
        O_Gcnt <= (others => '0');
      end if;
    end if;
  end if;
  end process O_Gcnt_ps;

  ram_start_d_ps: process (CLK_125M) is
  begin  -- process ram_start_d_ps
    if CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      ram_start_d<=ram_start;
    end if;
  end process ram_start_d_ps;
ram_start_d2_ps: process (CLK_125M) is
  begin  -- process ram_start_d_ps
    if CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      ram_start_d2<=ram_start_d;
    end if;
  end process ram_start_d2_ps;
  
-- rst_n_ps : process (GCLK, clk_125m) is
-- begin  -- process rst_n_ps
--   if gclk'event and gclk = '1' then
--     -- if GCLK_d = '0' and GCLK = '1' then  -- rising clock edge
--     if O_Gcnt = x"00" then
--       if Gcnt >= x"000f" and Gcnt <= x"0018" then
--         rst_n <= '0';
--       else
--         rst_n <= '1';
--       end if;
--     end if;
--   -- end if;
--   end if;
-- end process rst_n_ps;
-------------------------------------------------------------------------------
  -- trig_i_ps : process (GCLK, rst_n, clk_125m) is --自动不停地上传帧
  -- begin  -- process trig_i_ps
  --   if rst_n = '0' then                 -- asynchronous reset (active low)
  --     trig_i <= '0';
  --   elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
  --     -- if GCLK_d='0' and GCLK='1' then
  --     if Gcnt = x"0020" then
  --       trig_i <= '1';
  --     else
  --       trig_i <= '0';
  --     end if;
  --   end if;
  -- end process trig_i_ps;
-------------------------------------------------------------------------------
--     wren_reset_ps : process (GCLK, rst_n, clk_125m) is
-- --实际上是trig信号来以后持续100us或者其它。一个trig只持续一次。这里用gcnt会反复出现。但是用not full相与可以避免最终的使能反复。想要清零只能通过复位信号。以后要修改为命令trig下传后执行一次ram_clr
--   begin  -- process trig_i_ps
--     if rst_n = '0' then                 -- asynchronous reset (active low)
--       wren_reset <= '0';
--     elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
--       -- if GCLK_d='0' and GCLK='1' then
--       if Gcnt >= x"AC8" and Gcnt<=x"c68" and O_Gcnt=x"00" then  --为了防止上电马上采样时的抖动 这个数值要够大。
--         wren_reset <= '1';
--       else
--         wren_reset <= '0';
--       end if;
--     end if;
--   end process wren_reset_ps;
  
    ram_start_cnt_ps: process (clk_125m, Gclk_d, Gclk_d2, ram_start) is
  begin  -- process ram_rst_cnt_ps
    if rst_n = '0' then               -- asynchronous reset (active low)
      ram_start_cnt<=(others => '0');
    -- elsif Gclk'event and Gclk = '1' then  -- rising clock edge
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      if wren_ethernet ='0' then
        ram_start_cnt<=(others => '0'); 
      elsif wren_ethernet ='1' then
        if Gclk_d2 = '0' and Gclk_d = '1'  then
      -- if wren_ethernet<='1' then
        ram_start_cnt<=ram_start_cnt+1;
        end if;
      -- end if;
      end if;
    end if;
  end process ram_start_cnt_ps;

  wren_ethernet_ps: process (clk_125m, rst_n, ram_start_d, ram_start_d2) is
  begin  -- process wren_ethernet_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      wren_ethernet<='0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      if ram_start_cnt = x"3e1" then    --数小了似乎ram抓不满，和仿真的不一样。似乎存在bug。
        wren_ethernet<='0';
      elsif ram_start_d='1' and ram_start_d2='0' then
        wren_ethernet<='1';
    end if;
  end if;
  end process wren_ethernet_ps;

    trigin_d_ps: process (CLK_125M, rst_n) is
  begin  -- process trig_in_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      trigin_d<='0';
      trigin_d2<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      trigin_d<=srcc1_p_trigin;
      trigin_d2<=trigin_d;
    end if;
  end process trigin_d_ps;

  wren_trigin_ps: process (CLK_125M, rst_n, trigin_d, trigin_d2) is
--来自sma的trig
  begin  -- process trigin_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      wren_trigin<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      if trigin_cnt = x"3e1" then 
        wren_trigin<='0';
      elsif trigin_d = '1' and trigin_d2 ='0' then
         wren_trigin<='1';                           
      end if;
    end if;
  end process wren_trigin_ps;

  trigin_cnt_ps: process (CLK_125M, rst_n, gclk_d2, gclk_d) is
  begin  -- process trigin_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      trigin_cnt<=(others => '0');
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      if wren_trigin='0' then
        trigin_cnt<=(others => '0');
      elsif wren_trigin = '1' then
        if Gclk_d2 = '0' and Gclk_d = '1'  then        
        trigin_cnt<=trigin_cnt+1;
      end if;
    end if;
    end if;
  end process trigin_cnt_ps;

  -- ram_wren<=wren_ethernet or wren_reset or wren_trigin;
   ram_wren<=wren_ethernet or wren_trigin;
  -----------------------------------------------------------------------------
  upload_trig_ethernet_ps: process (CLK_125M, rst_n) is
  begin  -- process trig_in_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      upload_trig_ethernet_d<='0';
      upload_trig_ethernet_d2<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      upload_trig_ethernet_d<=upload_trig_ethernet;
      upload_trig_ethernet_d2<=upload_trig_ethernet_d;
    end if;
  end process upload_trig_ethernet_ps;
  
    SRCC1_n_upload_sma_trigin_ps: process (CLK_125M, rst_n) is
  begin  -- process trig_in_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      SRCC1_n_upload_sma_trigin_d<='0';
      SRCC1_n_upload_sma_trigin_d2<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      SRCC1_n_upload_sma_trigin_d<=SRCC1_n_upload_sma_trigin;
      SRCC1_n_upload_sma_trigin_d2<=SRCC1_n_upload_sma_trigin_d;
    end if;
  end process SRCC1_n_upload_sma_trigin_ps;

    ram_wren_d_ps: process (CLK_125M, rst_n) is
  begin  -- process trig_in_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      ram_wren_d<='0';
      ram_wren_d2<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      ram_wren_d<=ram_wren;
      ram_wren_d2<=ram_wren_d;
    end if;
  end process ram_wren_d_ps;
-------------------------
    upload_sma_trigin_ps: process (clk_125m, rst_n, SRCC1_n_upload_sma_trigin_d, SRCC1_n_upload_sma_trigin_d2) is
  begin  -- process wren_ethernet_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      upload_sma_trigin<='0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      if upload_sma_trigin_cnt = x"A" then  --模仿trig_i的长度
        upload_sma_trigin<='0';
      elsif SRCC1_n_upload_sma_trigin_d='1' and SRCC1_n_upload_sma_trigin_d2='0' then
        upload_sma_trigin<='1';
    end if;
  end if;
  end process upload_sma_trigin_ps;

   upload_sma_trigin_cnt_ps: process (CLK_125M, rst_n) is
  begin  -- process trigin_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      upload_sma_trigin_cnt<=(others => '0');
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      if upload_sma_trigin='0' then
        upload_sma_trigin_cnt<=(others => '0');
      elsif upload_sma_trigin = '1' then
        upload_sma_trigin_cnt<=upload_sma_trigin_cnt+1;
      end if;
    end if;
  end process upload_sma_trigin_cnt_ps;
--------------------------  
      upload_ethernet_trigin_ps: process (clk_125m, rst_n, upload_trig_ethernet_d,upload_trig_ethernet_d2) is
  begin  -- process wren_ethernet_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      upload_ethernet_trigin<='0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      if upload_ethernet_trigin_cnt = x"A" then  --模仿trig_i的长度
        upload_ethernet_trigin<='0';
      elsif upload_trig_ethernet_d='1' and upload_trig_ethernet_d2='0' then
        upload_ethernet_trigin<='1';
    end if;
  end if;
  end process upload_ethernet_trigin_ps;

     upload_ethernet_trigin_cnt_ps: process (CLK_125M, rst_n) is
  begin  -- process trigin_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      upload_ethernet_trigin_cnt<=(others => '0');
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      if upload_ethernet_trigin='0' then
        upload_ethernet_trigin_cnt<=(others => '0');
      elsif upload_ethernet_trigin = '1' then
        upload_ethernet_trigin_cnt<=upload_ethernet_trigin_cnt+1;
      end if;
    end if;
  end process upload_ethernet_trigin_cnt_ps;
-------------------------
     upload_wren_trigin_ps: process (clk_125m, rst_n, ram_wren_d,  ram_wren_d2) is
  begin  -- process wren_ethernet_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      upload_wren_trigin<='0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      if upload_wren_trigin_cnt = x"A" then  --模仿trig_i的长度
        upload_wren_trigin<='0';
      elsif ram_wren_d='1' and ram_wren_d2='0' then
        upload_wren_trigin<='1';
    end if;
  end if;
  end process upload_wren_trigin_ps;

     upload_wren_trigin_cnt_ps: process (CLK_125M, rst_n) is
  begin  -- process trigin_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      upload_wren_trigin_cnt<=(others => '0');
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      if upload_wren_trigin='0' then
        upload_wren_trigin_cnt<=(others => '0');
      elsif upload_wren_trigin = '1' then
        upload_wren_trigin_cnt<=upload_wren_trigin_cnt+1;
      end if;
    end if;
  end process upload_wren_trigin_cnt_ps;
------------------------
  --
 
------------------------
    busy_d_ps: process (CLK_125M, rst_n) is
  begin  -- process trig_in_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      busy_d<='0';
      busy_d2<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      busy_d<=busy;
      busy_d2<=busy_d;
    end if;
  end process busy_d_ps;
-------------------------------------------------------------------------------
 -- 无论ram_last什么情况,frame_gap在每次busy结束后触发，保证帧与帧之间相隔512Byte以通过CSMA/CD协议。
  frame_gap_ps: process (clk_125m, rst_n) is
  begin  -- process trig_i_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      frame_gap<='0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
        if frame_gap_cnt = x"010" then     --调整frame_gap的长度
          frame_gap <= '0';
        elsif busy_d2='1' and busy_d='0' then
          frame_gap <= '1';
        end if;
    end if;
  end process frame_gap_ps;

       frame_gap_cnt_ps: process (CLK_125M, rst_n) is
  begin  -- process trigin_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      frame_gap_cnt<=(others => '0');
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      if frame_gap='0' then
        frame_gap_cnt<=(others => '0');
      elsif frame_gap = '1' then
        frame_gap_cnt<=frame_gap_cnt+1;
      end if;
    end if;
  end process frame_gap_cnt_ps;

      frame_gap_d_ps: process (CLK_125M, rst_n) is
  begin  -- process trig_in_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      frame_gap_d<='0';
      frame_gap_d2<='0';
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      frame_gap_d<=frame_gap;
      frame_gap_d2<=frame_gap_d;
    end if;
  end process frame_gap_d_ps;
  -----------------------------------------------------------------------------
 -- 当RAM没有被读完时即ram_last='0',trig_i在每次frame_gap结束下降沿后触发。当ram被读完一遍时，即ram_last='1',ram读到最后一位，并且frame_gap释放,等待外部触发，
  trig_i_ps: process (clk_125m, rst_n) is
  begin  -- process trig_i_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      trig_i<='0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      if ram_last ='0' then
        if Trig_i_cnt = x"A" then
          trig_i <= '0';
        elsif frame_gap_d2='1' and frame_gap_d='0' then
          trig_i <= '1';
        end if;
      elsif ram_last='1' and frame_gap='0' then  --保证了死时间。以防下次外部触发太快。
      trig_i<=upload_sma_trigin or upload_ethernet_trigin or upload_wren_trigin; --可以通过上位机，sma，采集trig这三个统计来控制trig_i
        -- trig_i<=posedge_upload_trig;
      end if;
    end if;
  end process trig_i_ps;

     trig_i_cnt_ps: process (CLK_125M, rst_n) is
  begin  -- process trigin_cnt_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      trig_i_cnt<=(others => '0');
    elsif CLK_125M'event and CLK_125M = '1' then  -- rising clock edge
      if trig_i='0' then
        trig_i_cnt<=(others => '0');
      elsif trig_i = '1' then
        trig_i_cnt<=trig_i_cnt+1;
      end if;
    end if;
  end process trig_i_cnt_ps;
  
  -----------------------------------------------------------------------------
  Last_byte_ps : process (clk_125m, rst_n) is  --决定帧的长度
  begin  -- process Last_byte_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      last_byte <= '0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      -- if wr_addr = x"05db" then          --帧长1500
      if wr_addr = x"05db" then  
        last_byte <= '1';
      else
        last_byte <= '0';
      end if;
    end if;
  end process Last_byte_ps;

  wr_addr_ps : process (clk_125m, rst_n) is
  begin  -- process wr_addr_ps

    if clk_125m'event and clk_125m = '1' then     -- rising clock edge --每一帧busy的时候才增加地址
      if rst_n = '0' or Last_byte = '1' then  -- asynchronous reset (active low)
        wr_addr <= (others => '0');
      elsif busy = '1' then
        wr_addr <= wr_addr+1;
      else
        wr_addr <= (others => '0');
      end if;
    end if;
  end process wr_addr_ps;
-----------------------------------------------------------------------------
  data_test_ps: process (clk_125m, rst_n) is
  begin  -- process data_test_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      data_test<=(others => '0');
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      data_test<=data_test+1;
    end if;
  end process data_test_ps;
--  phy_txen_d_ps : process (clk_125m, rst_n) is
--  begin  -- process Gclk_ps
--    if rst_n = '0' then
--      phy_txen_quar <= '0';
--    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
--      phy_txen_quar <= phy_txen_o;
--    end if;
--  end process phy_txen_d_ps;
-----------------------------------------------------------------------------
  -- shift_reg_ps : process (clk_125m, rst_n) is
  -- begin  -- process shift_reg_ps
  --   if rst_n = '0' then                 -- asynchronous reset (active low)
  --     wr_data <= (others => '0');
  --   elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
  --     case wr_addr is
  --       when x"00" =>
  --         wr_data <= x"55";
  --       when x"01" =>
  --         wr_data <= x"55";
  --       when x"02" =>
  --         wr_data <= x"55";
  --       when x"03" =>
  --         wr_data <= x"55";
  --       when x"04" =>
  --         wr_data <= x"55";
  --       when x"05" =>
  --         wr_data <= x"55";
  --       when x"06" =>
  --         wr_data <= x"55";
  --       when x"07" =>
  --         wr_data <= x"d5";
  --       when others => wr_data <= x"00";
  --     end case;
  --   end if;
  -- end process shift_reg_ps;
-------------------------------------------------------------------------------
  SWITCH_STATE_ps : process (clk_125m, rst_n) is
  begin  -- process CHANGE_STATE_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      current_state <= ini_state;
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      current_state <= next_state;
    end if;
  end process SWITCH_STATE_ps;


  CHANGE_STATE_ps : process (current_state, next_state,trig_i,addr_en,frame_num_en,data_ready,last_byte,busy) is
  begin
    case current_state is
      when ini_state =>
        if trig_i = '1' then
          next_state <= header_state;
        else
          next_state <= ini_state;
        end if;
        when header_state =>
        if addr_en = '1' then
          next_state <= addr_state;
        else
          next_state <= header_state;
        end if;
        when addr_state =>
        if frame_num_en = '1' then
          next_state <= frame_num_state1;
        else
          next_state <= addr_state;
        end if;
        when frame_num_state1 =>
          next_state <= frame_num_state2;
        when frame_num_state2 =>
          next_state <= data_state;       
        when data_state =>
        if last_byte = '1' then
          next_state <= end_state;
        else
          next_state <= data_state;
        end if;
      when end_state =>
        if busy ='0' then
          next_state<=ini_state;
        end if;
      when others => null;
    end case;
  end process CHANGE_STATE_ps;

  FSM_output: process (clk_125m, rst_n) is
  begin  -- process FSM_output
    if rst_n = '0' then                 -- asynchronous reset (active low)
      wr_data<=(others => '0');
      frame_cnt<=(others => '0');
      -- ram_wren<='0';
      fifo_upload_wren<='0';
      ram_rden<='0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
        case current_state is
          when ini_state =>
            wr_data<=(others => '0');
            wait_frame<='0';
            -- ram_wren<='0';
            fifo_upload_wren<='0';
            addr_en<='0';
            frame_num_en<='0';
            ram_rden<='0';
          when header_state =>
            wr_data<=header(header_cnt);
             fifo_upload_wren<='1';
            -- ram_wren<='1';
           if header_cnt<7 then
            header_cnt<=header_cnt+1;
            else
              header_cnt<=0;
           end if;
            if header_cnt=6 then

--因为addr_en=1在cnt=7到来,作为组合逻辑next_state在header_cnt=7状态跳转，header_cnt=7在下一个clk因为是在下一个状态addr_state内所以不再增加但是还会持续一拍，因为addr_state的下一拍（cnt=8)才清零。所以加上else header_cnt<=0才能使它在111保持一拍。因为是时序逻辑case（current state)所以current_state的跳转在2拍后到来
              addr_en<='1';
            end if;
            
          when addr_state =>
            header_cnt<=0;
            if addr_cnt<13 then
            addr_cnt<=addr_cnt+1;
            else
              addr_cnt<=0;
            end if;
            wr_data<=address(addr_cnt);
            if addr_cnt =12 then
              frame_num_en<='1';
              frame_cnt<=frame_cnt+1;
            end if;
            
          when frame_num_state1 =>
            addr_cnt<=0;
            wr_data<=frame_cnt(15 downto 8);
             ram_rden<='1';
          when frame_num_state2 =>          
            wr_data<=frame_cnt(7 downto 0);
           ram_rden<='1';
          when data_state =>
            wr_data<=fifo_upload_data;
            ram_rden<='1';
          when end_state =>
            fifo_upload_wren<='0';
            -- ram_wren<='0';--ram_rden因为每帧的读写需要连续所以在状态机里控制，但是ram_wren理论上是上位机来了trig后持续一段时间结束
            ram_rden<='0';
          when others => null;
        end case;
    end if;
  end process FSM_output;
  -----------------------------------------------------------------------------
end Behavioral;

