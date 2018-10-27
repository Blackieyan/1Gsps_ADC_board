-------------------------------------------------------------------------------
---- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
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
-- materials, includi ng for any direct, or any indirect,
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
-- signalulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : $Name:  $
--  \   \         Application        : MIG
--  /   /         Filename           : phy_read_stage2_cal.vhd
-- /___/   /\     Timestamp          : Nov 19, 2008
-- \   \  /  \    Date Last Modified : $Date: 2011/06/02 07:18:33 $
--  \___\/\___\
--
--Device: Virtex-6
--Design: QDRII+
--
--Purpose:
--  This entity
--  1. Sets the latency for fixed latency mode.
--  2. Matches latency across multiple memories.
--  3. Determines the amount of latency delay required to generate the valids.
--
--Revision History:
--
--------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_read_stage2_cal is
   generic (
      BURST_LEN           : integer := 4;		  -- Burst Length
      DATA_WIDTH          : integer := 72;		-- Total data width across all memories
      NUM_DEVICES         : integer := 2;		  -- Number of memory devices
      MEMORY_WIDTH        : integer := 36;		-- Width of each memory
      FIXED_LATENCY_MODE  : integer := 0;		  -- 0 = minimum latency mode, 1 = fixed latency mode
      PHY_LATENCY         : integer := 16;		-- Indicates the desired latency for fixed latency mode
      TCQ                 : integer := 100		-- Register delay
   );
   port (
      -- System Signals
      clk                 : in std_logic;		-- main system half freq clk
      rst_clk             : in std_logic;		-- reset syncrhonized to clk
      
      -- Stage 1 Calibration Interface
      cal_stage2_start    : in std_logic;		-- indicates latency calibration can begin
      
      -- Write Interface
      int_rd_cmd_n        : in std_logic_vector(1 downto 0);		-- read command(s) - only bit 0 is used for BL4
      
      -- DCB Interface
      read_data           : in std_logic_vector(DATA_WIDTH * 4 - 1 downto 0);		-- read data from DCB
      inc_latency         : out std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates latency through a DCB to be increased
      
      -- Valid Generator Interface
      valid_latency       : out std_logic_vector(4 downto 0);		-- amount to delay read command
      
      -- User Interface
      cal_done            : out std_logic;		-- indicates overall calibration is complete
      
      -- Phase Detector
      pd_calib_done       : in std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates phase detector calibration is complete
      cal_stage2_done     : out std_logic;		-- indicates stage 2 calibration is complete
      
      -- Chipscope/Debug and Error
      error_max_latency   : out std_logic_vector(NUM_DEVICES - 1 downto 0);		-- mem_latency counter has maxed out
      error_adj_latency   : out std_logic;		-- target PHY_LATENCY is invalid
      -- general debug port
      dbg_stage2_cal      : out std_logic_vector(127 downto 0)
   );
end entity phy_read_stage2_cal;

