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
--  /   /         Filename           : phy_write_top.vhd
-- /___/   /\     Timestamp          : Nov 12, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This module
--  1. Instantiates all the write path submodules
--Revision History:
--
--/////////////////////////////////////////////////////////////////////////////
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity phy_write_top is
  generic( 
    BURST_LEN   : integer := 4;            --Burst Length
   REFCLK_FREQ  : real    := 300.0;        --Ref. Clk Freq. for IODELAYs
   CLK_PERIOD   : integer := 3752;         --Internal Fabric Clk Period (in ps)
   NUM_DEVICES  : integer := 2;            --Memory Devices
    DATA_WIDTH  : integer := 72;           --Data Width
    ADDR_WIDTH  : integer := 19;           --Address Width
    BW_WIDTH    : integer := 8;            --Byte Write Width
    IODELAY_GRP : string  := "IODELAY_MIG";-- May be assigned unique name 
                                           -- when mult IP cores in design
   TCQ          : integer := 100           --Register Delay
  );
  port ( 
    clk         : in  std_logic;          --main system half freq clk
    rst_wr_clk  : in  std_logic;          --main write path reset
    clk_mem     : in  std_logic;          --full frequency clock 

    --Read Path Interface
   cal_done             : in  std_logic;  --calibration done
    cal_stage1_start    : in  std_logic;  --stage 1 calibration start
    cal_stage2_start    : in  std_logic;  --stage 2 calibration start
    init_done           : out std_logic;  --init done cal can begin  

    --User Interface
    wr_cmd0             : in  std_logic;  --wr command 0
    wr_cmd1             : in  std_logic;  --wr command 1
    --wr address 0
    wr_addr0         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  
    --wr address 1
    wr_addr1         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  
    rd_cmd0             : in  std_logic;      --rd command 0
    rd_cmd1             : in  std_logic;      --rd command 1
    --rd address 0
    rd_addr0         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);    
    --rd address 1
    rd_addr1         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);    
    --user write data 0
    wr_data0         : in  std_logic_vector(DATA_WIDTH*2-1 downto 0);  
    --user write data 1
    wr_data1         : in  std_logic_vector(DATA_WIDTH*2-1 downto 0);  
    --user byte writes 0
    wr_bw_n0         : in  std_logic_vector(BW_WIDTH*2-1 downto 0);    
    --user byte writes 1
    wr_bw_n1         : in  std_logic_vector(BW_WIDTH*2-1 downto 0);    
  
    --Outputs to IOBs
    --internal rd cmd
    int_rd_cmd_n          : out std_logic_vector(1 downto 0);                
    --internal rd cmd
    int_wr_cmd_n          : out std_logic_vector(1 downto 0);                
    --OSERDES addr rise0
    iob_addr_rise0        : out std_logic_vector(ADDR_WIDTH-1 downto 0);     
    --OSERDES addr fall0
    iob_addr_fall0        : out std_logic_vector(ADDR_WIDTH-1 downto 0);     
    --OSERDES addr rise1
    iob_addr_rise1        : out std_logic_vector(ADDR_WIDTH-1 downto 0);     
    --OSERDES addr fall1
    iob_addr_fall1        : out std_logic_vector(ADDR_WIDTH-1 downto 0);     
                   
    --OSERDES d rise0
    iob_data_rise0        : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    --OSERDES d fall0
    iob_data_fall0        : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    --OSERDES d rise1
    iob_data_rise1        : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    --OSERDES d fall1
    iob_data_fall1        : out std_logic_vector(DATA_WIDTH-1 downto 0);     
    --OSERDES bw rise0
    iob_bw_rise0          : out std_logic_vector(BW_WIDTH-1 downto 0);       
    --OSERDES bw fall0
    iob_bw_fall0          : out std_logic_vector(BW_WIDTH-1 downto 0);       
    --OSERDES bw rise1
    iob_bw_rise1          : out std_logic_vector(BW_WIDTH-1 downto 0);       
    --OSERDES bw fall1
    iob_bw_fall1          : out std_logic_vector(BW_WIDTH-1 downto 0);       
    
    --ChipScope Debug Signals
    --cs debug - wr command
    dbg_phy_wr_cmd_n     : out std_logic_vector(1 downto 0);               
    --cs debug - address
    dbg_phy_addr         : out std_logic_vector(ADDR_WIDTH*4-1 downto 0);  
    --cs debug - rd command
    dbg_phy_rd_cmd_n     : out std_logic_vector(1 downto 0);               
    --cs debug - wr data
    dbg_phy_wr_data      : out std_logic_vector(DATA_WIDTH*4-1 downto 0)   
  );  
   
