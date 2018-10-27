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
-- \   \   \/     Version            : 3.0
--  \   \         Application        : MIG
--  /   /         Filename           : phy_write_data_io.vhd
-- /___/   /\     Timestamp          : Nov 12, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This module
--  1. Is the top level module for write data
--  2. Instantiates the I/O modules for the memory write data

--Revision History:
--
--/////////////////////////////////////////////////////////////////////////////
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity phy_write_data_io is
  generic(
    BURST_LEN         : integer := 4;   --Burst Length
    CLK_PERIOD        : integer := 3753;--Internal Fabric Clk Period (in ps)
    DATA_WIDTH        : integer := 72;  --Data Width
    BW_WIDTH          : integer := 8;   --Byte Write Width
    TCQ               : integer := 100  --Register Delay                                           
  );                        
  port(
    clk                 : in std_logic;       --main system half freq clk
    rst_wr_clk          : in std_logic;    --main write path reset 
    clk_mem             : in std_logic;     --full frequency clock
    cal_done            : in std_logic;   --calibration done   
    wr_cmd0             : in std_logic;
    wr_cmd1             : in std_logic;
    init_wr_cmd         : in std_logic_vector(1 downto 0);
                                                                        
    --init state machine data 0
    init_wr_data0            : in std_logic_vector(DATA_WIDTH*2-1 downto 0);    
    --init state machine data 1
    init_wr_data1            : in std_logic_vector(DATA_WIDTH*2-1 downto 0);    
    --user byte writes 0
    wr_bw_n0                 : in std_logic_vector(BW_WIDTH*2-1 downto 0);      
    --user byte writes 1
    wr_bw_n1                 : in std_logic_vector(BW_WIDTH*2-1 downto 0);          
    --OSERDES d rise0
    iob_data_rise0           : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    --OSERDES d fall0
    iob_data_fall0           : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    --OSERDES d rise1
    iob_data_rise1           : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    --user write data 0
    wr_data0                 : in std_logic_vector(DATA_WIDTH*2-1 downto 0);    
    --user write data 1
    wr_data1                 : in std_logic_vector(DATA_WIDTH*2-1 downto 0);    
    --OSERDES d fall1
    iob_data_fall1           : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    --OSERDES bw rise0
    iob_bw_rise0             : out std_logic_vector(BW_WIDTH-1 downto 0);       
    --OSERDES bw fall0
    iob_bw_fall0             : out std_logic_vector(BW_WIDTH-1 downto 0);       
    --OSERDES bw rise1
    iob_bw_rise1             : out std_logic_vector(BW_WIDTH-1 downto 0);       
    --OSERDES bw fall1
    iob_bw_fall1             : out std_logic_vector(BW_WIDTH-1 downto 0);       
    --cs debug - wr data       
    dbg_phy_wr_data          : out std_logic_vector(DATA_WIDTH*4-1 downto 0)                 
     );
end phy_write_data_io;

architecture arch of phy_write_data_io is

  --Signal Declarations
  signal mux_data_rise0       : std_logic_vector(DATA_WIDTH-1 downto 0); 
  signal mux_data_fall0       : std_logic_vector(DATA_WIDTH-1 downto 0); 
  signal mux_data_rise1       : std_logic_vector(DATA_WIDTH-1 downto 0); 
  signal mux_data_fall1       : std_logic_vector(DATA_WIDTH-1 downto 0); 
  signal mux_data_rise0_r     : std_logic_vector(DATA_WIDTH-1 downto 0); 
  signal mux_data_fall0_r     : std_logic_vector(DATA_WIDTH-1 downto 0); 
  signal mux_data_rise1_r     : std_logic_vector(DATA_WIDTH-1 downto 0); 
  signal mux_data_fall1_r     : std_logic_vector(DATA_WIDTH-1 downto 0); 
  signal mux_data_fall1_2r    : std_logic_vector(DATA_WIDTH-1 downto 0); 
       
  signal mux_bw_rise0         : std_logic_vector(BW_WIDTH-1 downto 0);   
  signal mux_bw_fall0         : std_logic_vector(BW_WIDTH-1 downto 0);   
  signal mux_bw_rise1         : std_logic_vector(BW_WIDTH-1 downto 0);   
  signal mux_bw_fall1         : std_logic_vector(BW_WIDTH-1 downto 0);   
  signal mux_bw_rise0_r       : std_logic_vector(BW_WIDTH-1 downto 0);   
  signal mux_bw_fall0_r       : std_logic_vector(BW_WIDTH-1 downto 0);   
  signal mux_bw_rise1_r       : std_logic_vector(BW_WIDTH-1 downto 0);   
  signal mux_bw_fall1_r       : std_logic_vector(BW_WIDTH-1 downto 0);   
  signal mux_bw_fall1_2r      : std_logic_vector(BW_WIDTH-1 downto 0);     

  
  signal iob_data_rise0_dly   : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal iob_data_fall0_dly   : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal iob_data_rise1_dly   : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal iob_data_fall1_dly   : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal iob_bw_rise0_dly     : std_logic_vector(BW_WIDTH-1 downto 0); 
  signal iob_bw_fall0_dly     : std_logic_vector(BW_WIDTH-1 downto 0);
  signal iob_bw_rise1_dly     : std_logic_vector(BW_WIDTH-1 downto 0);
  signal iob_bw_fall1_dly     : std_logic_vector(BW_WIDTH-1 downto 0);
  
