`include "riscvWb.v"
`timescale 1ns/1ns

module tst_riscvWb (
   input rst_i,
   input clk_i,
   output reg [29:0] adr_o,
   input [31:0] dat_i,
   output reg [31:0] dat_o,
   output reg we_o,
   output reg [3:0] sel_o,
   output reg stb_o,
   input ack_i,
   output reg cyc_o
   );

riscvWb top(
   .rst_i(rst_i),
   .clk_i(clk_i),
   .adr_o(adr_o),  //the wishbone mem is connected word addressed, but the master outputs bytes
   .dat_i(dat_i),
   .dat_o(dat_o),
   .we_o(we_o),
   .sel_o(sel_o),
   .stb_o(stb_o),
   .ack_i(ack_i),
   .cyc_o(cyc_o)
   );

initial begin
    $dumpfile("logs/vlt_dump.vcd");
    $dumpvars();
end

endmodule
