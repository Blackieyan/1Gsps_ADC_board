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
--/////////////////////////////////////////////////////////////////////////////
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 3.9
--  \   \         Application        : MIG
--  /   /         Filename           : phy_iob.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 07:18:32 $
-- \   \  /  \    Date Created       : Nov 18, 2008 
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This module
--  1. Instantiates all the modules that use the IOBs
--Revision History:
--
--/////////////////////////////////////////////////////////////////////////////
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity phy_iob is
  generic(
    DATA_WIDTH      : integer := 72;      -- Data Width
    ADDR_WIDTH      : integer := 19;      -- Adress Width
    BW_WIDTH        : integer := 8;       -- Byte Write Width
    MEM_TYPE        : string  := "QDR2PLUS";     -- Memory Type (QDR2PLUS; QDR2)
    REFCLK_FREQ     : real    := 300.0;   -- Reference Clk Feq for IODELAYs
    CLK_PERIOD      : integer := 3752;    -- Internal Fabric Clk Period (ps)
    BURST_LEN       : integer := 4;       -- Burst Length
    NUM_DEVICES     : integer := 2;       -- Memory Devices
    IODELAY_GRP     : string  := "IODELAY_MIG";-- May be assigned unique name 
                                               -- when mult IP cores in design
    DEVICE_TAPS     : integer := 32;      -- Number of taps in target IODELAY
    TAP_BITS        : integer := 5;       -- Number of bits needed to represent
                                          -- DEVICE_TAPS
    MEMORY_WIDTH    : integer := 36;      -- Width of each memory
    IBUF_LPWR_MODE  : string  := "OFF";   -- Input buffer low power mode
    IODELAY_HP_MODE : string  := "ON";    -- IODELAY High Performance Mode
    SIM_INIT_OPTION : string  := "NONE";  -- Simulation only. "NONE", "SIM_MODE"
    TCQ             : integer := 100      -- Register Delay
  );
  port(
    -- System Signals
    clk              : in std_logic;      -- main system half freq clk   
    rst_clk         : in std_logic;       
    rst_wr_clk       : in std_logic;      -- main write path reset 
    clk_mem          : in std_logic;      -- full frequency clock
    -- half freq CQ clock
    clk_rd           : out std_logic_vector(NUM_DEVICES-1 downto 0);        
    -- reset syncrhonized to clk_rd
    rst_clk_rd       : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    iserdes_rst      : in std_logic_vector(NUM_DEVICES-1 downto 0);          

    -- Write Path : in std_logics                                
    -- internal rd cmd
    int_rd_cmd_n     : in std_logic_vector(1 downto 0);              
    -- internal rd cmd
    int_wr_cmd_n     : in std_logic_vector(1 downto 0);              
    -- OSERDES addr rise0
    iob_addr_rise0   : in std_logic_vector(ADDR_WIDTH-1 downto 0);   
    -- OSERDES addr fall0
    iob_addr_fall0   : in std_logic_vector(ADDR_WIDTH-1 downto 0);   
    -- OSERDES addr rise1
    iob_addr_rise1   : in std_logic_vector(ADDR_WIDTH-1 downto 0);   
    -- OSERDES addr fall1
    iob_addr_fall1   : in std_logic_vector(ADDR_WIDTH-1 downto 0);   
    -- OSERDES d rise0
    iob_data_rise0   : in std_logic_vector(DATA_WIDTH-1 downto 0);   
    -- OSERDES d fall0
    iob_data_fall0   : in std_logic_vector(DATA_WIDTH-1 downto 0);   
    -- OSERDES d rise1
    iob_data_rise1   : in std_logic_vector(DATA_WIDTH-1 downto 0);   
    -- OSERDES d fall1
    iob_data_fall1   : in std_logic_vector(DATA_WIDTH-1 downto 0);   
    -- OSERDES bw rise0
    iob_bw_rise0     : in std_logic_vector(BW_WIDTH-1 downto 0);     
    -- OSERDES bw fall0
    iob_bw_fall0     : in std_logic_vector(BW_WIDTH-1 downto 0);     
    -- OSERDES bw rise1
    iob_bw_rise1     : in std_logic_vector(BW_WIDTH-1 downto 0);     
    -- OSERDES bw fall1
    iob_bw_fall1     : in std_logic_vector(BW_WIDTH-1 downto 0);     
    
    -- Read Path Signals
    -- CQ BUFIO clock
    clk_cq           : out std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- CQ# BUFIO clock
    clk_cqn          : out std_logic_vector(NUM_DEVICES-1 downto 0);
    -- RLDRAM II PD Source
    pd_source        : out std_logic_vector(NUM_DEVICES-1 downto 0);
    -- CQ IDELAY clock enable
    cq_dly_ce        : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- CQ IDELAY increment
    cq_dly_inc       : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- CQ IDELAY reset
    cq_dly_rst       : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- CQ IDELAY cntvaluein
    cq_dly_load      : in std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0); 
    -- CQ IDELAY tap settings
    dbg_cq_tapcnt     : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);  
    -- CQ# IDELAY clock enable
    cqn_dly_ce       : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- CQ# IDELAY increment
    cqn_dly_inc      : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- CQ# IDELAY reset
    cqn_dly_rst      : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- CQ# IDELAY cntvaluein
    cqn_dly_load     : in std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0); 
    -- CQ# IDELAY tap settings
    dbg_cqn_tapcnt    : out std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0); 
    -- Q IDELAY clock enable
    q_dly_ce         : in std_logic_vector(DATA_WIDTH-1 downto 0);           
    -- Q IDELAY increment
    q_dly_inc        : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- Q IDELAY reset
    q_dly_rst        : in std_logic_vector(DATA_WIDTH-1 downto 0);           
    -- Q IDELAY cntvaluein
    q_dly_load       : in std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0); 
    -- Q IDELAY tap settings
    dbg_q_tapcnt      : out std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0);  
    -- Q IDELAY CLK inversion
    q_dly_clkinv     : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- ISERDES Q4 -rise data 0
    iserdes_rd0        : out std_logic_vector(DATA_WIDTH-1 downto 0);           
    -- ISERDES Q3 -fall data 0
    iserdes_fd0      : out std_logic_vector(DATA_WIDTH-1 downto 0);           
    -- ISERDES Q2 -rise data 1
    iserdes_rd1      : out std_logic_vector(DATA_WIDTH-1 downto 0);           
    -- ISERDES Q1 -fall data 1
    iserdes_fd1      : out std_logic_vector(DATA_WIDTH-1 downto 0);           
    dbg_clk_rd        : out std_logic_vector(NUM_DEVICES-1 downto 0);          

    -- Memory Interface Signals
    -- clock K
    mem_k_p          : out std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- clock K#
    mem_k_n          : out std_logic_vector(NUM_DEVICES-1 downto 0);          
    --  Memory Address
    mem_sa           : out std_logic_vector(ADDR_WIDTH-1 downto 0);           
    -- Write Cmd
    mem_w_n          : out std_logic;                                 
    -- Read Cmd
    mem_r_n          : out std_logic;                                 
    -- Byte Writes to Memory
    mem_bw_n         : out std_logic_vector(BW_WIDTH-1 downto 0);             
    -- Data to Memory
    mem_d            : out std_logic_vector(DATA_WIDTH-1 downto 0);           
    -- CQ echo clock
    mem_cq_p         : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- CQ# echo clock
    mem_cq_n         : in std_logic_vector(NUM_DEVICES-1 downto 0);          
    -- Q data
    mem_q            : in std_logic_vector(DATA_WIDTH-1 downto 0)  
  );
