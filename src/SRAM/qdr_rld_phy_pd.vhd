--*****************************************************************************
-- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and 
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor                : Xilinx
-- \   \   \/     Version               : 3.9
--  \   \         Application           : MIG
--  /   /         Filename              : qdr_rld_phy_pd.vhd
-- /___/   /\     Date Last Modified    : $date$
-- \   \  /  \    Date Created          : Jan 30 2009
--  \___\/\___\
--
--Device            : Virtex-6
--Design            : QDRII+ SRAM/RLDRAM II SDRAM
--Purpose           : top level module for QDRII+/RLDRAM II Phase Detection. 
--Reference         :
--Revision History  :
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity qdr_rld_phy_pd is
generic(
  CLK_PERIOD      : integer := 1876;
  REFCLK_FREQ     : real    := 300.0;         -- Ref Clk Freq. for IODELAYs
  MEM_TYPE        : string  := "QDR2PLUS";    -- Memory Type (QDR2PLUS; 
                                              -- RLD2_CIO; RLD2_SIO)
  MIN_TAPS        : integer := 5;             -- minimum usuable clock tap setting  
  IODELAY_GRP     : string  := "IODELAY_MIG"; -- May be assigned unique name 
                                              -- when mult IP cores in design
  TCQ             : integer := 100;           -- Register Delay
  SIM_CAL_OPTION  : string  := "NONE";        -- "NONE", "FAST_CAL", or "SKIP_CAL"
  SIM_INIT_OPTION : string  := "NONE"         -- "NONE", "SIM_MODE"
);
port(
  pd_en_maintain      : out std_logic;
  pd_calib_done       : out std_logic;
  pd_incdec_maintain  : out std_logic;
  pd_calib_error      : out std_logic;
  pd_calib_start      : in std_logic;
  clk_cq              : in std_logic;
  clk_cqn             : in std_logic;
  clk_rd              : in std_logic;
  pd_source           : in std_logic;
  clk                 : in std_logic;
  clk_mem             : in std_logic;
  clk_wr              : in std_logic;
  wc                  : in std_logic;
  rst_clk_rd          : in std_logic;
  rst_wr_clk          : in std_logic;
  dbg_pd_off          : in std_logic
);
end entity qdr_rld_phy_pd;

