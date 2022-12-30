`timescale 1ns/1ns

module tst_registerfile (
    input clk_i,
    input rst_i,
    input [31:0] rd_i,
    output reg [31:0] rs1_o,
    output reg [31:0] rs2_o,
    input [4:0] selRd_i,
    input [4:0] selRs1_i,
    input [4:0] selRs2_i
   );

registerfile top(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .rd_i(rd_i),
    .rs1_o(rs1_o),
    .rs2_o(rs2_o),
    .selRd_i(selRd_i),
    .selRs1_i(selRs1_i),
    .selRs2_i(selRs2_i)
);

initial begin
    $dumpfile("logs/vlt_dump.vcd");
    $dumpvars();
end

endmodule
