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
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 3.9
--  \   \         Application        : MIG
--  /   /         Filename           : phy_d_q_io.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 07:18:32 $
-- \   \  /  \    Date Created       : Nov 19, 2008
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--  This module
--  1. Is the I/O module for the entire D & Q bus for a single memory.
--  2. Instantiates the phy_read_v6_d_q_io module for each bit in the memory.
--
--Revision History:
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity phy_d_q_io is
  generic(
    BYTE_WIDTH           : integer := 18;            -- clk:data ratio
    REFCLK_FREQ          : real    := 300.0;         -- Reference Clock Freq(Mhz)
    MEM_TYPE             : string  := "QDR2PLUS";    -- Memory Type
    ODELAY_VAL           : integer := 0;             -- value to delay data
    IODELAY_GRP          : string  := "IODELAY_MIG"; -- May be assigned unique name 
    HIGH_PERFORMANCE_MODE: boolean := TRUE;          -- IODELAY High Perf Mode
    IBUF_LOW_PWR         : boolean := FALSE;         -- Input buffer low power mode
    SIM_INIT_OPTION      : string  := "NONE";        -- Simulation only. "NONE", "SIM_MODE"
    TCQ                  : integer := 100            -- Register delay
    );
  port(
    -- System signals
    clk         : in std_logic;       -- system clock
    rst_wr_clk  : in std_logic;       -- reset syncronized to clk
    clk_mem     : in std_logic;       -- high frequency system clock
    wr_en       : in std_logic_vector(3 downto 0); -- tri-state control
    clk_cq      : in std_logic;       -- CQ from BUFIO
    clk_cqn     : in std_logic;       -- CQ# from BUFIO
    clk_rd      : in std_logic;       -- half freq CQ clock from BUFR
    rst_clk_rd  : in std_logic;        -- reset syncrhonized to clk_rd
   
    -- Memory Interface
    mem_q         : in     std_logic_vector(BYTE_WIDTH-1 downto 0);  -- Q from memory
    mem_d         : out    std_logic_vector(BYTE_WIDTH-1 downto 0);  -- D to memory
    mem_dq        : inout  std_logic_vector(BYTE_WIDTH-1 downto 0);  -- DQ to/from memory
           
    -- PHY Write Interface
    data_rise0    : in     std_logic_vector(BYTE_WIDTH-1 downto 0);   
    data_fall0    : in     std_logic_vector(BYTE_WIDTH-1 downto 0);   
    data_rise1    : in     std_logic_vector(BYTE_WIDTH-1 downto 0);   
    data_fall1    : in     std_logic_vector(BYTE_WIDTH-1 downto 0);   
                
    -- IDELAY control
    -- Q IDELAY clock enable
    q_dly_ce      : in     std_logic_vector(BYTE_WIDTH-1 downto 0);   
    -- Q IDELAY increment  
    q_dly_inc     : in     std_logic;                                   
    -- Q IDELAY reset
    q_dly_rst     : in     std_logic_vector(BYTE_WIDTH-1 downto 0);     
    -- Q IDELAY cntvaluein load value
    q_dly_load    : in     std_logic_vector(4 downto 0);                
    -- Q IDELAY tap settings concatenated together
    q_dly_tap     : out    std_logic_vector(BYTE_WIDTH*5-1 downto 0);   
                                                                        
    -- ISERDES control
    q_dly_clkinv  : in     std_logic; -- Q IDELAY CLK inversion
    
    -- PHY Read Interface
    iserdes_rst  : in      std_logic;
    -- ISERDES Q4 -rise data 0
    iserdes_rd0  : out     std_logic_vector(BYTE_WIDTH-1 downto 0);  
    -- ISERDES Q3 -fall data 0  
    iserdes_fd0  : out     std_logic_vector(BYTE_WIDTH-1 downto 0);   
    -- ISERDES Q2 -rise data 1
    iserdes_rd1  : out     std_logic_vector(BYTE_WIDTH-1 downto 0);   
    -- ISERDES Q1 -fall data 1
    iserdes_fd1  : out     std_logic_vector(BYTE_WIDTH-1 downto 0)

);
end phy_d_q_io;