--  signal data_zeros           : std_logic_vector(DATA_WIDTH-1 downto 0);  
--  signal init_cmd_p           : std_logic;
  

begin

  --Debug ChipScope Signals
  dbg_phy_wr_data <= mux_data_rise0 & mux_data_fall0 
                   & mux_data_rise1 & mux_data_fall1;
                   
--  data_zeros(DATA_WIDTH-1 downto 0) <= (others => '0');      
  
--  init_cmd_p <=  init_wr_cmd[0] xor init_wr_cmd[1] ;          
    
  --Select the data/bw from either the user or the init state machine based on
  --if calibration is done.
                    
   mux_data_rise0 <= wr_data0(DATA_WIDTH*2-1 downto DATA_WIDTH) when (cal_done = '1' and (wr_cmd0 = '1' or wr_cmd1 = '1') ) else 
                    init_wr_data0(DATA_WIDTH*2-1 downto DATA_WIDTH) when (cal_done = '0' and (init_wr_cmd(0) = '1' or init_wr_cmd(1) = '1')) else
                    (others => '0');
                    
  mux_data_fall0 <= wr_data0(DATA_WIDTH-1 downto 0) when (cal_done = '1' and (wr_cmd0 = '1' or wr_cmd1 = '1') ) else
                     init_wr_data0(DATA_WIDTH-1 downto 0)when (cal_done = '0' and (init_wr_cmd(0) = '1' or init_wr_cmd(1) = '1')) else
                     (others => '0');
       
  mux_data_rise1 <= wr_data1(DATA_WIDTH*2-1 downto DATA_WIDTH) when (cal_done = '1' and (wr_cmd0 = '1' or wr_cmd1 = '1') ) else 
                     init_wr_data1(DATA_WIDTH*2-1 downto DATA_WIDTH) when (cal_done = '0' and (init_wr_cmd(0) = '1' or init_wr_cmd(1) = '1')) else
                     (others => '0');
       
  mux_data_fall1 <= wr_data1(DATA_WIDTH-1 downto 0) when (cal_done = '1' and (wr_cmd0 = '1' or wr_cmd1 = '1') ) else        
                     init_wr_data1(DATA_WIDTH-1 downto 0) when (cal_done = '0' and (init_wr_cmd(0) = '1' or init_wr_cmd(1) = '1')) else
                     (others => '0');

  mux_bw_rise0 <= wr_bw_n0(BW_WIDTH*2-1 downto BW_WIDTH) when (cal_done = '1' and (wr_cmd0 = '1' or wr_cmd1 = '1') )
                    else (others => '0');
  mux_bw_fall0 <= wr_bw_n0(BW_WIDTH-1 downto 0) when (cal_done = '1' and (wr_cmd0 = '1' or wr_cmd1 = '1') )
                    else (others => '0');
  mux_bw_rise1 <= wr_bw_n1(BW_WIDTH*2-1 downto BW_WIDTH) when (cal_done = '1' and (wr_cmd0 = '1' or wr_cmd1 = '1') )
                    else (others => '0');
  mux_bw_fall1 <= wr_bw_n1(BW_WIDTH-1 downto 0) when (cal_done = '1' and (wr_cmd0 = '1' or wr_cmd1 = '1') )
                    else (others => '0');

  --When in BL4 mode, use the double registered version of the data/bw so they
  --appear on the edge after the write command was issued.  When in BL2
  --mode use the single registered data/bw so they appear on the same edge
  --as the write command.
  process (clk)
  begin
     if (clk'event and clk='1') then  
      if (rst_wr_clk = '1') then 
        mux_data_rise0_r   <= (others=>'0')    after TCQ*1 ps;
        mux_data_fall0_r   <= (others=>'0')    after TCQ*1 ps;
        mux_data_rise1_r   <= (others=>'0')    after TCQ*1 ps;
        mux_data_fall1_r   <= (others=>'0')    after TCQ*1 ps;
        mux_data_fall1_2r  <= (others=>'0')    after TCQ*1 ps;

        --Initialize active low bw to 1 - to fill entire width use (others=>'1')
        mux_bw_rise0_r     <= (others=>'1')    after TCQ*1 ps;
        mux_bw_fall0_r     <= (others=>'1')    after TCQ*1 ps;
        mux_bw_rise1_r     <= (others=>'1')    after TCQ*1 ps;
        mux_bw_fall1_r     <= (others=>'1')    after TCQ*1 ps;
        mux_bw_fall1_2r    <= (others=>'1')    after TCQ*1 ps;
      else               
        mux_data_rise0_r   <= mux_data_rise0   after TCQ*1 ps;
        mux_data_fall0_r   <= mux_data_fall0   after TCQ*1 ps;
        mux_data_rise1_r   <= mux_data_rise1   after TCQ*1 ps;
        mux_data_fall1_r   <= mux_data_fall1   after TCQ*1 ps;
        mux_data_fall1_2r  <= mux_data_fall1_r after TCQ*1 ps;
                        
        mux_bw_rise0_r     <= mux_bw_rise0     after TCQ*1 ps;
        mux_bw_fall0_r     <= mux_bw_fall0     after TCQ*1 ps;
        mux_bw_rise1_r     <= mux_bw_rise1     after TCQ*1 ps;
        mux_bw_fall1_r     <= mux_bw_fall1     after TCQ*1 ps;
        mux_bw_fall1_2r    <= mux_bw_fall1_r   after TCQ*1 ps;
      end if;
    end if;  
  end process;
  
  --select the registered data or not based on the burst length.  In BL4 the
  --data should come on the next rising edge after a wr_n command.  
  --Because the address/control are shifted by .25 of a clock cycle, the
  --data needs to be delayed in order to line up with on the cycle after the
  --write command is issued.  In order to reduce jitter on the data, we dont
  --want to delay this by using an IODELAY for that .25 of a cycle.  So for
  --this shift the D0, D1, D2, D3 ports to the oserdes need to be off by one.
  --D0 -> D3_r, D1 -> D0, D2 -> D1, D3 -> D2
  --In BL2 the data should arrive on the same cycle as the command. To keep
  --the data in line with the command, the same idea is used as that in BL4 
  --mode, by only delaying the data on D0.
  iob_data_rise0_dly <= mux_data_fall1_2r when (BURST_LEN = 4)  
                                      else mux_data_fall1_r;
  iob_data_fall0_dly <= mux_data_rise0_r  when (BURST_LEN = 4)   
                                      else mux_data_rise0;
  iob_data_rise1_dly <= mux_data_fall0_r  when (BURST_LEN = 4)  
                                      else mux_data_fall0;
  iob_data_fall1_dly <= mux_data_rise1_r  when(BURST_LEN = 4)    
                                      else mux_data_rise1;

  iob_bw_rise0_dly <= mux_bw_fall1_2r when (BURST_LEN = 4) 
                       else mux_bw_fall1_r;
  iob_bw_fall0_dly <= mux_bw_rise0_r  when (BURST_LEN = 4)  
                       else mux_bw_rise0;
  iob_bw_rise1_dly <= mux_bw_fall0_r  when (BURST_LEN = 4)  
                       else mux_bw_fall0;
  iob_bw_fall1_dly <= mux_bw_rise1_r  when (BURST_LEN = 4)  
                       else mux_bw_rise1;  
  
  process (clk)
  begin
    if (clk'event and clk='1') then  
      iob_data_rise0     <= iob_data_rise0_dly after TCQ*1 ps;
      iob_data_fall0     <= iob_data_fall0_dly after TCQ*1 ps;
      iob_data_rise1     <= iob_data_rise1_dly after TCQ*1 ps;
      iob_data_fall1     <= iob_data_fall1_dly after TCQ*1 ps;
                     
      iob_bw_rise0       <= iob_bw_rise0_dly   after TCQ*1 ps;
      iob_bw_fall0       <= iob_bw_fall0_dly   after TCQ*1 ps;
      iob_bw_rise1       <= iob_bw_rise1_dly   after TCQ*1 ps;
      iob_bw_fall1       <= iob_bw_fall1_dly   after TCQ*1 ps;
    end if;  
  end process;


end architecture arch;

