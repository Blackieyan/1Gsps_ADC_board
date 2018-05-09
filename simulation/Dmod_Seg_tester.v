// Verilog Test Fixture Template

  `timescale 1 ns / 1 ps

  module Dmod_Seg_tester;
   reg clk;
   reg posedge_sample_trig;
   reg rst_n;
   reg [15:0] cmd_smpl_depth;
   reg [31:0] Pstprc_RAM_dina；
   reg Pstprc_RAMQ_clka;
   reg Pstprc_RAMQ_clkb;
   reg [14:0] demoWinln_twelve;
   reg [14:0] demoWinstart_twelve;
   wire [63:0] pstprc_IQ_seq_o;
   wire        Pstprc_finish;
   reg [15:0] Pstprc_DPS_twelve;
   reg        pstprc_num_en;
   reg [3:0]   Pstprc_num;
   wire        pstprc_fifo_wren;



          Dmod_Seg inst_Dmod_Seg
            (
             .clk(clk),
             .posedge_sample_trig(posedge_sample_trig),
			 .rst_n(rst_n),
             .cmd_smpl_depth(cmd_smpl_depth),
             .Pstprc_RAMQ_dina(Pstprc_RAMQ_dina),
             .Pstprc_RAMQ_clka(Pstprc_RAMQ_clka),
             .Pstprc_RAMQ_clkb(Pstprc_RAMQ_clkb),
             .demoWinln_twelve(demoWinln_twelve),
             .demoWinstart_twelve(demoWinstart_twelve),
             .pstprc_IQ_seq_o(pstprc_IQ_seq_o),
             .Pstprc_finish(Pstprc_finish),
             .Pstprc_DPS_twelve(Pstprc_DPS_twelve),
             .pstprc_num_en(pstprc_num_en),
             .Pstprc_num(Pstprc_num),
             .pstprc_fifo_wren(pstprc_fifo_wren)
          );



   // The following code initializes the Global Set Reset (GSR) and Global Three-State (GTS) nets
   // Refer to the Synthesis and Simulation Design Guide for more information on this process
/* -----\/----- EXCLUDED -----\/-----
   reg GSR;
   assign glbl.GSR = GSR;
   reg GTS;
   assign glbl.GTS = GTS;
 -----/\----- EXCLUDED -----/\----- */



   initial begin
      forever begin
        #4 clk=!clk;
      end
   end

   assign Pstprc_RAMQ_clka = clk;
   assign Pstprc_RAMQ_clkb =clk;
   assign Pstprc_RAMI_clka =clk;
   assign Pstprc_RAMI_clkb =clk;

   initial begin
      clk =0;
      posedge_sample_trig = 0;
      rst_n= 0;
      cmd_smpl_depth = 32'h07d0;
      Pstprc_RAMQ_dina = 32'h0000;
      Pstprc_RAMQ_clka =0;
      Pstprc_RAMQ_clkb =0;
      demoWinln_twelve = {3'b000,12'h5dc};
      pstprc_IQ_seq_o = 64'h00000000;
      Pstprc_finish =0;
      Pstprc_DPS_twelve =16'h0000;
      pstprc_num_en =0;
      Pstprc_num = 4'h0;
      pstprc_fifo_wren = 0;
      #1000
        rst_n = '1';

   end

  endmodule
