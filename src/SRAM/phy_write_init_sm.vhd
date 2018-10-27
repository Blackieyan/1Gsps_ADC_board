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
--  /   /         Filename           : phy_write_init_sm.vhd
-- /___/   /\     Timestamp          : Nov 12, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--    This module
--  1. Is the initialization state machine for delay calibration before regular
--     memory transactions begin.
--  2. This sm generates control, address, and data.
--Revision History:
--
--/////////////////////////////////////////////////////////////////////////////
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity phy_write_init_sm is
  generic(
    BURST_LEN                : integer := 4;      --Burst Length
    ADDR_WIDTH               : integer := 19;     --Address Width
    DATA_WIDTH               : integer := 72;     --Data Width
    REFCLK_FREQ              : real    := 300.0;  --Ref Clk Freq. for IODELAYs
    TCQ                      : integer := 100     --Register Delay          
  );
  port(
    clk               : in std_logic;        --main system half freq clk
    rst_wr_clk        : in std_logic;        --main write path reset
    cal_stage1_start  : in std_logic;        --stage 1 calibration start
    cal_stage2_start  : in std_logic;        --stage 2 calibration start
    init_done         : out std_logic;       --init done, cal can begin 
    --init sm write data 0
    init_wr_data0     : out std_logic_vector(DATA_WIDTH*2-1 downto 0);
    --init sm write data 1
    init_wr_data1     : out std_logic_vector(DATA_WIDTH*2-1 downto 0);            
    --init sm write addr 0
    init_wr_addr0     : out std_logic_vector(ADDR_WIDTH-1 downto 0);  
    --init sm write addr 1
    init_wr_addr1     : out std_logic_vector(ADDR_WIDTH-1 downto 0);  
    --init sm read addr 0
    init_rd_addr0     : out std_logic_vector(ADDR_WIDTH-1 downto 0);  
    --init sma read addr 1
    init_rd_addr1     : out std_logic_vector(ADDR_WIDTH-1 downto 0);  
    init_rd_cmd       : out std_logic_vector(1 downto 0);   --init sm read command
    init_wr_cmd       : out std_logic_vector(1 downto 0)   --init sm write command        
    );
end phy_write_init_sm;

architecture arch of phy_write_init_sm is
  constant DATA_WIDTH_2     : integer := DATA_WIDTH*2;
  
  --Four states in the init sm, one-hot encoded
  constant CAL_INIT         : std_logic_vector(3 downto 0) := "0001";
  constant CAL_WRITE        : std_logic_vector(3 downto 0) := "0010";
  constant CAL_READ         : std_logic_vector(3 downto 0) := "0100";
  constant CAL_DONE         : std_logic_vector(3 downto 0) := "1000";
  
  --Stage 1 Calibration Pattern
  --00FF_FF00
  --00FF_00FF
  constant DATA_WIDTH_0    : std_logic_vector(DATA_WIDTH-1 downto 0) 
                                                            := (others => '0');
  constant DATA_WIDTH_1   : std_logic_vector(DATA_WIDTH-1 downto 0) 
                                                            := (others => '1');
  constant DATA_STAGE1     : std_logic_vector(DATA_WIDTH*8-1 downto 0) := 
                                 DATA_WIDTH_0 & DATA_WIDTH_1 &
                                 DATA_WIDTH_0 & DATA_WIDTH_1 &
                                 DATA_WIDTH_1 & DATA_WIDTH_0 &
                                 DATA_WIDTH_0 & DATA_WIDTH_1;
                      
  --Stage 2 Calibration Pattern 
  --AAAA_AAAA
  function DATA_STAGE2_CONST return std_logic_vector is
  variable TMP : std_logic_vector(DATA_WIDTH*4-1 downto 0);
  begin
    for i in 0 to (DATA_WIDTH-1) loop
      TMP(i*4+3 downto i*4) := x"A"; 
    end loop;
    return TMP;
  end function DATA_STAGE2_CONST;
  
  constant DATA_STAGE2     : std_logic_vector(DATA_WIDTH*4-1 downto 0) 
                                                          := DATA_STAGE2_CONST;

  --Signal Declarations
  signal phy_init_cs          : std_logic_vector(3 downto 0);
  signal phy_init_ns          : std_logic_vector(3 downto 0);
  signal rst_delayed          : std_logic_vector(6 downto 0) := (others => '0');
  signal cal_stage2_start_r   : std_logic;
  signal addr_cntr            : std_logic_vector(2 downto 0); 
  signal addr_cntr_dly        : std_logic_vector(2 downto 0); 
  signal init_wr_cmd_d        : std_logic_vector(1 downto 0);
  signal init_rd_cmd_d        : std_logic_vector(1 downto 0);
  signal incr_addr            : std_logic;
  signal init_wr_addr1_dly     : std_logic_vector(1 downto 0);
  signal init_rd_addr0_dly     : std_logic_vector(1 downto 0);
  signal init_wr_data0_dly     : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal init_wr_data0_dly_ST1 : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal init_wr_data1_dly     : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal init_wr_data1_dly_ST1 : std_logic_vector(DATA_WIDTH*2-1 downto 0);
  signal init_done_sig         : std_logic;
  signal init_wr_cmd_sig       : std_logic_vector(1 downto 0);
  