architecture trans of phy_read_stage2_cal is
  
  function DATA_CONST return std_logic_vector is
    variable TMP : std_logic_vector(DATA_WIDTH*4-1 downto 0);
  begin
    for i in 0 to (DATA_WIDTH-1) loop
      TMP(i*4+3 downto i*4) := x"A"; 
    end loop;
    return TMP;
  end function DATA_CONST;
  
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
 
  function bool_to_std_logic ( 
    exp : boolean
  ) return std_logic is
  begin
    if (exp) then 
      return '1';
    else
      return '0';
    end if;
  end function bool_to_std_logic;

  type dd_array is array (NUM_DEVICES - 1 downto 0) of std_logic_vector(4 downto 0);

  -- Localparams
  constant LAT_CAL_DATA : std_logic_vector(DATA_WIDTH*4-1 downto 0) := DATA_CONST;

  -- Wires and Regs
  signal bl8_rd_cmd_int        : std_logic;		-- inidicates any BL8 rd_cmd
  signal bl4_rd_cmd_int        : std_logic;		-- inidicates any BL4 rd_cmd
  signal bl2_rd_cmd_int        : std_logic;		-- indicates any BL2 rd_cmd
  signal bl8_rd_cmd_int_r      : std_logic;		-- delayed version of bl8_rd_cmd_int
  signal bl8_rd_cmd_int_r2     : std_logic;		-- delayed version of bl8_rd_cmd_r
  signal bl4_rd_cmd_int_r      : std_logic;		-- delayed version of bl4_rd_cmd_int
  signal bl2_rd_cmd_int_r      : std_logic;		-- delayed version of bl2_rd_cmd_int
  signal rd_cmd                : std_logic;		-- indicates rd_cmd for latency calibration
  signal lat_measure_done      : std_logic;		-- indicates latency measurement is complete
  signal en_mem_cntr           : std_logic;		-- memory counter enable
  signal start_lat_adj         : std_logic;		-- indicates that latency adjustment can begin
  signal en_mem_latency        : std_logic;		-- memory latency counter enable
  signal latency_cntr          : dd_array;		-- counter indicating the latency for each memory in the inteface
  signal rd0                   : std_logic_vector(DATA_WIDTH - 1 downto 0);		-- rising data 0 for all memories
  signal fd0                   : std_logic_vector(DATA_WIDTH - 1 downto 0);		-- falling data 0 for all memories
  signal rd1                   : std_logic_vector(DATA_WIDTH - 1 downto 0);		-- rising data 1 for all memories
  signal fd1                   : std_logic_vector(DATA_WIDTH - 1 downto 0);		-- falling data 1 for all memories
  signal rd0_lat               : std_logic_vector(DATA_WIDTH - 1 downto 0);		-- rising data 0 latency cal training pattern
  signal fd0_lat               : std_logic_vector(DATA_WIDTH - 1 downto 0);		-- falling data 0 latency cal training pattern
  signal rd1_lat               : std_logic_vector(DATA_WIDTH - 1 downto 0);		-- rising data 1 latency cal training pattern
  signal fd1_lat               : std_logic_vector(DATA_WIDTH - 1 downto 0);		-- falling data 1 latency cal training pattern
  signal rd0_vld               : std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates rd0 matches respective training pattern
  signal fd0_vld               : std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates fd0 matches respective training pattern
  signal rd1_vld               : std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates rd1 matches respective training pattern
  signal fd1_vld               : std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates fd1 matches respective training pattern
  signal mem_latency           : dd_array;		-- register indicating the measured latency for each memory
  signal latency_measured      : std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates that the latency has been measured for each memory
  signal mem_cntr              : std_logic_vector(4 downto 0);		-- indicates which memory is being operated on
  signal mem_cntr_done         : std_logic;		-- indicates mem_cntr has cycled through all memories
  signal max_latency           : std_logic_vector(4 downto 0);		-- maximum measured latency  
  signal max_lat_done          : std_logic;		-- indicates maximum latency measurement is done
  signal max_lat_done_r        : std_logic;		-- delayed version of max_lat_done
  signal mem_lat_adj           : dd_array;		-- amount latency needs incremented
  signal lat_adj_done          : std_logic_vector(NUM_DEVICES - 1 downto 0);		-- indicates latency adjustment is done
  signal cal_done_sig          : std_logic;
  signal cal_stage2_done_sig   : std_logic;
  signal valid_latency_sig     : std_logic_vector(4 downto 0);

