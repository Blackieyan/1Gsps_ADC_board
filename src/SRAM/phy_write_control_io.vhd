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
--  /   /         Filename           : phy_write_control_io.vhd
-- /___/   /\     Timestamp          : Nov 11, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This module
--  1. . Instantiates the I/O modules for generating the addresses and control
--     signals for memory
--Revision History:
--
--/////////////////////////////////////////////////////////////////////////////
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity phy_write_control_io is
  generic( 
    BURST_LEN   : integer := 4;           -- Burst Length
    CLK_PERIOD  : integer := 3752;        -- Internal Fabric Clk Period (in ps)
    ADDR_WIDTH  : integer := 19;          -- Address Width
    TCQ         : integer := 100          -- Register Delay
  );
  port(
    clk                  : in std_logic;    -- main system half freq clk
    rst_wr_clk           : in std_logic;    -- main write path reset
    clk_mem              : in std_logic;    -- full frequency clock
    wr_cmd0              : in std_logic;    -- wr command 0
    wr_cmd1              : in std_logic;    -- wr command 1
    -- wr address 0
    wr_addr0             : in std_logic_vector(ADDR_WIDTH-1 downto 0);    
    -- wr address 1
    wr_addr1             : in std_logic_vector(ADDR_WIDTH-1 downto 0);    
    rd_cmd0              : in std_logic;    -- rd command 0
    rd_cmd1              : in std_logic;    -- rd command 1
    -- rd address 0
    rd_addr0             : in std_logic_vector(ADDR_WIDTH-1 downto 0);    
    -- rd address 1
    rd_addr1             : in std_logic_vector(ADDR_WIDTH-1 downto 0);    
    -- init sm rd command
    init_rd_cmd          : in std_logic_vector(1 downto 0);               
    -- init sm wr command
    init_wr_cmd          : in std_logic_vector(1 downto 0);               
    -- init sm wr address0
    init_wr_addr0        : in std_logic_vector(ADDR_WIDTH-1 downto 0);    
    -- init sm wr address1
    init_wr_addr1        : in std_logic_vector(ADDR_WIDTH-1 downto 0);    
    -- init sm rd address0
    init_rd_addr0        : in std_logic_vector(ADDR_WIDTH-1 downto 0);    
    -- init sm rd address1
    init_rd_addr1        : in std_logic_vector(ADDR_WIDTH-1 downto 0);    
    -- calibration done
    cal_done             : in std_logic;                                  
    -- internal rd cmd
    int_rd_cmd_n         : out std_logic_vector(1 downto 0);              
    -- internal rd cmd
    int_wr_cmd_n         : out std_logic_vector(1 downto 0);              
    -- OSERDES addr rise0
    iob_addr_rise0       : out std_logic_vector(ADDR_WIDTH-1 downto 0);   
    -- OSERDES addr fall0
    iob_addr_fall0       : out std_logic_vector(ADDR_WIDTH-1 downto 0);   
    -- OSERDES addr rise1
    iob_addr_rise1       : out std_logic_vector(ADDR_WIDTH-1 downto 0);   
    -- OSERDES addr fall1
    iob_addr_fall1       : out std_logic_vector(ADDR_WIDTH-1 downto 0);   
    -- cs debug - wr command
    dbg_phy_wr_cmd_n     : out std_logic_vector(1 downto 0);              
    -- cs debug - address
    dbg_phy_addr         : out std_logic_vector(ADDR_WIDTH*4-1 downto 0); 
    -- cs debug - rd command     
    dbg_phy_rd_cmd_n     : out std_logic_vector(1 downto 0)                  
  );
end phy_write_control_io;

architecture arch of phy_write_control_io is

  -- signal declarations
  signal  mux_rd_cmd0        : std_logic;
  signal  mux_rd_cmd1        : std_logic;
  signal  mux_wr_cmd0        : std_logic;
  signal  mux_wr_cmd1        : std_logic;
  signal  rd_addr0_r         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal  rd_addr1_r         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal  wr_addr0_r         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal  wr_addr1_r         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  
  signal  int_rd_cmd_n_sig   : std_logic_vector(1 downto 0);
  signal  int_wr_cmd_n_sig   : std_logic_vector(1 downto 0);
  signal  iob_addr_rise0_sig : std_logic_vector(ADDR_WIDTH-1 downto 0);  
  signal  iob_addr_fall0_sig : std_logic_vector(ADDR_WIDTH-1 downto 0);  
  signal  iob_addr_rise1_sig : std_logic_vector(ADDR_WIDTH-1 downto 0);  
  signal  iob_addr_fall1_sig : std_logic_vector(ADDR_WIDTH-1 downto 0); 
  
  signal  mv_wr_addr0        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal  mv_wr_addr1        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal  mv_rd_addr1        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  
  signal iob_addr_rise0_dly  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal iob_addr_fall0_dly  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal iob_addr_rise1_dly  : std_logic_vector(ADDR_WIDTH-1 downto 0); 
  signal iob_addr_fall1_dly  : std_logic_vector(ADDR_WIDTH-1 downto 0); 
  
  signal mv_wr_cmd0          : std_logic;    
  signal mv_wr_cmd1          : std_logic;
  signal mv_rd_cmd1          : std_logic;
  signal wr_addr1_2r         : std_logic_vector(ADDR_WIDTH-1 downto 0);

