library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity ADC_interface is
  port(
    ADC_Mode     : out std_logic;       -- choose mode
    ADC_sclk_OUT : out std_logic;       -- register write clock
    ADC_sldn_OUT : out std_logic;       -- register write enable
    ADC_sdata    : out std_logic_vector(0 downto 0);
    -- OSC_in_n      : in  std_logic;
    -- OSC_in_p      : in  std_logic
    user_pushbutton : in std_logic;
    CLK1         : in  std_logic;        -- clock from dcm 100MHz
    clk2 : in std_logic
    );
end entity ADC_interface;

architecture Behavioral of ADC_interface is
  signal data        : std_logic_vector(15 downto 0) := "0000000011001110";  -- register data
  signal address     : std_logic_vector(2 downto 0)  := "000";  -- register address
  signal ADC_sldn    : std_logic;
  signal ADC_sclk    : std_logic;
  signal combine     : std_logic_vector(18 downto 0);           -- add+data
  signal rst_n       : std_logic;       -- rst_n
  --signal user_pushbutton : std_logic;
--  signal CLK_100M    : std_logic;       -- clk from dcm 10A0MHz
  signal Div_multi   : std_logic_vector(3 downto 0)  := "1010";  -- frequency division factor
  signal OOcnt       : std_logic_vector(15 downto 0) := x"0000";  --Gcnt round
  signal Gcnt        : std_logic_vector(31 downto 0) := x"00000000";  -- global count
  signal OGcnt       : std_logic_vector(15 downto 0) := x"0000";
  signal Scnt        : std_logic_vector(7 downto 0)  := x"00";  -- sclk count
  signal shift_data  : std_logic_vector(18 downto 0);
  signal shift_depth : std_logic_vector(4 downto 0)  := "10011";
  signal ADC_sld     : std_logic;
  signal enable      : std_logic;
  signal clk_div_cnt : std_logic_vector(7 downto 0)  := x"00";  -- 给时钟分频计数器
  signal sldn_cnt    : std_logic_vector(3 downto 0)  := "0000";
  signal ADC_sldn_d  : std_logic;
  signal start       : std_logic;
  signal start_d     : std_logic;
  signal finish      : std_logic;
  signal finish_d    : std_logic;
  signal finish_cnt  : std_logic_vector(3 downto 0)  := "0000";
  signal reg         : std_logic_vector(18 downto 0);
  signal working     : std_logic;
  signal SCLK_en : std_logic;
  constant reg000    : std_logic_vector(18 downto 0) := "0000111110011111100";
  constant reg001    : std_logic_vector(18 downto 0) := "0011000000010000000";
  constant reg010    : std_logic_vector(18 downto 0) := "0100000000000000000";
  constant reg011    : std_logic_vector(18 downto 0) := "0110000000000000000";
  constant reg100    : std_logic_vector(18 downto 0) := "1001000010000011011";
  constant reg101    : std_logic_vector(18 downto 0) := "1010000000000000000";
  constant reg110    : std_logic_vector(18 downto 0) := "1100000000000000000";
  constant reg111    : std_logic_vector(18 downto 0) := "1110000000000100100";
  -- constant reg000    : std_logic_vector(18 downto 0) := "0001111000011111100";
  -- constant reg001    : std_logic_vector(18 downto 0) := "0001111000011111100";
  -- constant reg010    : std_logic_vector(18 downto 0) := "0001111000011111100";
  -- constant reg011    : std_logic_vector(18 downto 0) := "0001111000011111100";
  -- constant reg100    : std_logic_vector(18 downto 0) := "0001111000011111100";
  -- constant reg101    : std_logic_vector(18 downto 0) := "0001111000011111100";
  -- constant reg110    : std_logic_vector(18 downto 0) := "0001111000011111100";
  -- constant reg111    : std_logic_vector(18 downto 0) := "0001111000011111100";
-------------------------------------------------------------------------------
begin
  -- ADC_sclk<=clk2;
  ADC_sclk_OUT <= ADC_sclk and SCLK_en;
  ADC_sldn_OUT <= ADC_sldn_d;
  -- ADC_Mode     <= '1';

  main_counter : process (CLK1,rst_n)
  begin
    if rst_n='0' then
      Gcnt<=(others => '0');
    elsif CLK1'event and CLK1 = '1' then   -- rising clock edge
      Gcnt <= Gcnt+1;
    elsif Gcnt >= x"11111111" then
      Gcnt <= x"00000000";
    end if;
  end process main_counter;

  -- purpose: count the cycle of Gcnt 为了只产生一次复位信号。
  -- type   : sequential
  -- inputs : clk1
  -- outputs: 
  set_OGcnt : process (clk1,rst_n) is
  begin  -- process OGcnt
    if rst_n='0' then
      OGcnt<=(others => '0');
    elsif clk1'event and clk1 = '1'  then     -- rising clock edge
      if Gcnt = x"11111111" then
        OGcnt <= OGcnt+1;
      else
        OGcnt <= OGcnt;
      end if;
    end if;
  end process set_OGcnt;