begin

  init_wr_cmd <= init_wr_cmd_sig;

  process (clk)
  begin
     if (clk'event and clk='1') then  
        rst_delayed(0) <= rst_wr_clk     after TCQ*1 ps;
        rst_delayed(1) <= rst_delayed(0) after TCQ*1 ps;
        rst_delayed(2) <= rst_delayed(1) after TCQ*1 ps;
        rst_delayed(3) <= rst_delayed(2) after TCQ*1 ps;
        rst_delayed(4) <= rst_delayed(3) after TCQ*1 ps;
        rst_delayed(5) <= rst_delayed(4) after TCQ*1 ps;
        rst_delayed(6) <= rst_delayed(5) after TCQ*1 ps;
     end if;  
  end process;

  --Signals to the read path that initialization can begin 
  process (clk)
  begin
     if (clk'event and clk='1') then
      if (rst_wr_clk = '1') then
        init_done_sig <='0' after TCQ*1 ps;
      elsif (rst_delayed(6)='1' and rst_delayed(5)='0') then 
          init_done_sig <='1' after TCQ*1 ps;
      else 
        init_done_sig <= init_done_sig;
      end if;
    end if;
  end process;
  
  init_done <= init_done_sig;
  
  process (clk)
  begin
    if (clk'event and clk='1') then
      if (rst_wr_clk = '1') then
        cal_stage2_start_r <= '0' after TCQ*1 ps;
      else
        cal_stage2_start_r <= cal_stage2_start after TCQ*1 ps;
      end if;
    end if;
  end process;

  addr_cntr_dly <= "100" when BURST_LEN = 4 else "010";

  --addr_cntr is used to select the data for initalization writes and
  --addressing.  The LSB is used to index data while [ADDR_WIDTH-1:1] is used
  --as the address therefore it is incremented by 2.
  process (clk)
  begin
    if (clk'event and clk='1') then
      if (rst_wr_clk = '1') then
        addr_cntr      <= "000" after TCQ*1 ps;
      --always use an address of 0x0 in stage 2 calibration
      elsif (cal_stage2_start = '1') then
        if (cal_stage2_start_r = '0' and cal_stage2_start = '1') then
          addr_cntr <= addr_cntr_dly after TCQ*1 ps;
        elsif (init_wr_cmd_sig(0) = '1' or init_wr_cmd_sig(1) = '1') then
          addr_cntr <= "000" after TCQ*1 ps;
        end if;

      elsif (incr_addr = '1') then
        addr_cntr(1 downto 0) <= addr_cntr(1 downto 0) + "10" after TCQ*1 ps; 
        addr_cntr(2)   <= '0' after TCQ*1 ps;
      else 
        addr_cntr <= addr_cntr;
      end if;
    end if;
  end process;


  --Register the State Machine Outputs
  process (clk)
  begin
    if (clk'event and clk='1') then
      if (rst_wr_clk = '1') then
        init_wr_cmd_sig <= "00"  after TCQ*1 ps;
        init_rd_cmd     <= "00" after TCQ*1 ps;
        init_wr_addr0   <= (others => '0') after TCQ*1 ps;
        init_wr_addr1   <= (others => '0') after TCQ*1 ps;
        init_rd_addr0   <= (others => '0') after TCQ*1 ps;
        init_rd_addr1   <= (others => '0') after TCQ*1 ps;
        init_wr_data0   <= (others => '0') after TCQ*1 ps;
        init_wr_data1   <= (others => '0') after TCQ*1 ps;
        phy_init_cs     <= CAL_INIT after TCQ*1 ps;
      else
        init_wr_cmd_sig <= init_wr_cmd_d after TCQ*1 ps;
        init_rd_cmd     <= init_rd_cmd_d after TCQ*1 ps;

        --init_wr_addr0/init_rd_addr1 are only used in BL2 mode.  Because of
        --this, we use all the address bits to maintain using even numbers for
        --the address' on the rising edge.  For BL2 the rising edge address 
        --should cycle through values 0,2,4, and 6.  On the falling edge where
        --'*addr1' is used the address should be rising edge +1 ('*addr0' +1).  
        --To save resources, instead of adding a +1, a 1 is concatinated
        --onto the rising edge address.
        --In BL4 mode, since reads only occur on the rising edge, and writes
        --on the falling edge, we uses everything but the LSB of addr_cntr 
        --since the LSB is only used to index the data register.  For BL4, 
        --the address should access 0x0 - 0x3 in stage one and 0x0 in stage 2.

        init_wr_addr0         <= EXT(addr_cntr(1 downto 0), ADDR_WIDTH) after TCQ*1 ps;          --Not used in BL4 - X
        init_wr_addr1         <= EXT(init_wr_addr1_dly, ADDR_WIDTH)  after TCQ*1 ps;
        init_rd_addr0         <= EXT(init_rd_addr0_dly, ADDR_WIDTH)  after TCQ*1 ps;
        init_rd_addr1         <= EXT(addr_cntr(1) & '1', ADDR_WIDTH) after TCQ*1 ps;  --Not used in BL4 - X

        --based on the address a bit-select is used to select 2 Data Words for
        --the pre-defined arrary of data for read calibration.
        init_wr_data0 <= init_wr_data0_dly after TCQ*1 ps;
        init_wr_data1 <= init_wr_data1_dly after TCQ*1 ps;
        phy_init_cs   <= phy_init_ns after TCQ*1 ps;
      end if;
    end if;
  end process;



  init_wr_addr1_dly <= addr_cntr(2 downto 1) when (BURST_LEN = 4) 
                       else addr_cntr(1) & '1';
  init_rd_addr0_dly <= addr_cntr(2 downto 1) when (BURST_LEN = 4) 
                       else  addr_cntr(1 downto 0);  


  init_wr_data0_dly <= DATA_STAGE2(DATA_WIDTH*2-1 downto 0) 
                      when cal_stage2_start = '1' else init_wr_data0_dly_ST1;
  init_wr_data0_dly_ST1 <= DATA_STAGE1(DATA_WIDTH*2-1 downto 0)
                           when addr_cntr(1 downto 0) = "00" else
                           DATA_STAGE1(DATA_WIDTH*6-1 downto DATA_WIDTH*4)   
                           when addr_cntr(1 downto 0) = "10" else 
                           (others => '0');

  init_wr_data1_dly <= DATA_STAGE2((DATA_WIDTH*4)-1 downto (DATA_WIDTH*2)) 
                       when (cal_stage2_start = '1') else init_wr_data1_dly_ST1;
  init_wr_data1_dly_ST1 <= DATA_STAGE1(DATA_WIDTH*4-1 downto DATA_WIDTH*2)   
                           when addr_cntr(1 downto 0) = "00" else
                           DATA_STAGE1(DATA_WIDTH*8-1 downto DATA_WIDTH*6)   
                           when addr_cntr(1 downto 0) = "10" else
                           (others => '0');                       

  --Initialization State Machine
  process (phy_init_cs, cal_stage1_start, cal_stage2_start_r, cal_stage2_start, 
           addr_cntr)
  begin
    case (phy_init_cs) is
      --In the init state, wait for cal_stage1_start to be asserted from the
      --read path to begin read/write transactions
      --Throughout this state machine, all outputs are registered except for 
      --incr_addr.  This is because that signal is used to set the address
      --which should be in line with the rest of the signals so it is used
      --immediately.
      when CAL_INIT =>
        init_wr_cmd_d   <= "00";
        init_rd_cmd_d   <= "00";
        incr_addr       <= '0';

        if (cal_stage1_start = '1') then
          phy_init_ns <= CAL_WRITE;
        else
          phy_init_ns <= CAL_INIT;
        end if;

      --Send a write command.  For BL2 mode two writes are issued to write
      --4 Data Words, in BL4 mode, only write on the falling edge by using
      --bit [1] of init_wr_cmd.
      when CAL_WRITE =>
        if (BURST_LEN = 4) then
          init_wr_cmd_d <= "10";
        else
          init_wr_cmd_d <= "11";
        end if;
        init_rd_cmd_d   <= "00";
        incr_addr       <= '1';
        
        --On the last two data words we are done writing in stage1
        --For stage two only one write is necessary
        if ((cal_stage2_start_r = '1' and cal_stage2_start = '1') or 
          (addr_cntr = "0010")) then
          phy_init_ns <= CAL_READ;
        else
          phy_init_ns <= CAL_WRITE;
        end if;

      --Send a write command.  For BL2 mode two reads are issued to read
      --back 4 Data Words, in BL4 mode, only read on the rising edge by using
      --bit [0] of init_rd_cmd.
      when CAL_READ =>
        init_wr_cmd_d   <= "00";
        if (BURST_LEN = 4) then
          init_rd_cmd_d   <= "01";
        else 
          init_rd_cmd_d   <= "11";
        end if;
        incr_addr       <= '1';

        --In stage 1 calibration, continuously read back data until stage 2 is
        --ready to begin.  in stage 2 read once then calibration is complete.
        --Only exit the read state when an entire sequence is complete (ie
        --on the last address of a sequence)
        if (cal_stage2_start_r = '1' and addr_cntr = "000") then
          phy_init_ns <= CAL_DONE;
        elsif (cal_stage2_start_r = '0' and cal_stage2_start ='1') then
          phy_init_ns <= CAL_WRITE;
        else
          phy_init_ns <= CAL_READ;
        end if;
        
      --Calibration Complete
      when CAL_DONE =>
        init_wr_cmd_d   <= "00";
        init_rd_cmd_d   <= "00";
        incr_addr       <= '0';
        phy_init_ns     <= CAL_DONE;

      when others =>
        init_wr_cmd_d   <= "XX";
        init_rd_cmd_d   <= "XX";
        incr_addr       <= '0';
        phy_init_ns     <= CAL_INIT;
     
    end case;
end process;--end init sm

end architecture arch;
