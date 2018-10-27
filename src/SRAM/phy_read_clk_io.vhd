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
-- \   \   \/     Version            : $Name:  $
--  \   \         Application        : MIG
--  /   /         Filename           : phy_read_clk_io.v
-- /___/   /\     Timestamp          : Nov 18, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:32 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--  This module
--  1. Is the I/O module for the incoming CQ echo clock from the memory.
--  2. Instantiates the IBUF followed by the IDELAY to delay the CQ clock
--     and routes it through a BUFIO.
--  3. Routes the CQ clock from the IDELAY through a BUFR which divides
--     the clock by 2.
--
--Revision History:
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity phy_read_clk_io is
generic(
  REFCLK_FREQ           : real    := 300.0;         -- Indicates the IDELAYCTRL 
                                                    -- reference clock frequency
  MEM_TYPE              : string  := "QDR2PLUS";    -- Memory Type (QDR2PLUS; 
                                                    -- RLD2_CIO; RLD2_SIO)
  IODELAY_GRP           : string  := "IODELAY_MIG"; -- May be assigned unique name 
  HIGH_PERFORMANCE_MODE : boolean := TRUE;          -- IODELAY High PerfMode
  IBUF_LOW_PWR          : boolean := FALSE;         -- Input buffer low power mode
  TCQ                   : integer := 100            -- Register delay
  );
port(
  -- Memory Interface
  mem_cq        : in std_logic;                  -- CQ clock from the memory
  mem_cq_n      : in std_logic;                  -- CQ# clock from the memory

  -- IDELAY control
  cal_clk       : in std_logic;                     -- IDELAY clock used for 
                                                    -- dynamic inc/dec
  cq_dly_ce     : in std_logic;                     -- CQ IDELAY clock enable
  cq_dly_inc    : in std_logic;                     -- CQ IDELAY increment
  cq_dly_rst    : in std_logic;                     -- CQ IDELAY reset
  cq_dly_load   : in std_logic_vector(4 downto 0);  -- CQ IDELAY cntvaluein load 
                                                    -- value
  cq_dly_tap    : out std_logic_vector(4 downto 0); -- CQ IDELAY tap settings 
                                                    -- concatenated
  
  cqn_dly_ce    : in std_logic;                     -- CQ# IDELAY clock enable
  cqn_dly_inc   : in std_logic;                     -- CQ# IDELAY increment
  cqn_dly_rst   : in std_logic;                     -- CQ# IDELAY reset
  cqn_dly_load  : in std_logic_vector(4 downto 0);  -- CQ# IDELAY cntvaluein 
                                                    -- load value
  cqn_dly_tap   : out std_logic_vector(4 downto 0); -- CQ# IDELAY tap settings 
                                                    -- concatenated

  -- PHY Read Interface
  clk_cq        : out std_logic;                    -- BUFIO CQ output
  clk_cqn       : out std_logic;                    -- BUFIO CQ# output
  clk_rd        : out std_logic;                    -- BUFR half frequency CQ output
  pd_source     : out std_logic;                    -- PD Source for RLDRAMII
  rst_clk_rd    : in  std_logic                     -- Reset Synchronized to Clk Rd
);
end entity phy_read_clk_io;

architecture arch of phy_read_clk_io is

  signal  cq_ibuf         : std_logic;
  signal  cq_idelay       : std_logic;
  signal  cq_bufio        : std_logic;
  signal  cq_bufr         : std_logic;
  
  signal  cqn_ibuf        : std_logic;
  signal  cqn_idelay      : std_logic;
  signal  cqn_bufio       : std_logic;

  signal cq_dly_ce_int    : std_logic;
  signal cqn_dly_ce_int   : std_logic;
  signal cq_dly_inc_int   : std_logic;
  signal cqn_dly_inc_int  : std_logic;
  signal clk_rd_int       : std_logic;
  signal pd_source_int    : std_logic;
  signal cq_dly_tap_int   : std_logic_vector(4 downto 0);
  signal cqn_dly_tap_int  : std_logic_vector(4 downto 0);

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
  attribute IODELAY_GROUP of mem_cq_idelay_inst : label is IODELAY_GRP;
  
  ----- component IOBUFDS_DIFF_OUT -----
   component IOBUFDS_DIFF_OUT
     generic (
        --DIFF_TERM : boolean := TRUE;
        IBUF_LOW_PWR : boolean := TRUE
        --IOSTANDARD : string := "DEFAULT"
     );
     port (
        O : out std_ulogic;
        OB : out std_ulogic;
        IO : inout std_ulogic;
        IOB : inout std_ulogic;
        I : in std_ulogic;
        TM : in std_ulogic;
        TS : in std_ulogic
     );
   end component;
   
   signal mem_cq_wire         : std_logic;
   signal mem_cq_n_wire       : std_logic;

