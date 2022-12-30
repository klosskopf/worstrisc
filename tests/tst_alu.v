`include "alu.v"
`timescale 1ns/1ns

module tst_alu (
    input rst_i,
    input clk_i,
    input [31:0] aluArg1_i,
    input [31:0] aluArg2_i,
    output reg [31:0] aluRes_o,
    input [2:0] funct3_i,
    input subSr_i,
    output done_o
);

alu top(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .aluArg1_i(aluArg1_i),
    .aluArg2_i(aluArg2_i),
    .aluRes_o(aluRes_o),
    .funct3_i(funct3_i),
    .subSr_i(subSr_i),
    .done_o(done_o)
);

initial begin
    $dumpfile("logs/vlt_dump.vcd");
    $dumpvars();
end
    
endmodule