-------------------------------------------------------------------------------
-- purpose: set reset
-- type   : sequential
-- inputs : ADC_SCLK,rst_n, rst_n
-- outputs: 
  set_reset : process (CLK1) is
  begin  -- process reset
    if CLK1'event and CLK1 = '1' then
      -- if Gcnt >= x"00000010" and Gcnt <= x"00000020" and OGcnt = x"0000" then
      --   rst_n <= '0';
      -- else
        rst_n <= user_pushbutton;
      -- end if;
    end if;
  end process set_reset;
-------------------------------------------------------------------------------
  set_start : process (CLK1, rst_n) is
  begin  -- process set_start
    if rst_n = '0' then                   -- asynchronous reset (active low)
      start <= '0';
    elsif CLK1'event and CLK1 = '1' then  -- rising clock edge
      if Gcnt >= x"00001000" and Gcnt <= x"00001010" and OGcnt = x"0000" then
        start <= '1';
      else
        start <= '0';
      end if;
    end if;
  end process set_start;

  set_start_d : process (ADC_sclk, rst_n) is
  begin  -- process set_start_d
    if rst_n = '0' then                 -- asynchronous reset (active low)
      start_d <= '0';
    elsif ADC_sclk'event and ADC_sclk = '1' then  -- rising clock edge
      start_d <= start;
    end if;
  end process set_start_d;
