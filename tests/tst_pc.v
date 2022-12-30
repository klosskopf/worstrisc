`timescale 1ns/1ns

module tst_pc (
    input rst_i,
    input clk_i,
    output reg [31:0] pc_o,
    input reg [31:0] pc_i,
    input setPc_i
   );

pc #(.RESET(32'h12345678)) top(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .pc_o(pc_o),
    .pc_i(pc_i),
    .setPc_i(setPc_i)
);

initial begin
    $dumpfile("logs/vlt_dump.vcd");
    $dumpvars();
end

endmodule