architecture arch of qdr_rld_phy_pd is
  -- constant declaratoin
  attribute IODELAY_GROUP : string;
  attribute IODELAY_GROUP of qdr_pd_idelay : label is IODELAY_GRP;
  constant IODELAY_PD_VAL : integer := MIN_TAPS;
  
  constant REFCLK200_LOW_LIMIT : integer := 8000; --clk_rd lower limit in ps
  constant REFCLK300_LOW_LIMIT : integer := 5334; --clk_rd lower limit in ps
  
  function and_br ( 
    var : std_logic_vector
  ) return std_logic is
    variable tmp : std_logic := '1' ;
  begin
    for i in 0 to (var'length-1) loop
      tmp := tmp and var(i);
    end loop;
    return tmp;
  end function and_br;
  
  function or_br ( 
      var : std_logic_vector
    ) return std_logic is
      variable tmp : std_logic := '0' ;
    begin
      for i in 0 to (var'length-1) loop
        tmp := tmp or var(i);
      end loop;
      return tmp;
    end function or_br;

  signal oserdes_pd_out     : std_logic;
  signal iobuf_out          : std_logic;
  signal pd_data_source     : std_logic;
  signal pd_iodly           : std_logic;
  signal pd_en_calib        : std_logic;
  signal trip_point         : std_logic;
  signal trip_point_1       : std_logic;
  signal trip_point_xor     : std_logic;
  signal pd_psen            : std_logic;
  signal first_calib_n      : std_logic;
  signal inv_trip_point     : std_logic;
  signal pd_incdec_calib    : std_logic;
  signal tap_count          : std_logic_vector(4 downto 0);
  signal cnt_value_out      : std_logic_vector(4 downto 0);
  signal cnt_value_lt_5     : std_logic;
  signal tq                 : std_logic;
  signal pd_incdec          : std_logic;
  signal pd_calib_done_int  : std_logic;
  signal pd_en_calib_int    : std_logic;
  signal pd_incdec_int      : std_logic; 
  signal pd_calib_error_int : std_logic;   
  
  constant INTERFACE_TYPE : string := "NETWORKING";
  
  -- Component declarations
  component qdr_rld_phy_ocb_mon
  generic(
    SIM_CAL_OPTION  : string;  -- "NONE", "FAST_CAL", "SKIP_CAL"
    SIM_INIT_OPTION : string;  -- "NONE", "SIM_MODE"
    TCQ             : integer  -- Register Delay
  );
  port(
    dbg_ocb_mon         : out std_logic_vector(255 downto 0);  -- debug signals
    ocb_mon_PSEN        : out std_logic;   -- to MCMM_ADV
    ocb_mon_PSINCDEC    : out std_logic;   -- to MCMM_ADV
    ocb_mon_calib_done  : out std_logic;   -- ocb clock calibration done
    ocb_wc              : out std_logic;   -- to OSERDESE1
    ocb_extend          : in std_logic;    -- from OSERDESE1
    ocb_mon_PSDONE      : in std_logic;    -- from MCMM_ADV
    ocb_mon_go          : in std_logic;    -- start the OCB monitor state machine 
    clk                 : in std_logic;    -- clkmem/2
    rst                 : in std_logic;
    ocb_enabled_n       : in std_logic
  );
  end component;
  
  begin
  
  pd_calib_done <= pd_calib_done_int;
  pd_calib_error <= pd_calib_error_int;
  
--  -- **************** Debug **********************************
--  --synthesis translate_off
--  process(pd_calib_start) 
--  begin
--    if (pd_calib_start'event and pd_calib_start = '1') then
--      if (rst_wr_clk = '0') then
--      $display ("PHY_QDR_PD: Phase Detector Initial Cal started at   %t", 
--                $time);
--          if ( (REFCLK_FREQ = 300.0 and CLK_PERIOD > REFCLK300_LOW_LIMIT ) or 
--             (  REFCLK_FREQ = 200.0 and CLK_PERIOD > REFCLK200_LOW_LIMIT))
--          $display ("QDR_RLD_PHY_PD: WARNING: Lower Frequency limit exceeded");      
--                
--      end if;
--    end if;
--  end process;
--  
--  process(pd_calib_done_int) 
--  begin
--    if (pd_calib_done_int'event and pd_calib_done_int = '1') then
--      if (rst_wr_clk = '0') then
--     $display ("PHY_QDR_PD: Phase Detector Initial Cal completed at %t", 
--                $time);
--      end if;
--    end if;
--  end process
--   --synthesis translate_on
   
  -- **************** instantiate PD OSERDESE1 ****************
--QDR2_PD_TRIP :
--if (MEM_TYPE = "QDR2PLUS" or MEM_TYPE = "QDR2") generate 
--begin
--  u_pd_oserdes : OSERDESE1 
--  generic map(
--    DATA_RATE_OQ   => "DDR",
--    DATA_RATE_TQ   => "DDR",
--    DATA_WIDTH     => 4,
--    DDR3_DATA      => 1,
--    INIT_OQ        => '0',
--    INIT_TQ        => '1',
--    INTERFACE_TYPE => "MEMORY_DDR3",
--    ODELAY_USED    => 0,
--    SERDES_MODE    => "MASTER",
--    SRVAL_OQ       => '0',
--    SRVAL_TQ       => '0',
--    TRISTATE_WIDTH => 4
--  )   
--  port map(
--    OQ           => oserdes_pd_out,   -- Data Output
--    SHIFTOUT1    => open,             -- Carry out for Data - Unused
--    SHIFTOUT2    => open,
--    TQ           => tq,               -- Tristate outputs
--    CLK          => clk_mem,          -- Full Freq Clk Input clocks D in OCB
--    CLKDIV       => clk,              -- Half Freq Clk Input for clking Data
--    CLKPERF      => clk_wr,           -- Full Freq Performance Path - Clocks
--    CLKPERFDELAY => '0',              -- Output from IODELAY
--    OFB          => open,             -- Feedback path for clk_wr
--    D1           => '1',
--    D2           => '0',
--    D3           => '1',
--    D4           => '0',
--    D5           => '0',              -- Data inputs 5/6 - Unused
--    D6           => '0',
--    OCBEXTEND    => open,
--    OCE          => '1',              -- Enable Data input bits
--    ODV          => '0',              -- Set to '0' because delay doesn't
--                                      -- exceed 180 degrees
--    SHIFTIN1     => '0',              -- Carry in for Data - Unused
--    SHIFTIN2     => '0',
--    RST          => rst_wr_clk,       -- Reset for OSERDES
--    T1           => '0',              -- Tie off Tristate inputs - Unused
--    T2           => '0',
--    T3           => '0',
--    T4           => '0',
--    TFB          => open,
--    TCE          => '0',              -- Disable Tristate inputs
--    WC           => wc                -- Write Command to reset internal cntrs
--  );
--   
--  -- **************** instantiate PD IOBUF ****************
--
--  u_iobuf_pd : IOBUF 
--  generic map(
--   IOSTANDARD => "HSTL_II"
--   ) 
--   port map(
--    O   => iobuf_out,
--    IO  => open,
--    I   => oserdes_pd_out,
--    T   => tq
--  );
--end generate;
--
--RLD2_PD_TRIP :
--if (not(MEM_TYPE = "QDR2PLUS" or MEM_TYPE = "QDR2")) generate 
--begin
--  iobuf_out <= pd_source;
--end generate;   

iobuf_out <= pd_source;

  -- **************** optionally delay pd_source ****************

  -- set delay to 900 to test inv_trip_point

  process(iobuf_out) 
  begin
    pd_data_source <= iobuf_out after 900 ps;
  end process;
  
  -- **************** instantiate PD IODELAYE1 ****************

  qdr_pd_idelay : IODELAYE1 
  generic map(
    DELAY_SRC              => "I",
    HIGH_PERFORMANCE_MODE  => TRUE,
    IDELAY_TYPE            => "VARIABLE",
    IDELAY_VALUE           => IODELAY_PD_VAL,
    REFCLK_FREQUENCY       => REFCLK_FREQ,
    SIGNAL_PATTERN         => "CLOCK"
  ) 
  port map(
    CNTVALUEOUT  => cnt_value_out,
    DATAOUT      => pd_iodly,
    C            => clk_rd,
    CE           => pd_en_calib_int,
    CINVCTRL     => '0',
    CNTVALUEIN   => "00000",
    DATAIN       => '0',
    IDATAIN      => pd_data_source,
    INC          => pd_incdec_int,
    ODATAIN      => '0',
    RST          => rst_clk_rd,
    CLKIN        => '0',
    T            => '1'
  );
   
  -- **************** instantiate PD ISERDESE1 ****************

  qdr_pd_iserdes : ISERDESE1 
  generic map(
    DATA_RATE          => "DDR",
    DATA_WIDTH         => 4,
    DYN_CLKDIV_INV_EN  => TRUE,
    IOBDELAY           => "IFD",
    INTERFACE_TYPE     => "NETWORKING",
    NUM_CE             => 2,
    SERDES_MODE        => "MASTER"
  ) 
  port map(
    BITSLIP        => '0',
    CE1            => '1',
    CE2            => '1',
    DYNCLKDIVSEL   => '0',
    CLK            => clk_cq,
    CLKB           => clk_cqn,
    CLKDIV         => clk_rd,
    D              => '0',
    DDLY           => pd_iodly,
    DYNCLKSEL      => '0',
    OCLK           => '0',
    RST            => rst_clk_rd,
    SHIFTIN1       => '0',
    SHIFTIN2       => '0',
    O              => open,
    Q1             => trip_point,
    Q2             => open,
    Q3             => open,
    Q4             => open,
    Q5             => open,
    Q6             => open,
    SHIFTOUT1      => open,
    SHIFTOUT2      => open,
    OFB            => '0' 
  ); 
   
  -- **************** conditionally invert trip_point ****************

  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        first_calib_n  <= '0' after TCQ*1 ps;
        inv_trip_point <= '0' after TCQ*1 ps;
      else
        if (pd_psen = '1') then
          first_calib_n <= '1' after TCQ*1 ps;
        end if;
        if (not(first_calib_n) = '1' and pd_psen = '1' and not(pd_incdec) = '1') then
          inv_trip_point <= '1' after TCQ*1 ps;
        end if;
      end if;
    end if;
  end process;

  --trip_point_1 <= inv_trip_point xor trip_point;
  
  trip_point_xor <= inv_trip_point xor trip_point;
  
  -- Determine if cnt_value_out < 5
  cnt_value_lt_5 <= '1' when (cnt_value_out < "00101") else
                    '0';
  
  trip_point_1 <= inv_trip_point when ((cnt_value_lt_5 = '1') and (inv_trip_point = '1')) else
                  trip_point_xor;   
 
  -- **************** instantiate phy_ocb_mon ****************

  u_qdr_rld_phy_ocb_mon : qdr_rld_phy_ocb_mon 
  generic map(
    SIM_CAL_OPTION  => SIM_CAL_OPTION,
    SIM_INIT_OPTION => SIM_INIT_OPTION,
    TCQ             => TCQ
     )
  port map(
    dbg_ocb_mon        => open,
    ocb_mon_PSEN       => pd_psen,
    ocb_mon_PSINCDEC   => pd_incdec,
    ocb_mon_calib_done => pd_calib_done_int,
    ocb_wc             => open,
    ocb_extend         => trip_point_1,
    ocb_mon_PSDONE     => '1',
    ocb_mon_go         => pd_calib_start,
    clk                => clk_rd,
    rst                => rst_clk_rd,
    ocb_enabled_n      => '0'          --always enabled
    );
   
  pd_en_maintain <= pd_psen and pd_calib_done_int and not(dbg_pd_off);
  pd_en_calib    <= pd_psen and not(pd_calib_done_int) and first_calib_n;
  
  pd_incdec_calib    <= pd_incdec;
  pd_incdec_maintain <= not(pd_incdec) and not(dbg_pd_off); 
  
  -- Prevent the taps from overflowing or underflowing by capping them at their
  -- minimum or maximum value
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        pd_en_calib_int <= '0' after TCQ*1 ps;         
      elsif (pd_en_calib = '1') then
        if (pd_incdec = '1') then
             pd_en_calib_int   <= not(and_br(cnt_value_out)) after TCQ*1 ps;
        else
             pd_en_calib_int   <= or_br(cnt_value_out) after TCQ*1 ps;
        end if;
      else
        pd_en_calib_int <= '0' after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  --need to register the "inc" signals to make sure they align with the "ce"
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then 
         pd_incdec_int  <= '0' after TCQ*1 ps;
      else
         pd_incdec_int  <= pd_incdec after TCQ*1 ps;
      end if;
    end if;
 end process;  
   
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        tap_count <= "00000" after TCQ*1 ps;         
      elsif (pd_en_calib = '1' and pd_incdec = '1') then
        tap_count <= (tap_count + 1) after TCQ*1 ps;
      elsif (pd_en_calib = '1' and pd_incdec = '0') then
        tap_count <= (tap_count - 1) after TCQ*1 ps;
      else
        tap_count <= tap_count after TCQ*1 ps;
      end if;
    end if;
  end process;

  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        pd_calib_error_int  <= '0' after TCQ*1 ps;       
      elsif (pd_en_calib = '1' and pd_incdec = '1' and (and_br(cnt_value_out) = '1')) then
        pd_calib_error_int  <= not(pd_calib_done_int) after TCQ*1 ps;  
      else 
        pd_calib_error_int  <= pd_calib_error_int after TCQ*1 ps;
      end if;
    end if;
  end process;

end architecture arch;
