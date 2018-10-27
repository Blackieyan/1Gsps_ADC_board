library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity phy_read_vld_gen is
  generic(
    BURST_LEN       : integer  := 4;    -- 4 = Burst Length 4, 2 = Burst Length 2
    TCQ             : integer  := 100   -- Register delay
  );
  port(
    -- System Signal
    clk             : in  std_logic;                    -- main system half freq clk
    rst_clk         : in  std_logic;                    -- reset syncrhonized to clk
    
    -- Write Interface
    int_rd_cmd_n    : in  std_logic_vector(1 downto 0); -- read command(s) 
                                                        -- only bit 0 is used for BL4
    
    -- Stage 2 Calibration Interface
    valid_latency   : in  std_logic_vector(4 downto 0); -- amount to delay read 
                                                        -- command
    cal_done        : in  std_logic;                    -- indicates calibration 
                                                        -- is complete

    -- User Interface
    data_valid0     : out std_logic;                    -- data valid for read data 0
    data_valid1     : out std_logic;                    -- data valid for read data 1
    
    -- ChipScope Debug Signals
    dbg_valid_lat   : out std_logic_vector(4 downto 0)
    );
end entity phy_read_vld_gen;

architecture arch of phy_read_vld_gen is
  
  --signal declarations
  signal data_valid0_int    : std_logic;
  signal data_valid1_int    : std_logic;
  signal data_valid0_int_r  : std_logic;
  signal data_valid1_int_r  : std_logic;
  signal int_rd_cmd_n_0_inv : std_logic;
  signal int_rd_cmd_n_1_inv : std_logic;
    
begin

  -- Delay the incoming rd_cmd0 by valid_latency number of cycles in order to
  -- generate the data valid for read data 0
  -- Invert D input signal.
  int_rd_cmd_n_0_inv <= not int_rd_cmd_n(0);
  vld_gen_srl0_inst : SRLC32E
  port map(
    Q    => data_valid0_int,
    Q31  => open,
    A    => valid_latency,
    CE   => '1',
    CLK  => clk,
    D    => int_rd_cmd_n_0_inv
  );
    
  process(clk)
  begin
    if (clk'event and clk = '1') then
      data_valid0_int_r <= data_valid0_int after TCQ*1 ps;
    end if;
  end process;
  
  -- Only issue valids after calibration has completed
  process(clk) 
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        data_valid0 <= '0' after TCQ*1 ps;
      elsif (BURST_LEN = 8) then
        data_valid0 <= ((data_valid0_int or data_valid0_int_r) and cal_done) after TCQ*1 ps;
      else
        data_valid0 <= (data_valid0_int and cal_done) after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  -- Delay the incoming rd_cmd1 by valid_latency number of cycles in order to
  -- generate the data valid for read data 1
  -- Invert D input signal.
  int_rd_cmd_n_1_inv <= not int_rd_cmd_n(1);
  vld_gen_srl1_inst : SRLC32E
  port map(
    Q    =>data_valid1_int,
    Q31  => open,
    A    => valid_latency,
    CE   => '1',
    CLK  => clk,
    D    => int_rd_cmd_n_1_inv
  );
  
  process(clk)
  begin
    if (clk'event and clk = '1') then
      data_valid1_int_r <= data_valid1_int after TCQ*1 ps;
    end if;
  end process;

  -- Only issue valids after calibration has completed  
  process(clk) is 
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        data_valid1 <= '0' after TCQ*1 ps;
      elsif (BURST_LEN = 8) then
        data_valid1 <= ((data_valid1_int or data_valid1_int_r) and cal_done) after TCQ*1 ps;
      else
        data_valid1 <= (data_valid1_int and cal_done) after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Assign debug signals
  dbg_valid_lat <= valid_latency;

end architecture arch;