begin
  mem_cq_wire   <= mem_cq;
  mem_cq_n_wire <= mem_cq_n;

  -- Prevent the taps from overflowing or underflowing by capping them at their
  -- minimum or maximum value
  process (clk_rd_int)
  begin
    if (clk_rd_int'event and clk_rd_int='1') then  
      if (rst_clk_rd = '1') then
        cq_dly_ce_int <= '0' after TCQ*1 ps;

      elsif (cq_dly_ce = '1') then
        if (cq_dly_inc = '1') then
          cq_dly_ce_int <= not(and_br(cq_dly_tap_int)) after TCQ*1 ps;
        else
          cq_dly_ce_int <= or_br(cq_dly_tap_int) after TCQ*1 ps;
        end if;

      else
        cq_dly_ce_int <= '0' after TCQ*1 ps;
      end if;
    end if;
  end process;

  process (clk_rd_int)
  begin
    if (clk_rd_int'event and clk_rd_int='1') then  
      if (rst_clk_rd = '1') then
        cqn_dly_ce_int <= '0' after TCQ*1 ps;
      elsif (cqn_dly_ce = '1') then
        if (cqn_dly_inc = '1') then
          cqn_dly_ce_int <=not(and_br(cqn_dly_tap_int)) after TCQ*1 ps;
        else
          cqn_dly_ce_int <= or_br(cqn_dly_tap_int) after TCQ*1 ps;
        end if;
      else
        cqn_dly_ce_int <= '0' after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  -- need to register the "inc" signals to make sure they align with the "ce"
  process (clk_rd_int)
  begin
    if (clk_rd_int'event and clk_rd_int='1') then  
      if (rst_clk_rd = '1') then
        cq_dly_inc_int  <= '0';
        cqn_dly_inc_int <= '0';
      else
        cq_dly_inc_int  <= cq_dly_inc after TCQ*1 ps;
        cqn_dly_inc_int <= cqn_dly_inc after TCQ*1 ps;
      end if;
    end if;
  end process;

  IBUF_CQ_CQ_B : if (MEM_TYPE = "QDR2PLUS" or MEM_TYPE = "QDR2") generate
  begin
    -- CQ first passes through an IBUF
    mem_cq_ibuf_inst : IBUF   
    generic map(
      IBUF_LOW_PWR => IBUF_LOW_PWR
    )
    port map(
      I => mem_cq,
      O => cq_ibuf
    );  

    -- CQ# first passes through an IBUF
    mem_cqn_ibuf_inst : IBUF   
    generic map(
      IBUF_LOW_PWR => IBUF_LOW_PWR
    )
    port map(
      I => mem_cq_n,
      O => cqn_ibuf
    );
    
    --pd_source_int <= '0';  
    pd_source_int <= cqn_ibuf;  
  
  end generate IBUF_CQ_CQ_B;
    
  IOBUF_QK : if (not (MEM_TYPE = "QDR2PLUS" or MEM_TYPE = "QDR2")) generate 
  
  begin
    --Differential Input Buffer
    --N-side used for the Phase Detector
    qk_ibufgds_diff_out : IOBUFDS_DIFF_OUT 
    generic map(
      IBUF_LOW_PWR => IBUF_LOW_PWR
    ) 
    port map(
      O   => cq_ibuf,
      OB  => cqn_ibuf,
      IO  => mem_cq_wire,
      IOB => mem_cq_n_wire,
      I   => '0',
      TM  => '1',
      TS  => '1'
    );
    
    pd_source_int <= cqn_ibuf;

  end generate IOBUF_QK;
  
  -- CQ then passes through an IDELAY
  mem_cq_idelay_inst : IODELAYE1 
  generic map(
    CINVCTRL_SEL            => FALSE,
    DELAY_SRC               => "I",
    HIGH_PERFORMANCE_MODE   => HIGH_PERFORMANCE_MODE,
    IDELAY_TYPE             => "VAR_LOADABLE",
    REFCLK_FREQUENCY        => REFCLK_FREQ,
    SIGNAL_PATTERN          => "CLOCK"
  ) 
  port map(
    CNTVALUEOUT  => cq_dly_tap_int,
    DATAOUT      => cq_idelay,
    C            => cal_clk,
    CE           => cq_dly_ce_int,
    CINVCTRL     => '0',
    CNTVALUEIN   => cq_dly_load,
    DATAIN       => '0',
    IDATAIN      => cq_ibuf,
    INC          => cq_dly_inc_int,
    ODATAIN      => '0',
    RST          => cq_dly_rst,
    CLKIN        => '0',
    T            => '1'
  );    
  
  cqn_bufio <= not(cq_bufio);  
  cqn_dly_tap_int <= "00000";  
  
  
--  CQ_B_IOB : if (MEM_TYPE = "QDR2PLUS" or MEM_TYPE = "QDR2") generate
--  
--  attribute IODELAY_GROUP of mem_cqn_idelay_inst : label is IODELAY_GRP;
--  begin
--    -- CQ# then passes through an IDELAY
--    mem_cqn_idelay_inst : IODELAYE1 
--    generic map( 
--      CINVCTRL_SEL           => FALSE,
--      DELAY_SRC              => "I",
--      HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
--      IDELAY_TYPE            => "VAR_LOADABLE",
--      REFCLK_FREQUENCY       => REFCLK_FREQ,
--      SIGNAL_PATTERN         => "CLOCK"
--    )
--    port map(
--      CNTVALUEOUT  => cqn_dly_tap_int,
--      DATAOUT      => cqn_idelay,
--      C            => cal_clk,
--      CE           => cqn_dly_ce_int,
--      CINVCTRL     => '0',
--      CNTVALUEIN   => cqn_dly_load,
--      DATAIN       => '0',
--      IDATAIN      => cqn_ibuf,
--      INC          => cqn_dly_inc_int,
--      ODATAIN      => '0',
--      RST          => cqn_dly_rst,
--      CLKIN        => '0',
--      T            => '1'
--    );
--
--    -- Out of the IDELAY, CQ# is distributed through a BUFIO
--    mem_cqn_bufio_inst : BUFIO 
--    port map(
--      I => cqn_idelay,
--      O => cqn_bufio
--    );
--  end generate CQ_B_IOB;
--  
--  CQ_B_IOB_else : if (MEM_TYPE /= "QDR2PLUS" and MEM_TYPE /= "QDR2") generate
--  begin
--    cqn_bufio <= not(cq_bufio);
--    cqn_dly_tap_int <= "00000";
--  end generate CQ_B_IOB_else;
  
  -- Out of the IDELAY, CQ is distributed through a BUFIO
  mem_cq_bufio_inst : BUFIO 
  port map(
    I => cq_idelay,
    O => cq_bufio
  );
  
  -- The output of the IDELAY also passes through a BUFR that divides
  -- the clock by 2
  mem_cq_bufr_inst : BUFR 
  generic map(
    BUFR_DIVIDE => "2",
    SIM_DEVICE  => "VIRTEX6"
  )
  port map(
    O    => cq_bufr, 
    CE   => '1', 
    CLR  => '0', 
    I    => cq_idelay
  );
      
  clk_cq      <= cq_bufio;
  clk_rd_int  <= cq_bufr;
  clk_rd      <= clk_rd_int;
  pd_source   <= pd_source_int;

  --  assign #1100 clk_cqn = cqn_bufio;
  clk_cqn     <= cqn_bufio;
  cq_dly_tap  <= cq_dly_tap_int;
  cqn_dly_tap <= cqn_dly_tap_int;
  
end architecture arch;

