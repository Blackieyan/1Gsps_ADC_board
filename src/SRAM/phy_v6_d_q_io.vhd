--*****************************************************************************
--(c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
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
--
--/////////////////////////////////////////////////////////////////////////////
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 3.9 
--  \   \         Application        : MIG
--  /   /         Filename           : phy_v6_d_q_io.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 07:18:33 $
-- \   \  /  \    Date Created       : Nov 19, 2008
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+ / RLDRAM-II
--
--Purpose:
--  This module
--  1. Is the I/O module for a single Q bit coming from the memory.
--  2. Instantiates the IBUF followed by the IDELAY to delay the Q and
--     then passes the data to the ISERDES for deserialization.
--
--Revision History:
--
--/////////////////////////////////////////////////////////////////////////////

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity phy_v6_d_q_io is
generic(
  REFCLK_FREQ           : real    := 300.0;         -- Reference Clock Freq(Mhz)
  MEM_TYPE              : string  := "QDR2PLUS";    -- Memory Type
  ODELAY_VAL            : integer := 0;             -- Value to delay data
  IODELAY_GRP           : string  := "IODELAY_MIG"; -- May be assigned unique name 
  HIGH_PERFORMANCE_MODE : boolean := TRUE;          -- IODELAY High Perf Mode
  IBUF_LOW_PWR          : boolean := FALSE;         -- Input buffer low power mode
  SIM_INIT_OPTION       : string  := "NONE";        -- Simulation only. "NONE", "SIM_MODE"
  TCQ                   : integer := 100            -- Register delay
);
port(
  -- System signals
  clk           : in std_logic;                     -- system clock
  rst_wr_clk    : in std_logic;                     -- reset syncronized to clk
  clk_mem       : in std_logic;                     -- high frequency system clock
  wr_en         : in std_logic_vector(3 downto 0);  -- tri-state control
  clk_cq        : in std_logic;                     -- CQ from BUFIO
  clk_cqn       : in std_logic;                     -- CQ# from BUFIO
  clk_rd        : in std_logic;                     -- half freq CQ clock from BUFR
  rst_clk_rd    : in std_logic;                     -- reset syncrhonized to clk_rd

  -- Memory Interface
  mem_q         : in std_logic;                     -- Q from memory
  mem_d         : out std_logic;                    -- D to memory
  mem_dq        : inout std_logic;                  -- DQ to/from memory
  
  -- PHY Write Interface
  data_rise0    : in std_logic; 
  data_fall0    : in std_logic;  
  data_rise1    : in std_logic;   
  data_fall1    : in std_logic;

  -- IDELAY control
  q_dly_ce      : in std_logic;                     -- Q IDELAY clock enable
  q_dly_inc     : in std_logic;                     -- Q IDELAY increment
  q_dly_inc_int : in std_logic;                     -- Q IDELAY increment delayed
  q_dly_rst     : in std_logic;                     -- Q IDELAY reset
  q_dly_load    : in std_logic_vector(4 downto 0);  -- Q IDELAY cntvaluein load value
  q_dly_tap     : out std_logic_vector(4 downto 0); -- Q IDELAY tap setting
  
  -- ISERDES control
  q_dly_clkinv  : in std_logic;                     -- Q IDELAY CLK inversion
  
  -- PHY Read Interface
  iserdes_rst_int : in std_logic;           -- ISERDES reset
  iserdes_rd0     : out std_logic;          -- ISERDES Q4 output - rise data 0
  iserdes_fd0     : out std_logic;          -- ISERDES Q3 output - fall data 0
  iserdes_rd1     : out std_logic;          -- ISERDES Q2 output - rise data 1
  iserdes_fd1     : out std_logic          -- ISERDES Q1 output - fall data 1
  
);
end entity phy_v6_d_q_io;

architecture arch of phy_v6_d_q_io is
  
  -- Component delcarations
  COMPONENT phy_oserdes_io
    generic(
      ODELAY_VAL            : integer := 0;             -- value to delay clk_wr
      REFCLK_FREQ           : real    := 300.0;         -- Ref Clk Freq. for IODELAYs
      IODELAY_GRP           : string  := "IODELAY_MIG"; -- May be assigned unique 
                                                        -- name when mult IP cores 
                                                        -- in design
      HIGH_PERFORMANCE_MODE : boolean := TRUE;          -- IODELAY High 
                                                        -- Performance Mode
      INIT_OQ_VAL           : bit     := '0';                                                    
      DIFF_OUT              : integer := 0              -- Use Differential 
                                                        -- Ouputs Buffer
    );
    PORT(
      clk         : IN std_logic;
      rst_wr_clk  : IN std_logic;
      clk_mem     : IN std_logic;
      data_rise0  : IN std_logic;
      data_fall0  : IN std_logic;
      data_rise1  : IN std_logic;
      data_fall1  : IN std_logic;          
      data_out_p  : OUT std_logic;
      data_out_n  : OUT std_logic
    );
  END COMPONENT;
  
  -- Signal Declarations
  signal q_ibuf           : std_logic;
  signal q_idelay         : std_logic;
  signal oserdes_d_out    : std_logic;
  signal iodelay_d_out    : std_logic;
  signal ocb_tfb          : std_logic;  -- Must be connected to T input of IODELAY
  signal dq_oe_n_r        : std_logic;  -- Connect OSERDES to IOBUF
  signal oserdes_oq       : std_logic;
  signal q_dly_clkinv_inv : std_logic;  -- Inverted q_dly_clkinv
  signal q_dly_ce_int     : std_logic;
  signal iserdes_rd0_int  : std_logic;
  signal iserdes_fd0_int  : std_logic;
  signal iserdes_rd1_int  : std_logic;
  signal iserdes_fd1_int  : std_logic;
  signal iserdes_fd1_int2 : std_logic;
  signal q_dly_tap_int    : std_logic_vector(4 downto 0);


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
  
  attribute IODELAY_GROUP : string;
  
  begin
    q_dly_tap       <= q_dly_tap_int;

  -- Prevent the taps from overflowing or underflowing by capping them at their
  -- minimum or maximum value
  process (clk_rd)
  begin
    if (clk_rd'event and clk_rd='1') then  
      if (rst_clk_rd = '1') then
        q_dly_ce_int <= '0' after TCQ*1 ps;
      elsif (q_dly_ce = '1') then
        if (q_dly_inc = '1') then
          q_dly_ce_int <= not(and_br(q_dly_tap_int)) after TCQ*1 ps;
        else
          q_dly_ce_int <= or_br(q_dly_tap_int) after TCQ*1 ps;
        end if;
      else
        q_dly_ce_int <= '0' after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  -- Register ISERDES output to do a bitslip
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd='1') then  
      if (rst_clk_rd = '1') then
         iserdes_fd1_int2 <= '0' after TCQ*1 ps;
      else 
        iserdes_fd1_int2 <= iserdes_fd1_int after TCQ*1 ps;
      end if;
    end if; 
  end process;
  
  -- Register ISERDES outputs for better timing
  process (clk_rd) 
  begin
    if (clk_rd'event and clk_rd='1') then  
      if (rst_clk_rd = '1') then
        iserdes_rd0 <= '0' after TCQ*1 ps;
        iserdes_fd0 <= '0' after TCQ*1 ps;
        iserdes_rd1 <= '0' after TCQ*1 ps;
        iserdes_fd1 <= '0' after TCQ*1 ps;
      elsif (q_dly_clkinv = '1') then
        iserdes_rd0 <= iserdes_fd1_int2 after TCQ*1 ps;
        iserdes_fd0 <= iserdes_rd0_int  after TCQ*1 ps;
        iserdes_rd1 <= iserdes_fd0_int  after TCQ*1 ps;
        iserdes_fd1 <= iserdes_rd1_int  after TCQ*1 ps;
      else 
        iserdes_rd0 <= iserdes_rd0_int  after TCQ*1 ps;
        iserdes_fd0 <= iserdes_fd0_int  after TCQ*1 ps;
        iserdes_rd1 <= iserdes_rd1_int  after TCQ*1 ps;
        iserdes_fd1 <= iserdes_fd1_int  after TCQ*1 ps;
      end if;
     end if;
  end process;

  io_Q_D : if (MEM_TYPE = "QDR2PLUS"  or MEM_TYPE = "QDR2" or MEM_TYPE = "RLD2_SIO") generate
  attribute IODELAY_GROUP of u_iodelay_d : label is IODELAY_GRP;
  begin
    -- Q first passes through an IBUF                                     
    u_ibuf_q : IBUF                                                       
      generic map(                                                        
        IBUF_LOW_PWR => IBUF_LOW_PWR                                      
      )                                                                   
      port map(                                                           
        I => mem_q,                                                       
        O => q_ibuf                                                       
      );                                                                  
                                                                          
    -- Q then passes through an IDELAY                                    
     u_iodelay_d : IODELAYE1                                              
      generic map(                                                        
        DELAY_SRC              => "I",                                    
        HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,                  
        IDELAY_TYPE            => "VAR_LOADABLE",                         
        REFCLK_FREQUENCY       => REFCLK_FREQ,                            
        SIGNAL_PATTERN         => "DATA"                                  
      )                                                                   
      port map(                                                           
        CNTVALUEOUT  => q_dly_tap_int,                                    
        DATAOUT      => q_idelay,                                         
        C            => clk_rd,                                           
        CE           => q_dly_ce_int,                                     
        CINVCTRL     => '0',                                              
        CNTVALUEIN   => q_dly_load,                                       
        DATAIN       => '0',                                              
        IDATAIN      => q_ibuf,                                           
        INC          => q_dly_inc_int,                                    
        ODATAIN      => '0',                                              
        RST          => q_dly_rst,                                        
        CLKIN        => '0',                                              
        T            => '1'                                               
      );            
      
                 
 
  
    -- Finally Q is deserialized in the ISERDES
    u_iserdes_q : ISERDESE1                                           
      generic map(                                                    
        DATA_RATE          => "DDR",                                  
        DATA_WIDTH         => 4,                                      
        DYN_CLK_INV_EN     => FALSE,                                  
        DYN_CLKDIV_INV_EN  => FALSE,                                  
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
        DDLY           => q_idelay,                                   
        DYNCLKSEL      => '0',                                        
        OCLK           => '0',                                         
        RST            => iserdes_rst_int,                            
        SHIFTIN1       => '0',                                        
        SHIFTIN2       => '0',                                        
        O              => open,                                       
        Q1             => iserdes_fd1_int,                            
        Q2             => iserdes_rd1_int,                            
        Q3             => iserdes_fd0_int,                            
        Q4             => iserdes_rd0_int,                            
        Q5             => open,                                       
        Q6             => open,                                       
        SHIFTOUT1      => open,                                       
        SHIFTOUT2      => open,                                       
        OFB            => '0'                                         
      );
    
    -- Output D data
    u_phy_oserdes_data : phy_oserdes_io 
      generic map(
        ODELAY_VAL            => ODELAY_VAL,
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
        data_rise0   => data_rise0, 
        data_fall0   => data_fall0,  
        data_rise1   => data_rise1,   
        data_fall1   => data_fall1,    
        data_out_p   => mem_d,
        data_out_n   => open
    );
  
  end generate io_Q_D;

  IO_DQ : if MEM_TYPE = "RLD2_CIO" generate
  attribute IODELAY_GROUP of u_iodelay_dq : label is IODELAY_GRP;
  begin
    
    --tie the D outputs low since not used
    mem_d <= '0';
    
    u_iobuf_dq : IOBUF    
      generic map(
        IBUF_LOW_PWR => IBUF_LOW_PWR
      )  
      port map(
        I  => q_idelay,    -- Input from IODELAY output  
        T  => dq_oe_n_r,
        IO => mem_dq,   
        O  => q_ibuf       -- Connect to IDATA_IN  of IODELAY 
      );
      
    --DQ then passes through an IODELAY (input and output)
    u_iodelay_dq : IODELAYE1 
      generic map(
        CINVCTRL_SEL           => FALSE,
        DELAY_SRC              => "IO",
        HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
        IDELAY_TYPE            => "VARIABLE",
        IDELAY_VALUE           => 0,
        ODELAY_TYPE            => "FIXED",
        ODELAY_VALUE           => ODELAY_VAL,
        REFCLK_FREQUENCY       => REFCLK_FREQ,
        SIGNAL_PATTERN         => "DATA"
      )
      port map(
        CNTVALUEOUT  => q_dly_tap_int,
        DATAOUT      => q_idelay,
        C            => clk_rd,
        CE           => q_dly_ce_int,
        CINVCTRL     => '0',           -- Not used
        CNTVALUEIN   => q_dly_load,
        DATAIN       => '0',           -- Not used
        IDATAIN      => q_ibuf,
        INC          => q_dly_inc_int,
        ODATAIN      => oserdes_oq,
        RST          => q_dly_rst,
        CLKIN        => '0',
        T            => ocb_tfb 
      );
     
    
    -- Finally DQ is deserialized in the ISERDES
    u_iserdes_dq : ISERDESE1
      generic map(
        DATA_RATE          => "DDR",
        DATA_WIDTH         => 4,
        DYN_CLK_INV_EN     => FALSE,
        DYN_CLKDIV_INV_EN  => FALSE,
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
        DDLY           => q_idelay,
        DYNCLKSEL      => '0',
        OCLK           => clk_mem,
        RST            => iserdes_rst_int,
        SHIFTIN1       => '0',
        SHIFTIN2       => '0',
        O              => open,
        Q1             => iserdes_fd1_int,
        Q2             => iserdes_rd1_int,
        Q3             => iserdes_fd0_int,
        Q4             => iserdes_rd0_int,
        Q5             => open,
        Q6             => open,
        SHIFTOUT1      => open,
        SHIFTOUT2      => open,
        OFB            => '0'
     );
     
    u_oserdes_dq : OSERDESE1
      generic map(
       DATA_RATE_OQ   => "DDR",         -- Output 'OQ' as DDR Format
       DATA_RATE_TQ   => "DDR",         -- Output 'TQ' as DDR Format - Unused
       DATA_WIDTH     => 4,             -- D inputs width of four
       DDR3_DATA      => 0,             -- Data is not for DDR3
       INIT_OQ        => '0',           -- Initial value of OQ output
       INIT_TQ        => '1',           -- Initial value of TQ output
       INTERFACE_TYPE => "DEFAULT", -- To bypass DDR3 circuitry
       ODELAY_USED    => 0,             -- Internal ODELAY unused
       SERDES_MODE    => "MASTER",      -- This is the master OSERDES 
       SRVAL_OQ       => '0',           -- 'OQ' value on reset
       SRVAL_TQ       => '1',           -- 'TQ' value on reset - Unused
       TRISTATE_WIDTH => 4              -- T inputs width of four - Unused
      ) 
      port map(
        OQ           => oserdes_oq,     -- Data Output
        SHIFTOUT1    => open,           -- Carry out for Data - Unused
        SHIFTOUT2    => open,
        TQ           => dq_oe_n_r,      -- Tristate outputs
        CLK          => clk_mem,        -- Full Freq Clock Input clocks D in OCB
        CLKDIV       => clk,            -- Half Freq Clock Input for clking Data
        CLKPERF      => '0',         -- Full Freq Performance Path - Clock out
        CLKPERFDELAY => '0',            -- Output from IODELAY
        OFB          => open,           -- Feedback path - Unused
        D1           => data_rise0,
        D2           => data_fall0,
        D3           => data_rise1,
        D4           => data_fall1,
        D5           => '0',            -- Data inputs 5/6 - Unused
        D6           => '0',
        OCBEXTEND    => open,
        OCE          => '1',            -- Enable Data input bits
        ODV          => '0',            -- Set to '0' because delay doesn't 
                                        -- exceed 180 degrees
        SHIFTIN1     => '0',            -- Carry in for Data - Unused
        SHIFTIN2     => '0',
        RST          => rst_wr_clk,     -- Reset for OSERDES 
        T1           => wr_en(0),       -- Tristate inputs
        T2           => wr_en(1),
        T3           => wr_en(2),
        T4           => wr_en(3),
        TFB          => ocb_tfb,
        TCE          => '1',            -- Enable Tristate inputs
        WC           => '0'              -- Write Command to reset internal cntrs
     );
  end generate IO_DQ;
end architecture arch;
