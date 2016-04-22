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
    ram_wren : out std_logic;
    ram_rden : out std_logic
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
  signal wr_addr             : std_logic_vector(11 downto 0)  := x"000";
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
  -- constant address : array_address := (x"0c",x"00",x"86",x"B1",x"00",x"67",x"10",x"00",x"ff",x"ff",x"ff",x"ff",x"ff",x"ff");
      constant address : array_address := (x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
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
    if rst_n = '0' then
      Gclk_d <= '0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      GCLK_d <= GCLK;
    end if;
  end process Gclk_d_ps;

  Gclk_d2_ps : process (clk_125m, rst_n) is
  begin  -- process Gclk_d2_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      Gclk_d2 <= '0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      Gclk_d2 <= GCLK_d;
    end if;
  end process Gclk_d2_ps;

  Gcnt_ps : process (GCLK, rst_n) is
  begin
    if rst_n = '0' then
      Gcnt <= (others => '0');
    -- elsif Gclk_d2 = '0' and Gclk_d = '1' then
    elsif GCLK'event and GCLK = '1' then
-- if Gcnt <= x"ffffffff" then
      Gcnt <= Gcnt+1;
    end if;
-- end if;
  end process Gcnt_ps;

  O_Gcnt_ps : process (clk_125m, rst_n) is
  begin  -- process O_Gcnt_ps
    if rst_n = '0' then
      O_Gcnt <= (others => '0');
    -- elsif Gclk_d2 = '0' and Gclk_d = '1' then
    elsif GCLK'event and GCLK = '1' then
      if Gcnt = x"ffff" and O_Gcnt <= x"F5" then
        O_Gcnt <= O_Gcnt+1;
      else
        O_Gcnt <= (others => '0');
      end if;
    end if;
  end process O_Gcnt_ps;

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
  trig_i_ps : process (GCLK, rst_n, clk_125m) is
  begin  -- process trig_i_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      trig_i <= '0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      -- if GCLK_d='0' and GCLK='1' then
      if Gcnt = x"0020" then
        trig_i <= '1';
      else
        trig_i <= '0';
      end if;
    end if;
  end process trig_i_ps;

    ram_wren_ps : process (GCLK, rst_n, clk_125m) is
--实际上是trig信号来以后持续100us或者其它。一个trig只持续一次。这里用gcnt会反复出现。但是用not full相与可以避免最终的使能反复。想要清零只能通过复位信号。以后要修改为命令trig下传后执行一次ram_clr
  begin  -- process trig_i_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      ram_wren <= '0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      -- if GCLK_d='0' and GCLK='1' then
      if Gcnt >= x"AC8" and Gcnt<=x"c68" then  --为了防止上电马上采样时的抖动 这个数值要够大。
        ram_wren <= '1';
      else
        ram_wren <= '0';
      end if;
    end if;
  end process ram_wren_ps;
  
  Last_byte_ps : process (clk_125m, rst_n) is
  begin  -- process Last_byte_ps
    if rst_n = '0' then                 -- asynchronous reset (active low)
      last_byte <= '0';
    elsif clk_125m'event and clk_125m = '1' then  -- rising clock edge
      if wr_addr = x"5db" then
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