end phy_write_top;

architecture arch of phy_write_top is

  signal init_rd_cmd       : std_logic_vector(1 downto 0);               
  signal init_wr_cmd       : std_logic_vector(1 downto 0);              
  signal init_wr_addr0     : std_logic_vector(ADDR_WIDTH-1 downto 0);   
  signal init_wr_addr1     : std_logic_vector(ADDR_WIDTH-1 downto 0);   
  signal init_rd_addr0     : std_logic_vector(ADDR_WIDTH-1 downto 0);   
  signal init_rd_addr1     : std_logic_vector(ADDR_WIDTH-1 downto 0);   
  signal init_wr_data0     : std_logic_vector(DATA_WIDTH*2-1 downto 0); 
  signal init_wr_data1     : std_logic_vector(DATA_WIDTH*2-1 downto 0); 

  component phy_write_control_io
  generic(
    BURST_LEN         : integer;
    CLK_PERIOD        : integer;
    ADDR_WIDTH        : integer;
    TCQ               : integer
  );
  port(
    clk                : in std_logic;
    rst_wr_clk         : in std_logic;
    clk_mem            : in std_logic;
    wr_cmd0            : in std_logic;
    wr_cmd1            : in std_logic;
    wr_addr0           : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    wr_addr1           : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    rd_cmd0            : in std_logic;
    rd_cmd1            : in std_logic;
    rd_addr0           : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    rd_addr1           : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    init_rd_cmd        : in std_logic_vector(1 downto 0);
    init_wr_cmd        : in std_logic_vector(1 downto 0);
    init_wr_addr0      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    init_wr_addr1      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    init_rd_addr0      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    init_rd_addr1      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    cal_done           : in std_logic;          
    int_rd_cmd_n       : out std_logic_vector(1 downto 0);
    int_wr_cmd_n       : out std_logic_vector(1 downto 0);
    iob_addr_rise0     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    iob_addr_fall0     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    iob_addr_rise1     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    iob_addr_fall1     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    dbg_phy_wr_cmd_n   : out std_logic_vector(1 downto 0);
    dbg_phy_addr       : out std_logic_vector(ADDR_WIDTH*4-1 downto 0);
    dbg_phy_rd_cmd_n   : out std_logic_vector(1 downto 0)
  );
  end component;


  component phy_write_data_io
  generic(
    BURST_LEN         : integer;
    CLK_PERIOD        : integer;
    DATA_WIDTH        : integer;
    BW_WIDTH          : integer;
    TCQ               : integer
  );                        
  port(
    clk                 : in std_logic;
    rst_wr_clk          : in std_logic;
    clk_mem             : in std_logic;
    cal_done            : in std_logic;
    wr_cmd0             : in std_logic;
    wr_cmd1             : in std_logic;
    init_wr_cmd         : in std_logic_vector(1 downto 0);
    init_wr_data0       : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
    init_wr_data1       : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
    wr_data0            : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
    wr_data1            : in std_logic_vector(DATA_WIDTH*2-1 downto 0);
    wr_bw_n0            : in std_logic_vector(BW_WIDTH*2-1 downto 0);
    wr_bw_n1            : in std_logic_vector(BW_WIDTH*2-1 downto 0);          
    iob_data_rise0      : out std_logic_vector(DATA_WIDTH-1 downto 0);
    iob_data_fall0      : out std_logic_vector(DATA_WIDTH-1 downto 0);
    iob_data_rise1      : out std_logic_vector(DATA_WIDTH-1 downto 0);
    iob_data_fall1      : out std_logic_vector(DATA_WIDTH-1 downto 0);
    iob_bw_rise0        : out std_logic_vector(BW_WIDTH-1 downto 0);
    iob_bw_fall0        : out std_logic_vector(BW_WIDTH-1 downto 0);
    iob_bw_rise1        : out std_logic_vector(BW_WIDTH-1 downto 0);
    iob_bw_fall1        : out std_logic_vector(BW_WIDTH-1 downto 0);
    dbg_phy_wr_data     : out std_logic_vector(DATA_WIDTH*4-1 downto 0)
  );
  end component;

  component phy_write_init_sm
  generic(
    BURST_LEN          : integer;
    ADDR_WIDTH         : integer;
    DATA_WIDTH         : integer;
    REFCLK_FREQ        : real ;
    TCQ                : integer
  );
  port( 
    clk                 : in std_logic;
    rst_wr_clk          : in std_logic;
    cal_stage1_start    : in std_logic;
    cal_stage2_start    : in std_logic;         
    init_done           : out std_logic;
    init_wr_data0       : out std_logic_vector(DATA_WIDTH*2-1 downto 0);
    init_wr_data1       : out std_logic_vector(DATA_WIDTH*2-1 downto 0);
    init_wr_addr0       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    init_wr_addr1       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    init_rd_addr0       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    init_rd_addr1       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    init_rd_cmd         : out std_logic_vector(1 downto 0);
    init_wr_cmd         : out std_logic_vector(1 downto 0)
    );
  end component;

  begin

  u_phy_write_control : phy_write_control_io 
  generic map(
    BURST_LEN         => BURST_LEN,
    CLK_PERIOD        => CLK_PERIOD,
    ADDR_WIDTH        => ADDR_WIDTH,
    TCQ               => TCQ    
  )
  port map(
    clk               => clk,
    rst_wr_clk        => rst_wr_clk,
    clk_mem           => clk_mem,
    wr_cmd0           => wr_cmd0,
    wr_cmd1           => wr_cmd1,
    wr_addr0          => wr_addr0,
    wr_addr1          => wr_addr1,
    rd_cmd0           => rd_cmd0,
    rd_cmd1           => rd_cmd1,
    rd_addr0          => rd_addr0,
    rd_addr1          => rd_addr1,
    init_rd_cmd       => init_rd_cmd,
    init_wr_cmd       => init_wr_cmd,
    init_wr_addr0     => init_wr_addr0,
    init_wr_addr1     => init_wr_addr1,
    init_rd_addr0     => init_rd_addr0,
    init_rd_addr1     => init_rd_addr1,
    cal_done          => cal_done,
    int_rd_cmd_n      => int_rd_cmd_n,
    int_wr_cmd_n      => int_wr_cmd_n,
    iob_addr_rise0    => iob_addr_rise0,
    iob_addr_fall0    => iob_addr_fall0,
    iob_addr_rise1    => iob_addr_rise1,
    iob_addr_fall1    => iob_addr_fall1,
    dbg_phy_wr_cmd_n  => dbg_phy_wr_cmd_n,
    dbg_phy_addr      => dbg_phy_addr,
    dbg_phy_rd_cmd_n  => dbg_phy_rd_cmd_n
  );

  u_phy_write_data : phy_write_data_io 
  generic map(
    BURST_LEN         => BURST_LEN,  
    CLK_PERIOD        => CLK_PERIOD,
    DATA_WIDTH        => DATA_WIDTH,
    BW_WIDTH          => BW_WIDTH,  
    TCQ               => TCQ  
  )
  port map(
    clk               => clk,
    rst_wr_clk        => rst_wr_clk,
    clk_mem           => clk_mem,
    cal_done          => cal_done,
    wr_cmd0           => wr_cmd0,
    wr_cmd1           => wr_cmd1,    
    init_wr_cmd       => init_wr_cmd, 
    init_wr_data0     => init_wr_data0,
    init_wr_data1     => init_wr_data1,
    wr_data0          => wr_data0,
    wr_data1          => wr_data1,
    wr_bw_n0          => wr_bw_n0,
    wr_bw_n1          => wr_bw_n1,
    iob_data_rise0    => iob_data_rise0,
    iob_data_fall0    => iob_data_fall0,
    iob_data_rise1    => iob_data_rise1,
    iob_data_fall1    => iob_data_fall1,
    iob_bw_rise0      => iob_bw_rise0,
    iob_bw_fall0      => iob_bw_fall0,
    iob_bw_rise1      => iob_bw_rise1,
    iob_bw_fall1      => iob_bw_fall1,
    dbg_phy_wr_data   => dbg_phy_wr_data
  );

  u_phy_write_init_sm: phy_write_init_sm 
  generic map(
    BURST_LEN         => BURST_LEN,  
    ADDR_WIDTH        => ADDR_WIDTH, 
    DATA_WIDTH        => DATA_WIDTH, 
    REFCLK_FREQ       => REFCLK_FREQ,
    TCQ               => TCQ        
  )
  port map(
    clk               => clk,
    rst_wr_clk        => rst_wr_clk,
    cal_stage1_start  => cal_stage1_start,
    cal_stage2_start  => cal_stage2_start,
    init_done         => init_done,
    init_wr_data0     => init_wr_data0,
    init_wr_data1     => init_wr_data1,
    init_wr_addr0     => init_wr_addr0,
    init_wr_addr1     => init_wr_addr1,
    init_rd_addr0     => init_rd_addr0,
    init_rd_addr1     => init_rd_addr1,
    init_rd_cmd       => init_rd_cmd,
    init_wr_cmd       => init_wr_cmd
  );


end architecture arch;
 