begin

  -- assign outputs
  cal_done        <= cal_done_sig;
  cal_stage2_done <= cal_stage2_done_sig;
  valid_latency <= valid_latency_sig;

  -- Create rd_cmd for BL8, BL4 and BL2. BL8/BL4 only uses one bit for incoming
  -- rd_cmd's. Since this stage of calibration can't start until stage 1 is
  -- complete, mask off all incoming rd_cmd's until stage 2 begins. There can
  -- be rd_cmd's from the stage 1 calibration just after stage 2 starts. These
  -- will be masked off by looking for the rising edge of rd_cmd.
  
   bl8_rd_cmd_int <= bool_to_std_logic((BURST_LEN = 8) and (int_rd_cmd_n = "10")); 
   bl4_rd_cmd_int <= bool_to_std_logic((BURST_LEN = 4) and (int_rd_cmd_n = "10")); 
   bl2_rd_cmd_int <= bool_to_std_logic((BURST_LEN = 2) and (int_rd_cmd_n = "00"));

  process (clk) begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        bl8_rd_cmd_int_r  <= '0' after TCQ*1 ps;
        bl8_rd_cmd_int_r2 <= '0' after TCQ*1 ps;
      else
        bl8_rd_cmd_int_r  <= bl8_rd_cmd_int  after TCQ*1 ps;
        bl8_rd_cmd_int_r2 <= bl8_rd_cmd_int_r  after TCQ*1 ps;
      end if;
    end if;
  end process;


  process (clk) begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        bl4_rd_cmd_int_r <= '0' after TCQ*1 ps;
      else
        bl4_rd_cmd_int_r <= bl4_rd_cmd_int after TCQ*1 ps;
      end if;
    end if;
  end process;

  process (clk) begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        bl2_rd_cmd_int_r <= '0' after TCQ*1 ps;
      else
        bl2_rd_cmd_int_r <= bl2_rd_cmd_int after TCQ*1 ps;
      end if;
    end if;
  end process;

  
  --generate the rd_cmd flag
  BL8_RD_CMD :
  if (BURST_LEN = 8) generate
    rd_cmd <= bl8_rd_cmd_int and not(bl8_rd_cmd_int_r) and
              not(bl8_rd_cmd_int_r2) and cal_stage2_start and not(cal_done_sig);
  end generate;

  BL4_RD_CMD :
  if (BURST_LEN = 4) generate
    rd_cmd <= bl4_rd_cmd_int and not(bl4_rd_cmd_int_r) and 
              cal_stage2_start and not(cal_done_sig);
  end generate;

  BL2_RD_CMD :
  if (BURST_LEN = 2) generate
    rd_cmd <= bl2_rd_cmd_int and not(bl2_rd_cmd_int_r) and 
              cal_stage2_start and not(cal_done_sig);
  end generate;


  -- Create an enable for the latency counter. Enable it whenver the
  -- appropriate rd_cmd is seen from the initialization logic in the write
  -- interface. Since only one rd_cmd is issued during this phase, it can
  -- remain enabled after asserted for the first time.
  process (clk) begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        en_mem_latency <= '0' after TCQ*1 ps;
      elsif (cal_stage2_done_sig = '1') then
        en_mem_latency <= '0' after TCQ*1 ps;     
      elsif (rd_cmd = '1') then
        en_mem_latency <= '1' after TCQ*1 ps;
      end if;
    end if;
  end process;


  -- For each memory in the interface, determine the latency from the time the
  -- rd_cmd is issued until the expected read back data is received. This
  -- determines the latency of the system.
  mem_lat_inst :
  for nd_i in 0 to NUM_DEVICES-1 generate
  begin

      -- Count the number of cycles from the time that the rd_cmd is seen. This
      -- will be used to determine how long for the read data to be returned and
      -- hence the read latency. If latency_cntr counter maxes out, issue an 
      -- error. This is either because the latency of the read is higher than 
      -- the design can handle or because the latency calibration readback data 
      -- of AA's was never correctly received. The latency counter begins 
      -- counting from 1 since there is an additional cycle of latency in the 
      -- read path not accounted for by this read command from the 
      -- initialization logic.
      process (clk) begin
        if (clk'event and clk = '1') then
          if (rst_clk = '1') then
            latency_cntr(nd_i)      <= "00001" after TCQ*1 ps;
            error_max_latency(nd_i) <= '0' after TCQ*1 ps;
          elsif (latency_cntr(nd_i) = "11111") then
            latency_cntr(nd_i)      <= "11111" after TCQ*1 ps;
            if (latency_measured(nd_i) = '0') then
              error_max_latency(nd_i) <= '1' after TCQ*1 ps;
            else
              error_max_latency(nd_i) <= '0' after TCQ*1 ps;
            end if;
          elsif (en_mem_latency = '1' or rd_cmd = '1') then
            latency_cntr(nd_i)      <= latency_cntr(nd_i) + "00001" after TCQ*1 ps;  
            error_max_latency(nd_i) <= '0' after TCQ*1 ps;
          end if;
        end if;
      end process;

      -- Break apart the read_data bus into the various rising and falling data
      -- groups for each memory. The read_data bus is constructed as follows:
      -- read_data = {rd0, fd0, rd1, fd1}
      -- rd0 = {rd0(n), ..., rd0(1), rd0(0)}
      -- fd0 = {fd0(n), ..., fd0(1), fd0(0)}
      -- rd1 = {rd1(n), ..., rd1(1), rd1(0)}
      -- fd1 = {fd1(n), ..., fd1(1), fd1(0)}
      rd0(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) <= 
          read_data(((nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*3)+MEMORY_WIDTH-1) downto (nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*3));
      fd0(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) <= 
          read_data(((nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*2)+MEMORY_WIDTH-1) downto (nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*2));
      rd1(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) <= 
          read_data(((nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*1)+MEMORY_WIDTH-1) downto (nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*1));
      fd1(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) <= 
          read_data(((nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*0)+MEMORY_WIDTH-1) downto (nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*0));

      -- Pull off the respective LAT_CAL_DATA for each group of data.
      rd0_lat(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) <= 
          LAT_CAL_DATA(((nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*3)+MEMORY_WIDTH-1) downto (nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*3));
      fd0_lat(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) <= 
          LAT_CAL_DATA(((nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*2)+MEMORY_WIDTH-1) downto (nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*2));
      rd1_lat(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) <= 
          LAT_CAL_DATA(((nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*1)+MEMORY_WIDTH-1) downto (nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*1));
      fd1_lat(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) <= 
          LAT_CAL_DATA(((nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*0)+MEMORY_WIDTH-1) downto (nd_i*MEMORY_WIDTH+MEMORY_WIDTH*NUM_DEVICES*0));

      -- Indicate if the data for each memory matches the respective
      -- LAT_CAL_DATA.
      rd0_vld(nd_i) <= bool_to_std_logic(rd0(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) = 
                                     rd0_lat(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH));
      fd0_vld(nd_i) <= bool_to_std_logic(fd0(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) = 
                                     fd0_lat(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH));
      rd1_vld(nd_i) <= bool_to_std_logic(rd1(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) = 
                                     rd1_lat(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH));
      fd1_vld(nd_i) <= bool_to_std_logic(fd1(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH) = 
                                     fd1_lat(nd_i*MEMORY_WIDTH+MEMORY_WIDTH-1 downto nd_i*MEMORY_WIDTH));

      -- Capture the current latency count when the received data
      -- (LAT_CAL_DATA) is seen. Also indicate that the latency has been
      -- measured for this memory.
      process (clk) begin
        if (clk'event and clk = '1') then
          if (rst_clk = '1') then
            mem_latency(nd_i)       <= (others => '0') after TCQ*1 ps;
            latency_measured(nd_i)  <= '0' after TCQ*1 ps;
          elsif ((en_mem_latency = '1') and (rd0_vld(nd_i) = '1') and 
                 (fd0_vld(nd_i) = '1') and (rd1_vld(nd_i) = '1') and 
                 (fd1_vld(nd_i) = '1')) then
            mem_latency(nd_i)       <= latency_cntr(nd_i) after TCQ*1 ps;
            latency_measured(nd_i)  <= '1' after TCQ*1 ps;
          end if;
        end if;
      end process;
  end generate;

  -- Determine the maximum latency
  max_lat_inst_dev1 :
  if (NUM_DEVICES = 1) generate
  begin
    -- With only one device, the maximum latency of the system is simply the
    -- the latency determined previously.
    process (clk) begin
      if (clk'event and clk = '1') then
        if (rst_clk = '1') then
          max_latency <= (others => '0') after TCQ*1 ps;
        elsif (latency_measured(0) = '1') then
          max_latency <= mem_latency(0) after TCQ*1 ps;
        end if;
      end if;
    end process;

    process (clk) begin
      if (clk'event and clk = '1') then
        if (rst_clk = '1') then
          max_lat_done <= '0' after TCQ*1 ps;
        elsif (latency_measured(0) = '1') then
          max_lat_done <= '1' after TCQ*1 ps;
        end if;
      end if;
    end process;
  end generate;


  max_lat_inst :
  if (NUM_DEVICES > 1) generate
  begin
    lat_measure_done <= and_br(latency_measured);
    en_mem_cntr      <= (lat_measure_done and not(mem_cntr_done));

    -- Counter that cycles through each memory which will be used to determine
    -- the largest latency in the system. It only starts counting after the 
    -- latency has been measured for each device. Also indicates when all
    --  devices have been cycled through.
    process (clk) begin
      if (clk'event and clk = '1') then
        if (rst_clk = '1') then
          mem_cntr      <= (others => '0') after TCQ*1 ps;
          mem_cntr_done <= '0' after TCQ*1 ps;
        elsif ((mem_cntr = (NUM_DEVICES-1)) and (lat_measure_done = '1') 
                and (mem_cntr_done = '0')) then
          mem_cntr      <= mem_cntr after TCQ*1 ps;
          mem_cntr_done <= '1' after TCQ*1 ps;
        elsif (en_mem_cntr = '1') then
          mem_cntr      <= mem_cntr + "00001" after TCQ*1 ps;  
          mem_cntr_done <= mem_cntr_done after TCQ*1 ps;
        end if;
      end if;
    end process;

    -- As the counter for each memory device increments, the latency of that
    -- device is compared against the value in the max_latency signalister. If it
    -- is larger than the stored value, it replaces the max_latency value.
    --  This repeats for each device until the maximum latency is found.
    process (clk) begin
      if (clk'event and clk = '1') then
        if (rst_clk = '1') then
          max_latency <= (others => '0') after TCQ*1 ps;
        elsif ((mem_latency(to_integer(unsigned(mem_cntr))) > max_latency) 
               and (mem_cntr_done = '0')) then
          max_latency <= mem_latency(to_integer(unsigned(mem_cntr))) after TCQ*1 ps;
        end if;
      end if;
    end process;

    -- Indicate when maximum latency measurement is complete.
    process (clk) begin
      if (clk'event and clk = '1') then
        if (rst_clk = '1') then
          max_lat_done <= '0' after TCQ*1 ps;
        else
          max_lat_done <= mem_cntr_done after TCQ*1 ps;
        end if;
      end if;
    end process;

  end generate;

  -- Adjust the latency. For FIXED_LATENCY_MODE=1, the latency of each memory
  -- must be increased to the target PHY_LATENCY value. For
  -- FIXED_LATENCY_MODE=0, the latency of each memory is increased to the max
  -- latency of any of the memories.
  adj_lat_inst :
  if ((NUM_DEVICES > 1) or (FIXED_LATENCY_MODE = 1)) generate
  begin

      -- Determine when max_lat_done is first asserted. This will be used to
      -- initiate the latency adjustment sequence.
      process (clk) begin
        if (clk'event and clk = '1') then
          if (rst_clk = '1') then
            max_lat_done_r <= '0' after TCQ*1 ps;
          else
            max_lat_done_r <= max_lat_done after TCQ*1 ps;
          end if;
        end if;
      end process;

      start_lat_adj <= max_lat_done and not(max_lat_done_r);

      inc_lat_inst :
      for nd_j in  0 to  NUM_DEVICES-1 generate
      begin
        -- Adjust the latency as required for each memory. For
        -- FIXED_LATENCY_MODE=0, the latency for each memory must be adjusted
        -- to the maximum latency previously found within the system. For
        -- FIXED_LATENCY_MODE=1, the latency for every memory will be adjusted
        -- to the latency determined by the PHY_LATENCY parameter. Latency
        -- adjustments are made by asserting the inc_latency signal
        -- independently for each memory. For every cycle inc_latency is
        -- asserted, the latency will be increased by one.
        process (clk) begin
          if (clk'event and clk = '1') then
            if (rst_clk = '1') then
              inc_latency(nd_j)   <= '0' after TCQ*1 ps;
              mem_lat_adj(nd_j)   <= (others => '0') after TCQ*1 ps;
              lat_adj_done(nd_j)  <= '0' after TCQ*1 ps;

            elsif (start_lat_adj = '1') then
              if (FIXED_LATENCY_MODE = 0) then
                inc_latency(nd_j)   <= '0' after TCQ*1 ps;
                mem_lat_adj(nd_j)   <= max_latency - mem_latency(nd_j) after TCQ*1 ps;
                lat_adj_done(nd_j)  <= '0' after TCQ*1 ps;
              else 
                inc_latency(nd_j)   <= '0' after TCQ*1 ps;
                mem_lat_adj(nd_j)   <= PHY_LATENCY - mem_latency(nd_j) after TCQ*1 ps;
                lat_adj_done(nd_j)  <= '0';
              end if;
            elsif (max_lat_done_r = '1') then
              if (mem_lat_adj(nd_j) = 0) then
                inc_latency(nd_j)   <= '0' after TCQ*1 ps;
                mem_lat_adj(nd_j)   <= (others => '0') after TCQ*1 ps;
                lat_adj_done(nd_j)  <= '1' after TCQ*1 ps;
              else
                inc_latency(nd_j)   <= or_br(mem_lat_adj(nd_j)) after TCQ*1 ps;
                mem_lat_adj(nd_j)   <= mem_lat_adj(nd_j) - 1 after TCQ*1 ps;
                lat_adj_done(nd_j)  <= '0' after TCQ*1 ps;
              end if;
            end if;
          end if;
        end process;
        end generate;

        -- Issue an error if in FIXED_LATENCY_MODE=1 and the target PHY_LATENCY
        -- is less than what the system can safely provide.
        process (clk) begin
          if (clk'event and clk = '1') then
            if (rst_clk = '1') then
              error_adj_latency <= '0' after TCQ*1 ps;
            elsif ((FIXED_LATENCY_MODE = 1) and start_lat_adj = '1') then
              if (PHY_LATENCY < max_latency) then
                error_adj_latency <= '1' after TCQ*1 ps;
              end if;
            end if;
          end if;
        end process;

        -- Signal that stage 2 calibration is complete once the latencies have
        -- been adjusted.
        process (clk) begin
          if (clk'event and clk = '1') then
            if (rst_clk = '1') then
              cal_stage2_done_sig <= '0' after TCQ*1 ps;
            else
              cal_stage2_done_sig <= or_br(lat_adj_done) after TCQ*1 ps;
            end if;
          end if;
        end process;

      
  end generate;

  adj_lat_inst_dev1 :
  if (not((NUM_DEVICES > 1) or (FIXED_LATENCY_MODE = 1))) generate
  begin
    -- Since no latency adjustments are required for single memory interface
    -- with FIXED_LATENCY_MODE=0, calibration can be signaled as soon as
    -- max_lat_done is asserted
    process (clk) begin
      if (clk'event and clk = '1') then
        if (rst_clk = '1') then
          cal_stage2_done_sig <= '0' after TCQ*1 ps;
        else
          cal_stage2_done_sig <= max_lat_done after TCQ*1 ps;
        end if;
      end if;
    end process;
        
    -- Tie off error_adj_latency signal
    process (clk) begin
      if (clk'event and clk = '1') then
        error_adj_latency <= '0' after TCQ*1 ps;
      end if;
    end process;
  end generate;

  -- The final step is to indicate to the vld_gen logic how much to delay
  -- incoming rd_cmd's by in order to align them with the read data. This
  -- latency to the vld_gen logic is set to either the max_latency - 3
  -- FIXED_LATENCY_MODE=0) or PHY_LATENCY - 3 (FIXED_LATENCY_MODE=1). The
  -- minus 3 is to account for the extra cycles out of the vld_gen logic.
  process (clk) begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        valid_latency_sig <= (others => '0') after TCQ*1 ps;
      elsif (cal_stage2_done_sig = '1') then
        valid_latency_sig <= valid_latency_sig after TCQ*1 ps;
      elsif (FIXED_LATENCY_MODE = 0) then
        valid_latency_sig <= max_latency - "00011" after TCQ*1 ps;
      else
        valid_latency_sig <= std_logic_vector(to_unsigned((PHY_LATENCY-3), 5)) after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Indicate overall calibration is complete once stage 2 calibration is done
  -- and each phase detector has completed calibration.
  process (clk) begin
    if (clk'event and clk = '1') then
      if (rst_clk = '1') then
        cal_done_sig <= '0' after TCQ*1 ps;
      else
        cal_done_sig <= and_br(pd_calib_done) and cal_stage2_done_sig after TCQ*1 ps;
      end if;
    end if;
  end process;

  -- Assign debug signals
   dbg_stage2_cal(0)              <= en_mem_latency;
   dbg_stage2_cal(5 downto 1)     <= latency_cntr(0);
   dbg_stage2_cal(6)              <= rd_cmd;
   dbg_stage2_cal(7)              <= latency_measured(0);
   dbg_stage2_cal(8)              <= bl4_rd_cmd_int;
   dbg_stage2_cal(9)              <= bl4_rd_cmd_int_r;
   dbg_stage2_cal(127 downto 10)  <= (others => '0');

end architecture;