architecture arch of phy_d_q_io is

  -- Component delcarations
  component phy_v6_d_q_io
  generic(
    REFCLK_FREQ           : real   ;               -- Reference Clock Freq(Mhz)
    MEM_TYPE              : string ;               -- Memory Type
    ODELAY_VAL            : integer;               -- Value to delay data
    IODELAY_GRP           : string ;               -- May be assigned unique name 
    HIGH_PERFORMANCE_MODE : boolean;               -- IODELAY High Perf Mode
    IBUF_LOW_PWR          : boolean;               -- Input buffer low power mode
    SIM_INIT_OPTION       : string ;               -- Simulation only. 
    TCQ                   : integer                 -- Register delay
  );
  port(
    -- System signals
    clk                   : in std_logic;          -- system clock
    rst_wr_clk            : in std_logic;          -- reset syncronized to clk
    clk_mem               : in std_logic;          -- high frequency system clock
    wr_en                 : in std_logic_vector(3 downto 0); -- tri-state control
    clk_cq                : in std_logic;          -- CQ from BUFIO
    clk_cqn               : in std_logic;          -- CQ# from BUFIO
    clk_rd                : in std_logic;          -- half freq CQ clock from BUFR
    rst_clk_rd            : in std_logic;          -- reset syncrhonized to clk_rd

    -- Memory Interface
    mem_q                 : in std_logic;          -- Q from memory
    mem_d                 : out std_logic;         -- D to memory
    mem_dq                : inout std_logic;       -- DQ to/from memory
    
    -- PHY Write Interface
    data_rise0            : in std_logic; 
    data_fall0            : in std_logic;  
    data_rise1            : in std_logic;   
    data_fall1            : in std_logic;

    -- IDELAY control
    q_dly_ce              : in std_logic;         -- Q IDELAY clock enable
    q_dly_inc             : in std_logic;         -- Q IDELAY increment
    q_dly_inc_int         : in std_logic;         -- Q IDELAY increment delayed
    q_dly_rst             : in std_logic;         -- Q IDELAY reset
    q_dly_load            : in std_logic_vector(4 downto 0);  -- Q IDELAY cntvaluein load value
    q_dly_tap             : out std_logic_vector(4 downto 0); -- Q IDELAY tap setting
    
    -- ISERDES control
    q_dly_clkinv          : in std_logic;         -- Q IDELAY CLK inversion
    
    -- PHY Read Interface
    iserdes_rst_int       : in  std_logic;        -- ISERDES rst
    iserdes_rd0           : out std_logic;        -- ISERDES Q4 output - rise data 0
    iserdes_fd0           : out std_logic;        -- ISERDES Q3 output - fall data 0
    iserdes_rd1           : out std_logic;        -- ISERDES Q2 output - rise data 1
    iserdes_fd1           : out std_logic        -- ISERDES Q1 output - fall data 1
    
  );
  end component;

  -- Signal Declarations
  signal iserdes_rst_int : std_logic;
  signal q_dly_inc_int   : std_logic;

  attribute max_fanout : string;
  attribute max_fanout of iserdes_rst_int : signal is "1";
  attribute max_fanout of q_dly_inc_int   : signal is "1";
  
begin

  -- Register ISERDES reset to help with timing
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        iserdes_rst_int <= '0' after TCQ*1 ps;
      else
        iserdes_rst_int <= iserdes_rst after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  -- Need to register the Q "inc" signals to make sure they align with the "ce"
  process (clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        q_dly_inc_int <= '0' after TCQ*1 ps;
      else
        q_dly_inc_int <= q_dly_inc after TCQ*1 ps;
      end if;
    end if;
  end process;


  d_q_mem_inst:
  for mw_i in 0 to BYTE_WIDTH-1 generate
    begin
    d_q_inst : phy_v6_d_q_io 
    generic map(
      REFCLK_FREQ          => REFCLK_FREQ,
      MEM_TYPE             => MEM_TYPE,
      ODELAY_VAL           => ODELAY_VAL,
      IODELAY_GRP          => IODELAY_GRP,
      HIGH_PERFORMANCE_MODE=> HIGH_PERFORMANCE_MODE,
      IBUF_LOW_PWR         => IBUF_LOW_PWR,
      SIM_INIT_OPTION      => SIM_INIT_OPTION,
      TCQ                  => TCQ
    )  
    port map( 
      --System Signals
      clk              => clk,
      rst_wr_clk       => rst_wr_clk,
      --Write Interface
      clk_mem          => clk_mem,  
      data_rise0       => data_rise0(mw_i),
      data_fall0       => data_fall0(mw_i),
      data_rise1       => data_rise1(mw_i),
      data_fall1       => data_fall1(mw_i),
      mem_d            => mem_d(mw_i),
      --Bidirectional Interface
      wr_en            => wr_en,
      mem_dq           => mem_dq(mw_i),
      --Read Interface
      clk_cq           => clk_cq,
      clk_cqn          => clk_cqn,
      clk_rd           => clk_rd,
      rst_clk_rd       => rst_clk_rd,
      mem_q            => mem_q(mw_i),
      q_dly_ce         => q_dly_ce(mw_i),
      q_dly_inc        => q_dly_inc,
      q_dly_inc_int    => q_dly_inc_int,
      q_dly_rst        => q_dly_rst(mw_i),
      q_dly_load       => q_dly_load,
      q_dly_tap        => q_dly_tap((mw_i+1)*5-1 downto mw_i*5),
      q_dly_clkinv     => q_dly_clkinv,
      iserdes_rst_int  => iserdes_rst_int,
      iserdes_rd0      => iserdes_rd0(mw_i),
      iserdes_fd0      => iserdes_fd0(mw_i),
      iserdes_rd1      => iserdes_rd1(mw_i),
      iserdes_fd1      => iserdes_fd1(mw_i)
      );
  end generate;

end architecture arch;