-------------------------------------------------------------------------------
  set_clk_div_cnt : process (CLK1, rst_n) is
  begin  -- process set_clk_div_cnt
    if rst_n = '0' then                 -- asynchronous reset (active
      clk_div_cnt <= x"00";
    elsif CLK1'event and CLK1 = '1' then          -- rising clock edge
      if clk_div_cnt <= Div_multi then
        clk_div_cnt <= clk_div_cnt+1;
      else
        clk_div_cnt <= x"00";
      end if;
    end if;
  end process set_clk_div_cnt;

  set_ADC_sclk : process (CLK1, rst_n) is
  begin  -- process set_ADC_sclk
    if rst_n = '0' then                   -- asynchronous reset (active low)
      ADC_SCLK <= '0';
    elsif CLK1'event and CLK1 = '1' then  -- rising clock edge
      if clk_div_cnt <= Div_multi(3 downto 1) then
        ADC_SCLK <= '0';
      else
        ADC_SCLK <= '1';
      end if;
    end if;
  end process set_ADC_sclk;

  set_mode : process (ADC_sclk, rst_n) is
  begin  -- process set_mode
    if rst_n = '0' then                 -- asynchronous reset (active low)
      ADC_Mode <= '0';
    elsif ADC_sclk'event and ADC_sclk = '1' then  -- rising clock edge
      if OOcnt=x"0001" and finish_cnt= "0000"  then
        ADC_mode<='0';
      else
      ADC_Mode <= '1';
    end if;
  end if;
  end process set_mode;
  -----------------------------------------------------------------------------
  set_working : process (ADC_sclk, rst_n) is
  begin  -- process set_working
    if rst_n = '0' then                 -- asynchronous reset (active low)
      working <= '0';
    elsif ADC_sclk'event and ADC_sclk = '1' then  -- rising clock edge
      if finish_cnt <= "0111" then
        if start = '1' and start_d = '0' then
          working <= '1';
        end if;
      end if;
    end if;
  end process set_working;

  set_OOcnt : process (ADC_sclk, rst_n) is
  begin  -- process set_OOcnt
    if rst_n = '0' then                 -- asynchronous reset (active low)
      OOcnt <= (others => '0');
    elsif ADC_sclk'event and ADC_sclk = '1' then  -- rising clock edge
      if working = '1' then
        if OOcnt <= x"0019" then
          OOcnt <= OOcnt+1;
        elsif OOcnt >= x"001A" then
          OOcnt <= (others => '0');
        end if;
      end if;
    end if;
  end process set_OOcnt;
-------------------------------------------------------------------------------


  set_ADC_sldn : process (ADC_SCLK, rst_n) is
  begin  -- process ADC_sldn
    -- if rst_n = '0' then                 -- asynchronous reset (active low)
    --   ADC_sldn <= '1';
    -- elsif ADC_SCLK'event and ADC_SCLK = '0' then  -- rising clock edge
    --   if finish = '1' then
    --     ADC_sldn <= '1';
    --   end if;
    -- end if;
    if rst_n = '0' then                 -- asynchronous reset (active low)
      ADC_sldn <= '1';
    elsif ADC_SCLK'event and ADC_SCLK = '0' then
      if finish_cnt <= "0111" then
        if OOcnt >= x"0003" and OOcnt <= x"0016" then
          ADC_sldn <= '0';
        else
          ADC_sldn <= '1';
        end if;
      end if;
    end if;
  end process set_ADC_sldn;

  set_ADC_sldn_d : process (ADC_sclk, rst_n) is
  begin  -- process set_ADC_sldn_d
    if rst_n = '0' then                 -- asynchronous reset (active low)
      ADC_sldn_d <= '1';

    elsif ADC_sclk'event and ADC_sclk = '0' then  -- rising clock edge
      ADC_sldn_d <= ADC_sldn;
    end if;
  end process set_ADC_sldn_d;
  -----------------------------------------------------------------------------
  set_SCLK_ctr: process (ADC_sclk, rst_n) is
  begin  -- process set_SCLK_ctr
    if rst_n = '0' then                 -- asynchronous reset (active low)
      SCLK_en<='0';
    elsif ADC_sclk'event and ADC_sclk = '1' then  -- rising clock edge
      if finish_cnt<="0111" then
      if OOcnt >= x"0003" and OOcnt <= x"0018" then
        SCLK_en<='1';
      else
        SCLK_en<='0';
    end if;
  end if;
end if;
  end process set_SCLK_ctr;
  -----------------------------------------------------------------------------
  write_register : process (ADC_sclk, rst_n) is
  begin  -- process write register
    if rst_n = '0' then                 -- asynchronous reset (active low)
      combine <= reg;
    elsif ADC_sclk'event and ADC_sclk = '0' then  -- rising clock edge
      if OOcnt = x"0003" then
        -- ADC_sdata(0) <= '0';
        combine      <= reg;
      elsif ADC_sldn = '0' then
        ADC_sdata(0) <= combine(18);
        combine      <= combine(17 downto 0)&"0";
      end if;
    end if;
  end process write_register;
  -----------------------------------------------------------------------------
  set_finish : process (ADC_sclk, rst_n) is
  begin  -- process set_finish
    if rst_n = '0' then                 -- asynchronous reset (active low)
      finish <= '0';
    elsif ADC_sclk'event and ADC_sclk = '1' then  -- rising clock edge
      if OOcnt = x"001A" then
        finish <= '1';
      else
        finish <= '0';
      end if;
    end if;
  end process set_finish;

  set_finish_d : process (ADC_sclk, rst_n) is
  begin  -- process set_finish_d
    if rst_n = '0' then                 -- asynchronous reset (active low)
      finish_d <= '0';
    elsif ADC_sclk'event and ADC_sclk = '1' then  -- rising clock edge
      finish_d <= finish;
    end if;
  end process set_finish_d;

  set_finish_cnt : process (ADC_sclk, rst_n) is
  begin  -- process set_start_cnt
    if rst_n = '0' then                 -- asynchronous reset (active low)
      finish_cnt <= (others => '0');
    elsif ADC_sclk'event and ADC_sclk = '1' then  -- rising clock edge
      if finish_cnt <= "0111" then
        if finish = '1' and finish_d = '0'then
          finish_cnt <= finish_cnt+1;
        end if;
      end if;
    end if;
  end process set_finish_cnt;
  ------------------------------------------------------------------------------
  set_reg : process (ADC_sclk, rst_n) is
  begin  -- process set_reg
    if rst_n = '0' then                 -- asynchronous reset (active low)
      reg <= (others => '0');
    elsif ADC_sclk'event and ADC_sclk = '1' then  -- rising clock edge
      if finish_cnt = "000" then
        reg <= reg000;
      elsif finish_cnt = "001" then
        reg <= reg001;
      elsif finish_cnt = "010" then
        reg <= reg010;
      elsif finish_cnt = "011" then
        reg <= reg011;
      elsif finish_cnt = "100" then
        reg <= reg100;
      elsif finish_cnt = "101" then
        reg <= reg101;
      elsif finish_cnt = "110" then
        reg <= reg110;
      elsif finish_cnt = "111" then
        reg <= reg111;
      end if;
    end if;
  end process set_reg;
------------------------------------------------------------------------------
end Behavioral;