begin

  -- Test Signals for Chipscope
  dbg_phy_wr_cmd_n <= int_wr_cmd_n_sig;
  dbg_phy_rd_cmd_n <= int_rd_cmd_n_sig;
  dbg_phy_addr     <= iob_addr_rise0_sig & iob_addr_fall0_sig 
                    & iob_addr_rise1_sig & iob_addr_fall1_sig;

  -- In BL4 mode, writes should only be driven out on the falling edge, if we
  -- have a command on port 0 (rising edge) move it to port 1 (falling edge)
  -- Tie off the rising edge 
  mv_wr_addr0 <= (others => '0')   when BURST_LEN = 4 else wr_addr0; 
  mv_wr_addr1 <= wr_addr0          when BURST_LEN = 4 else wr_addr1;
  mv_rd_addr1 <= (others => '0')   when BURST_LEN = 4 else rd_addr1;
   
  -- Select the correct address either from the user or from the init state
  -- machine based on if calibration is complete
  rd_addr0_r  <= rd_addr0         when cal_done = '1' else init_rd_addr0;
  rd_addr1_r  <= mv_rd_addr1      when cal_done = '1' else init_rd_addr1;
  wr_addr0_r  <= mv_wr_addr0      when cal_done = '1' else init_wr_addr0;
  wr_addr1_r  <= mv_wr_addr1      when cal_done = '1' else init_wr_addr1;

  iob_addr_rise0_dly <= rd_addr0_r  when BURST_LEN = 4 else wr_addr1_2r;
  iob_addr_fall0_dly <= rd_addr0_r;
  iob_addr_rise1_dly <= wr_addr1_r  when BURST_LEN = 4 else wr_addr0_r;
  iob_addr_fall1_dly <= wr_addr1_r  when BURST_LEN = 4 else rd_addr1_r;
   
  process (clk)
  begin
    if (clk'event and clk='1') then
      wr_addr1_2r <= wr_addr1_r after TCQ*1 ps;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk='1') then  
      -- Select the correct input to the oserdes based on the burst mode
      iob_addr_rise0_sig <= iob_addr_rise0_dly after TCQ*1 ps;
      iob_addr_fall0_sig <= iob_addr_fall0_dly after TCQ*1 ps;
      iob_addr_rise1_sig <= iob_addr_rise1_dly after TCQ*1 ps;
      iob_addr_fall1_sig <= iob_addr_fall1_dly after TCQ*1 ps;
    end if;
  end process;

  -- In BL4 mode, writes should only be driven out on the falling edge, if we
  -- have a command on port 0 (rising edge) move it to port 1 (falling edge)
  -- Tie off the rising edge 
  mv_wr_cmd0 <= '0'        when (BURST_LEN = 4) else wr_cmd0;
  mv_wr_cmd1 <= wr_cmd0    when (BURST_LEN = 4) else wr_cmd1;
  mv_rd_cmd1 <= '0'        when (BURST_LEN = 4) else rd_cmd1;
  
  -- Select the command from the user or from the init state machine based 
  -- on if calibration is complete.
  -- from the init state machine the high bit 1, corresponds to a write on the
  -- rising edge of the clock as is "_cmd0"
  mux_rd_cmd0 <= rd_cmd0     when cal_done = '1'   else init_rd_cmd(0);
  mux_rd_cmd1 <= mv_rd_cmd1  when cal_done = '1'   else init_rd_cmd(1);
  mux_wr_cmd0 <= mv_wr_cmd0  when cal_done = '1'   else init_wr_cmd(0);
  mux_wr_cmd1 <= mv_wr_cmd1  when cal_done = '1'   else init_wr_cmd(1);

  -- Invert the commands to be used on the memory interface as active low
  
  process (clk)
  begin
    if (clk'event and clk='1') then  
      if (rst_wr_clk = '1') then 
        int_rd_cmd_n_sig <= "11" after TCQ*1 ps;
        int_wr_cmd_n_sig <= "11" after TCQ*1 ps;
      else 
        int_rd_cmd_n_sig <= not(mux_rd_cmd1) & not(mux_rd_cmd0) after TCQ*1 ps;
        int_wr_cmd_n_sig <= not(mux_wr_cmd1) & not(mux_wr_cmd0) after TCQ*1 ps;
      end if;
    end if;
  end process;

  int_rd_cmd_n    <= int_rd_cmd_n_sig;
  int_wr_cmd_n    <= int_wr_cmd_n_sig;
  iob_addr_rise0  <= iob_addr_rise0_sig;
  iob_addr_fall0  <= iob_addr_fall0_sig;
  iob_addr_rise1  <= iob_addr_rise1_sig;
  iob_addr_fall1  <= iob_addr_fall1_sig;

end architecture arch;