end phy_iob;

architecture arch of phy_iob is

  -- Calculate the tap resolution based on the Reference Clock
  constant  IODELAY_TAP_RES   : integer := 
                                1000000 / (integer(REFCLK_FREQ) * 64);

  constant  SHIFT_BY4         : integer := 
                                ((CLK_PERIOD/2) / (4 * IODELAY_TAP_RES));

  -- Select the address delay value for IODELAY depending on BL
  function CALC_ODELAY_VAL return integer is
  begin
    if (BURST_LEN = 4) then
      return SHIFT_BY4;
    else
      return 0;
    end if;
  end function CALC_ODELAY_VAL;
  constant   ODELAY_ADDR_VAL    : integer := CALC_ODELAY_VAL;

  -- Enable low power mode for input buffer
  function CALC_IBUF_LOW_PWR return boolean is
  begin
    if (IBUF_LPWR_MODE = "OFF") then
      return FALSE;
    else 
      return TRUE;
    end if;
  end function CALC_IBUF_LOW_PWR;
  constant IBUF_LOW_PWR       : boolean := CALC_IBUF_LOW_PWR;

  -- Set performance mode for IODELAY (power vs. performance tradeoff)
  function CALC_HIGH_PERFORMANCE_MODE return boolean is
  begin
    if (IODELAY_HP_MODE = "OFF") then
      return FALSE;
    else
      return TRUE;
    end if;
  end function CALC_HIGH_PERFORMANCE_MODE;
  constant HIGH_PERFORMANCE_MODE : boolean := CALC_HIGH_PERFORMANCE_MODE;
                                     
  signal cq_dly_tap        : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal cqn_dly_tap       : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal q_dly_tap         : std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0); 
  signal cq_dly_tap_r      : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal cqn_dly_tap_r     : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal q_dly_tap_r       : std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0); 
  signal cq_dly_tap_2r     : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal cqn_dly_tap_2r    : std_logic_vector(TAP_BITS*NUM_DEVICES-1 downto 0);
  signal q_dly_tap_2r      : std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0); 
  
  signal clk_rd_sig        : std_logic_vector(NUM_DEVICES-1 downto 0); 
  signal clk_cq_sig        : std_logic_vector(NUM_DEVICES-1 downto 0);
  signal clk_cqn_sig       : std_logic_vector(NUM_DEVICES-1 downto 0);
  
  component phy_oserdes_io 
  generic(
    ODELAY_VAL    : integer;  -- value to delay clk_wr
    REFCLK_FREQ   : real;     -- Ref Clk Freq. for IODELAYs
    IODELAY_GRP   : string ;  -- May be assigned unique name 
                              -- when mult IP cores in design
    -- IODELAY High Performance Mode
    HIGH_PERFORMANCE_MODE     : boolean ;  
    INIT_OQ_VAL   : bit ;
    DIFF_OUT      : integer  -- Use Differential Ouputs Buffer
  );
  port(
    clk           : in std_logic;    
    rst_wr_clk    : in std_logic;   
    clk_mem       : in std_logic;   
    data_rise0    : in std_logic;    
    data_fall0    : in std_logic;     
    data_rise1    : in std_logic;      
    data_fall1    : in std_logic;       
    data_out_p    : out std_logic;  
    data_out_n    : out std_logic  
  ); 
  end component;
  
  
  component phy_read_clk_io
  generic(
     REFCLK_FREQ           : real;      -- Indicates the IDELAYCTRL 
                                        -- reference clock frequency
     IODELAY_GRP           : string ;   -- May be assigned unique name 
     MEM_TYPE              : string ;     -- Memory Type (QDR2PLUS; QDR2)
     HIGH_PERFORMANCE_MODE : boolean ;  -- IODELAY High PerfMode
     IBUF_LOW_PWR          : boolean ;  -- Input buffer low power mode
     TCQ                   : integer    -- Register delay
  );
  port(
  -- Memory Interface
    mem_cq        : in std_logic;    -- CQ clock from the memory
    mem_cq_n      : in std_logic;    -- CQ# clock from the memory
  
  -- IDELAY control
    cal_clk       : in std_logic;       -- IDELAY clock used for dynamic inc/dec
    cq_dly_ce     : in std_logic;       -- CQ IDELAY clock enable
    cq_dly_inc    : in std_logic;       -- CQ IDELAY increment
    cq_dly_rst    : in std_logic;       -- CQ IDELAY reset
    -- CQ IDELAY cntvaluein load value
    cq_dly_load   : in std_logic_vector(4 downto 0);  
    -- CQ IDELAY tap settings concatenated
    cq_dly_tap    : out std_logic_vector(4 downto 0);  
  
    cqn_dly_ce    : in std_logic;              -- CQ# IDELAY clock enable
    cqn_dly_inc   : in std_logic;              -- CQ# IDELAY increment
    cqn_dly_rst   : in std_logic;              -- CQ# IDELAY reset
    -- CQ# IDELAY cntvaluein load value
    cqn_dly_load  : in std_logic_vector(4 downto 0);  
    -- CQ# IDELAY tap settings concatenated
    cqn_dly_tap   : out std_logic_vector(4 downto 0);  

  -- PHY Read Interface
    clk_cq        : out std_logic;              -- BUFIO CQ : out std_logic;
    clk_cqn       : out std_logic;              -- BUFIO CQ# : out std_logic;
    clk_rd        : out std_logic;              -- BUFR half frequency CQ output
    pd_source     : out std_logic;              -- RLDRAM II PD Source
    rst_clk_rd    : in  std_logic               -- Rest Sync to CLK RD
  );
  end component;
  
  component phy_d_q_io
  generic(
    BYTE_WIDTH            : integer;   -- clk:data ratio
    REFCLK_FREQ           : real;      -- Reference Clock Freq(Mhz)
    MEM_TYPE              : string;     -- Memory Type (QDR2PLUS; QDR2)
    ODELAY_VAL            : integer;   -- value to delay data
    IODELAY_GRP           : string;    -- May be assigned unique name 
    HIGH_PERFORMANCE_MODE : boolean ;  -- IODELAY High Perf Mode
    IBUF_LOW_PWR          : boolean;   -- Input buffer low power mode
    SIM_INIT_OPTION       : string;    -- Simulation only. "NONE", "SIM_MODE"
    TCQ                   : integer     -- Register delay
   );
  port(
  -- System signals
    clk           : in std_logic;               -- system clock
    rst_wr_clk    : in std_logic;               -- reset syncronized to clk
    clk_mem       : in std_logic;               -- high frequency system clock
    wr_en         : in std_logic_vector(3 downto 0);       -- tri-state control
    clk_cq        : in std_logic;               -- CQ from BUFIO
    clk_cqn       : in std_logic;               -- CQ# from BUFIO
    clk_rd        : in std_logic;               -- half freq CQ clock from BUFR
    rst_clk_rd    : in std_logic;               -- reset syncrhonized to clk_rd
    
    -- Memory Interface
    -- Q from memory
    mem_q         : in  std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    -- D to memory
    mem_d         : out std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    -- DQ to/from memory
    mem_dq        : inout std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    
    -- PHY Write Interface
    data_rise0  : in std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    data_fall0  : in std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    data_rise1  : in std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    data_fall1  : in std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    
    -- IDELAY control
    -- Q IDELAY clock enable
    q_dly_ce      : in std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    -- Q IDELAY increment
    q_dly_inc     : in std_logic;                          
     -- Q IDELAY reset
    q_dly_rst     : in std_logic_vector(MEMORY_WIDTH-1 downto 0);  
    -- Q IDELAY cntvaluein load value
    q_dly_load    : in std_logic_vector(4 downto 0);              
    -- Q IDELAY tap settings 
    q_dly_tap     : out std_logic_vector(MEMORY_WIDTH*5-1 downto 0); 
    
    -- ISERDES control
    q_dly_clkinv  : in std_logic;            -- Q IDELAY CLK inversion
    
    -- PHY Read Interface
    iserdes_rst   : in std_logic;
    -- ISERDES Q4 -rise data 0
    iserdes_rd0   : out std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    -- ISERDES Q3 -fall data 0
    iserdes_fd0   : out std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    -- ISERDES Q2 -rise data 1
    iserdes_rd1   : out std_logic_vector(MEMORY_WIDTH-1 downto 0);   
    -- ISERDES Q1 -fall data 1
    iserdes_fd1   : out std_logic_vector(MEMORY_WIDTH-1 downto 0)  
);
  end component;
  begin

  dbg_clk_rd <= clk_rd_sig;
  clk_rd     <= clk_rd_sig;
  clk_cq     <= clk_cq_sig;
  clk_cqn     <= clk_cqn_sig;
  

  DBG_DLY_INST:
  for dbg_nd_i in 0 to (NUM_DEVICES-1) generate
  begin
    
    process(clk_rd_sig(dbg_nd_i))
    begin
      if (clk_rd_sig(dbg_nd_i)'event and clk_rd_sig(dbg_nd_i) = '1') then
         if (rst_clk_rd(dbg_nd_i) = '1') then
            cq_dly_tap_r  (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                              <= (others => '0') after TCQ*1 ps;         
            cqn_dly_tap_r (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                              <= (others => '0') after TCQ*1 ps;  
            q_dly_tap_r   ((TAP_BITS*(dbg_nd_i+1)*MEMORY_WIDTH)-1 downto (dbg_nd_i*TAP_BITS*MEMORY_WIDTH))  <= (others => '0') after TCQ*1 ps;
            cq_dly_tap_2r (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                              <= (others => '0') after TCQ*1 ps;       
            cqn_dly_tap_2r(TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                              <= (others => '0') after TCQ*1 ps;
            q_dly_tap_2r  ((TAP_BITS*(dbg_nd_i+1)*MEMORY_WIDTH)-1 downto (dbg_nd_i*TAP_BITS*MEMORY_WIDTH))  <= (others => '0') after TCQ*1 ps;
            dbg_cq_tapcnt (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                              <= (others => '0') after TCQ*1 ps;        
            dbg_cqn_tapcnt(TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                              <= (others => '0') after TCQ*1 ps;
            dbg_q_tapcnt  ((TAP_BITS*(dbg_nd_i+1)*MEMORY_WIDTH)-1 downto (dbg_nd_i*TAP_BITS*MEMORY_WIDTH))  <= (others => '0') after TCQ*1 ps;
         else 
            cq_dly_tap_r  (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                             <=  cq_dly_tap    (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS)) after TCQ*1 ps;         
            cqn_dly_tap_r (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                             <=  cqn_dly_tap   (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS)) after TCQ*1 ps;         
            cq_dly_tap_2r (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                             <=  cq_dly_tap_r  (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS)) after TCQ*1 ps;         
            cqn_dly_tap_2r(TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                             <=  cqn_dly_tap_r (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS)) after TCQ*1 ps;         
            dbg_cq_tapcnt (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                             <=  cq_dly_tap_2r (TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS)) after TCQ*1 ps;         
            dbg_cqn_tapcnt(TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS))                             <=  cqn_dly_tap_2r(TAP_BITS*(dbg_nd_i+1)-1 downto (dbg_nd_i*TAP_BITS)) after TCQ*1 ps;
            q_dly_tap_r   ((TAP_BITS*(dbg_nd_i+1)*MEMORY_WIDTH)-1 downto (dbg_nd_i*TAP_BITS*MEMORY_WIDTH)) <=  q_dly_tap     ((TAP_BITS*(dbg_nd_i+1)*MEMORY_WIDTH)-1 downto (dbg_nd_i*TAP_BITS*MEMORY_WIDTH)) after TCQ*1 ps;
            q_dly_tap_2r  ((TAP_BITS*(dbg_nd_i+1)*MEMORY_WIDTH)-1 downto (dbg_nd_i*TAP_BITS*MEMORY_WIDTH)) <=  q_dly_tap_r   ((TAP_BITS*(dbg_nd_i+1)*MEMORY_WIDTH)-1 downto (dbg_nd_i*TAP_BITS*MEMORY_WIDTH)) after TCQ*1 ps;
            dbg_q_tapcnt  ((TAP_BITS*(dbg_nd_i+1)*MEMORY_WIDTH)-1 downto (dbg_nd_i*TAP_BITS*MEMORY_WIDTH)) <=  q_dly_tap_2r  ((TAP_BITS*(dbg_nd_i+1)*MEMORY_WIDTH)-1 downto (dbg_nd_i*TAP_BITS*MEMORY_WIDTH)) after TCQ*1 ps;
         end if;
      end if;
   end process;  
  end generate;
 
 
  --Instantiate the OSERDES to clock out single ended K clocks 
  clk_inst :
  for clk_i in 0 to (NUM_DEVICES-1) generate
  begin
    u_phy_oserdes_clk : phy_oserdes_io 
    generic map(
        ODELAY_VAL              => SHIFT_BY4,
        REFCLK_FREQ             => REFCLK_FREQ,
        IODELAY_GRP             => IODELAY_GRP,
        HIGH_PERFORMANCE_MODE   => HIGH_PERFORMANCE_MODE,   
        INIT_OQ_VAL             => '1',    
        DIFF_OUT                => 0
      )  
    port map(
        clk                     => clk ,
        rst_wr_clk              => rst_wr_clk ,
        clk_mem                 => clk_mem ,
        data_rise0              => '0', 
        data_fall0              => '1',  
        data_rise1              => '0',   
        data_fall1              => '1',    
        data_out_p              => mem_k_p(clk_i) , 
        data_out_n              => open
      );                     
  end generate;
  
  --Instantiate the OSERDES to clock out single ended K# clocks 
  clkn_inst :
  for clkn_i in 0 to (NUM_DEVICES-1) generate
  begin
    u_phy_oserdes_clk : phy_oserdes_io 
    generic map(
        ODELAY_VAL              => SHIFT_BY4,
        REFCLK_FREQ             => REFCLK_FREQ,
        IODELAY_GRP             => IODELAY_GRP,
        HIGH_PERFORMANCE_MODE   => HIGH_PERFORMANCE_MODE,  
        INIT_OQ_VAL             => '0',  
        DIFF_OUT                => 0
      )  
    port map(
        clk                     => clk ,
        rst_wr_clk              => rst_wr_clk ,
        clk_mem                 => clk_mem ,
        data_rise0              => '1', 
        data_fall0              => '0',  
        data_rise1              => '1',   
        data_fall1              => '0',    
        data_out_p              => mem_k_n(clkn_i) , 
        data_out_n              => open
      );                     
  end generate;
   
  
  -- Instantiate an OSERDES for the read and write command lines
  -- delay the clock for read/write commands.  this does not need a delay
  -- value but is inserted to maintain delay across commands and addressing
  -- which encounter a minor delay through the IODELAYE1 primitive
  u_phy_oserdes_rd : phy_oserdes_io 
  generic map(
    ODELAY_VAL            => SHIFT_BY4, 
    REFCLK_FREQ           => REFCLK_FREQ, 
    IODELAY_GRP           => IODELAY_GRP, 
    HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE, 
    INIT_OQ_VAL             => '0',  
    DIFF_OUT              => 0
  )  
  port map(
    clk          => clk, 
    rst_wr_clk   => rst_wr_clk,
    clk_mem      => clk_mem,
    data_rise0   => int_rd_cmd_n(0),  
    data_fall0   => int_rd_cmd_n(0),   
    data_rise1   => int_rd_cmd_n(1),    
    data_fall1   => int_rd_cmd_n(1),     
    data_out_p   => mem_r_n,  
    data_out_n   => open
  );
  
  u_phy_oserdes_wr : phy_oserdes_io 
  generic map(
    ODELAY_VAL           => SHIFT_BY4,
    REFCLK_FREQ          => REFCLK_FREQ,
    IODELAY_GRP          => IODELAY_GRP,
    HIGH_PERFORMANCE_MODE=> HIGH_PERFORMANCE_MODE, 
    INIT_OQ_VAL             => '0',  
    DIFF_OUT             => 0
  ) 
  port map( 
    clk          => clk,
    rst_wr_clk   => rst_wr_clk,
    clk_mem      => clk_mem,
    data_rise0   => int_wr_cmd_n(0), 
    data_fall0   => int_wr_cmd_n(0),  
    data_rise1   => int_wr_cmd_n(1),   
    data_fall1   => int_wr_cmd_n(1),    
    data_out_p   => mem_w_n,
    data_out_n   => open
  );

  -- Instantiate an OSERDES for each bit of the address
  -- Delay output by .25 to center align the address.  This is only used with
  -- BURST_LEN == 2.  Otherwise the delay value is 0
  oserdes_addr :
  for aw_i in 0 to (ADDR_WIDTH-1) generate
  begin
    u_phy_oserdes_addr : phy_oserdes_io 
    generic map(
      ODELAY_VAL           => ODELAY_ADDR_VAL,
      REFCLK_FREQ          => REFCLK_FREQ,
      IODELAY_GRP          => IODELAY_GRP,
      HIGH_PERFORMANCE_MODE=> HIGH_PERFORMANCE_MODE,
      INIT_OQ_VAL             => '0',  
      DIFF_OUT             => 0
      )  
    port map( 
      clk          => clk,
      rst_wr_clk   => rst_wr_clk,
      clk_mem      => clk_mem,
      data_rise0   => iob_addr_rise0(aw_i), 
      data_fall0   => iob_addr_fall0(aw_i),  
      data_rise1   => iob_addr_rise1(aw_i),   
      data_fall1   => iob_addr_fall1(aw_i),    
      data_out_p   => mem_sa(aw_i), 
      data_out_n   => open
    );
  end generate;

  -- Instantiate an OSERDES for each byte write bit to clock out the 
  -- byte writes 
  oserdes_bw : 
  for bw_i in 0 to (BW_WIDTH-1) generate
  begin
    u_phy_oserdes_bw : phy_oserdes_io 
    generic map(
      ODELAY_VAL           => 0,
      REFCLK_FREQ          => REFCLK_FREQ,
      IODELAY_GRP          => IODELAY_GRP,
      HIGH_PERFORMANCE_MODE=> HIGH_PERFORMANCE_MODE,
      INIT_OQ_VAL             => '0',  
      DIFF_OUT             => 0
      ) 
    port map( 
      clk          => clk,
      rst_wr_clk   => rst_wr_clk,
      clk_mem      => clk_mem,
      data_rise0   => iob_bw_rise0(bw_i), 
      data_fall0   => iob_bw_fall0(bw_i),  
      data_rise1   => iob_bw_rise1(bw_i),   
      data_fall1   => iob_bw_fall1(bw_i),    
      data_out_p   => mem_bw_n(bw_i),
      data_out_n   => open
      );
  end generate;

  -- Instantiate I/Os for read path
  clk_data_io :
  for nd_i in 0 to (NUM_DEVICES-1) generate
  begin 
    -- Instantiate the I/O logic for the CQ clock.
    u_phy_read_cq_io : phy_read_clk_io 
    generic map(
      REFCLK_FREQ           => REFCLK_FREQ,
      IODELAY_GRP           => IODELAY_GRP,
      MEM_TYPE              => MEM_TYPE,
      HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
      IBUF_LOW_PWR          => IBUF_LOW_PWR,
      TCQ                   => TCQ
      )  
    port map(
      mem_cq       => mem_cq_p(nd_i),
      mem_cq_n     => mem_cq_n(nd_i),
      cal_clk      => clk_rd_sig (nd_i),
      cq_dly_ce    => cq_dly_ce(nd_i),
      cq_dly_inc   => cq_dly_inc(nd_i),
      cq_dly_rst   => cq_dly_rst(nd_i),
      cq_dly_load  => cq_dly_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      cq_dly_tap   => cq_dly_tap(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      cqn_dly_ce   => cqn_dly_ce(nd_i),
      cqn_dly_inc  => cqn_dly_inc(nd_i),
      cqn_dly_rst  => cqn_dly_rst(nd_i),
      cqn_dly_load => cqn_dly_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      cqn_dly_tap  => cqn_dly_tap(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
      clk_cq       => clk_cq_sig(nd_i),
      clk_cqn      => clk_cqn_sig(nd_i),
      clk_rd       => clk_rd_sig(nd_i),
      pd_source    => pd_source(nd_i),
      rst_clk_rd   => rst_clk_rd(nd_i)
    );

    -- Instantiate the I/O logic for the D & Q data.
  u_phy_d_q_io : phy_d_q_io 
  generic map(
    BYTE_WIDTH           => MEMORY_WIDTH,
    REFCLK_FREQ          => REFCLK_FREQ,
    MEM_TYPE             => MEM_TYPE,
    ODELAY_VAL           => 0,
    IODELAY_GRP          => IODELAY_GRP,
    HIGH_PERFORMANCE_MODE=> HIGH_PERFORMANCE_MODE,
    IBUF_LOW_PWR         => IBUF_LOW_PWR,
    SIM_INIT_OPTION      => SIM_INIT_OPTION,
    TCQ                  => TCQ
  )  
  port map(
    -- System Signals
    clk         => clk,
    rst_wr_clk  => rst_wr_clk,        
    -- Write Interface
    clk_mem     => clk_mem,
    data_rise0  => iob_data_rise0(MEMORY_WIDTH*(nd_i+1)-1 downto 
                                  MEMORY_WIDTH*nd_i),
    data_fall0  => iob_data_fall0(MEMORY_WIDTH*(nd_i+1)-1 downto 
                                  MEMORY_WIDTH*nd_i),
    data_rise1  => iob_data_rise1(MEMORY_WIDTH*(nd_i+1)-1 downto 
                                  MEMORY_WIDTH*nd_i),
    data_fall1  => iob_data_fall1(MEMORY_WIDTH*(nd_i+1)-1 downto 
                                  MEMORY_WIDTH*nd_i),
    mem_d       => mem_d(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
    -- Bidirectional Interface
    wr_en       => "0000",
    mem_dq      => open,
    -- Read Interface
    clk_cq      => clk_cq_sig(nd_i),
    clk_cqn     => clk_cqn_sig(nd_i),
    clk_rd      => clk_rd_sig (nd_i),
    rst_clk_rd  => rst_clk_rd(nd_i),
    mem_q       => mem_q(MEMORY_WIDTH*(nd_i+1)-1 downto MEMORY_WIDTH*nd_i),
    q_dly_ce    => q_dly_ce(MEMORY_WIDTH*(nd_i+1)-1 
                                                 downto MEMORY_WIDTH*nd_i),
    q_dly_inc   => q_dly_inc(nd_i),
    q_dly_rst   => q_dly_rst(MEMORY_WIDTH*(nd_i+1)-1 
                                                  downto MEMORY_WIDTH*nd_i),
    q_dly_load  => q_dly_load(TAP_BITS*(nd_i+1)-1 downto TAP_BITS*nd_i),
    q_dly_tap   => q_dly_tap(MEMORY_WIDTH*TAP_BITS*(nd_i+1)-1 downto 
                             MEMORY_WIDTH*TAP_BITS*nd_i),
    q_dly_clkinv=> q_dly_clkinv(nd_i),
    iserdes_rst => iserdes_rst(nd_i),
    iserdes_rd0 => iserdes_rd0(MEMORY_WIDTH*(nd_i+1)-1 
                                            downto MEMORY_WIDTH*nd_i),
    iserdes_fd0 => iserdes_fd0(MEMORY_WIDTH*(nd_i+1)-1 
                                            downto MEMORY_WIDTH*nd_i),
    iserdes_rd1 => iserdes_rd1(MEMORY_WIDTH*(nd_i+1)-1 
                                            downto MEMORY_WIDTH*nd_i),
    iserdes_fd1 => iserdes_fd1(MEMORY_WIDTH*(nd_i+1)-1 
                                            downto MEMORY_WIDTH*nd_i)
    );
  end generate;

end architecture arch;

