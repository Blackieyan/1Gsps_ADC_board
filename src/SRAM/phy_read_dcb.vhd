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
------------------------------------------------------------------------------/
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : $Name:  $
--  \   \         Application        : MIG
--  /   /         Filename           : phy_qdr_pd.v
-- /___/   /\     Timestamp          :
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:32 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This module
--  1. is the top level module for QDRII Phase Detection.
--
--Revision History:
--
------------------------------------------------------------------------------/
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity phy_read_dcb is
  generic(
    MEMORY_WIDTH  : integer := 36;    -- Width of each memory
    TCQ           : integer := 100   -- Register delay
  );
  port(
    -- System Signal
    clk_rd      : in std_logic;   -- half freq CQ clock - write side
    rst_clk_rd  : in std_logic;   -- reset syncrhonized to clk_rd - write side
    clk         : in std_logic;   -- main system half freq clk - read side
    rst_clk     : in std_logic;   -- main read path reset sync to clk - read side
    cq_dly_rst  : in std_logic;   -- CQ IODELAY rest indication
    
    -- Data ALign Interface
    din_rd0 : in std_logic_vector(MEMORY_WIDTH-1 downto 0); -- rise data 0 from 
                                                            -- data align
    din_fd0 : in std_logic_vector(MEMORY_WIDTH-1 downto 0); -- fall data 0 from 
                                                            -- data align
    din_rd1 : in std_logic_vector(MEMORY_WIDTH-1 downto 0); -- rise data 1 from 
                                                            -- data align
    din_fd1 : in std_logic_vector(MEMORY_WIDTH-1 downto 0); -- fall data 1 from 
                                                            -- data align
    
    -- User Interface
    dout_rd0 : out std_logic_vector(MEMORY_WIDTH-1 downto 0); -- rise data 0 from DCB
    dout_fd0 : out std_logic_vector(MEMORY_WIDTH-1 downto 0); -- fall data 0 from DCB
    dout_rd1 : out std_logic_vector(MEMORY_WIDTH-1 downto 0); -- rise data 1 from DCB
    dout_fd1 : out std_logic_vector(MEMORY_WIDTH-1 downto 0); -- fall data 1 from DCB
    
    -- Latency Calibration Interface
    inc_latency : in std_logic; -- increase latency when asserted
    
    -- ChipScope Debug Signals
    dbg_dcb_wr_ptr  : out std_logic_vector(4 downto 0);
    dbg_dcb_rd_ptr  : out std_logic_vector(4 downto 0);
    dbg_dcb_din     : out std_logic_vector(MEMORY_WIDTH*4-1 downto 0);
    dbg_dcb_dout    : out std_logic_vector(MEMORY_WIDTH*4-1 downto 0)
  );
  end entity phy_read_dcb;

  architecture arch of phy_read_dcb is
  attribute ASYNC_REG : string;

  -- Signal Declarations
  signal dcb_in   : std_logic_vector(MEMORY_WIDTH*4-1 downto 0);
  signal dcb_out  : std_logic_vector(MEMORY_WIDTH*4-1 downto 0);  
    
  signal cq_dly_rst_r   : std_logic;
  signal cq_dly_rst_2r  : std_logic;
  signal cq_dly_rst_3r  : std_logic;
  signal cq_dly_rst_4r  : std_logic;
  signal cq_dly_rst_ext : std_logic;
  signal cdr_clkrd_r   : std_logic;
  
  signal wr_ptr   : std_logic_vector(4 downto 0);
  signal rd_ptr   : std_logic_vector(4 downto 0);
  signal di_int0  : std_logic_vector(MEMORY_WIDTH*4-1 downto 0);
  signal do_int0  : std_logic_vector(MEMORY_WIDTH*4-1 downto 0);
  
  signal rst_wr_ptr    : std_logic;
  signal rst_rd_ptr    : std_logic;
  signal cdr_clk_r     : std_logic;
  attribute ASYNC_REG of cdr_clk_r : signal is "TRUE";
  
  
  begin
  
  dcb_in <= (din_fd1 & din_rd1 & din_fd0 & din_rd0);
  
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        dout_rd0 <= (others => '0') after TCQ*1 ps;
        dout_fd0 <= (others => '0') after TCQ*1 ps;
        dout_rd1 <= (others => '0') after TCQ*1 ps;
        dout_fd1 <= (others => '0') after TCQ*1 ps;
      else
        dout_rd0 <= dcb_out(MEMORY_WIDTH-1 downto 0) after TCQ*1 ps;
        dout_fd0 <= dcb_out(2*MEMORY_WIDTH-1 downto MEMORY_WIDTH) after TCQ*1 ps;
        dout_rd1 <= dcb_out(3*MEMORY_WIDTH-1 downto MEMORY_WIDTH*2) after TCQ*1 ps;
        dout_fd1 <= dcb_out(4*MEMORY_WIDTH-1 downto MEMORY_WIDTH*3) after TCQ*1 ps;
      end if;
    end if;
  end process; 
 

  -- As CQ is calibrated, the rd_ptr can pass the wr_ptr due to delayed or
  -- missed clk_rd pulses. To avoid this, reset the points back to their
  -- original values each time the CQ IODELAY reset is issued from
  -- calibration.
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        cq_dly_rst_r  <= '0' after TCQ*1 ps;
        cq_dly_rst_2r <= '0' after TCQ*1 ps;
        cq_dly_rst_3r <= '0' after TCQ*1 ps;
        cq_dly_rst_4r <= '0' after TCQ*1 ps;
      else
        cq_dly_rst_r  <= cq_dly_rst after TCQ*1 ps;
        cq_dly_rst_2r <= cq_dly_rst_r after TCQ*1 ps;
        cq_dly_rst_3r <= cq_dly_rst_2r after TCQ*1 ps;
        cq_dly_rst_4r <= cq_dly_rst_3r after TCQ*1 ps;
      end if;
    end if;
  end process;
 
  -- Extend the reset signal to ensure (1) that the pulse is not missed due to
  -- the unknown phase of the two clocks and (2) that the change of phase
  -- resulting from clk_rd being reset does not affect this logic.
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        cq_dly_rst_ext <= '0' after TCQ*1 ps;
      else
        cq_dly_rst_ext <= cq_dly_rst_r  or cq_dly_rst_2r or
                          cq_dly_rst_3r or cq_dly_rst_4r    after TCQ*1 ps;
      end if;
    end if;
  end process;
 
  -- Match double registers used to cross from clk_rd to clk domain to ensure
  -- that both pointers are reset within a cycle of each other.
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        cdr_clkrd_r   <= '0' after TCQ*1 ps;
        rst_wr_ptr    <= '0' after TCQ*1 ps;
      else
        cdr_clkrd_r   <= cq_dly_rst_ext after TCQ*1 ps;
        rst_wr_ptr    <= cdr_clkrd_r after TCQ*1 ps;
      end if;
    end if;
  end process;
 
  -- Cross from clk_rd to clk domain
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        cdr_clk_r   <= '0' after TCQ*1 ps;
        rst_rd_ptr  <= '0' after TCQ*1 ps;
      else
        cdr_clk_r   <= cq_dly_rst_ext after TCQ*1 ps;
        rst_rd_ptr  <= cdr_clk_r after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Read pointer must always trail write pointer. Therefore, reset write pointer
  -- to 3 and read pointer to 0 to allow sufficient spacing between the pointers
  -- under reset uncertainties and variations in clock phases over V/T. Otherwise,
  -- the pointers continually increment and wrap around when the counter tops out.
  process(clk_rd)
  begin
    if (clk_rd'event and clk_rd = '1') then
      if (rst_clk_rd = '1') then
        wr_ptr <= "00011" after TCQ*1 ps;
      elsif (rst_wr_ptr = '1') then
        wr_ptr <= "00011" after TCQ*1 ps;
      else
        wr_ptr <= wr_ptr + "00001" after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  -- The read pointer has one additional requirement in that if inc_latency is
  -- asserted for the clk cycle, then the read pointer doesn't increment. This
  -- has the affect of increasing the latency through the system.
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        rd_ptr <= (others => '0') after TCQ*1 ps;
      elsif (rst_rd_ptr = '1') then
        rd_ptr <= (others => '0') after TCQ*1 ps;
      elsif (inc_latency = '1') then
        rd_ptr <= rd_ptr after TCQ*1 ps;
      else
        rd_ptr <= rd_ptr + "00001" after TCQ*1 ps;
      end if;
    end if;
  end process;
  
  -- Assign debug signals
  dbg_dcb_din <= dcb_in;
  dbg_dcb_dout <= dcb_out;
  dbg_dcb_rd_ptr <= rd_ptr;
  dbg_dcb_wr_ptr <= wr_ptr;
  
  di_int0 <= dcb_in;
  dcb_out <= do_int0;
  
  --***************************************************************************
  -- instantiate RAM64X1D for storage for x8, x9 and x18 memories
  --***************************************************************************
  
  gen_ram :  for i in 0 to (4*MEMORY_WIDTH -1) generate
   begin
      u_RAM64X1D : RAM64X1D 
      generic map (
        INIT =>  X"0000000000000000"
      )
      port map (
       DPO     =>  do_int0(i),
       SPO     =>  open,
       A0      =>  wr_ptr(0),
       A1      =>  wr_ptr(1),
       A2      =>  wr_ptr(2),
       A3      =>  wr_ptr(3),  
       A4      =>  wr_ptr(4),  
       A5      =>  '0',
       D       =>  di_int0(i),
       DPRA0   =>  rd_ptr(0),
       DPRA1   =>  rd_ptr(1),
       DPRA2   =>  rd_ptr(2),
       DPRA3   =>  rd_ptr(3), 
       DPRA4   =>  rd_ptr(4), 
       DPRA5   =>  '0',
       WCLK    =>  clk_rd,
       WE      =>  '1'
      );
  end generate gen_ram;
  

  
end architecture arch;
