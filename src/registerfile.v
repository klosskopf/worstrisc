`timescale 1ns/1ns

module registerfile (
    input clk_i,
    input rst_i,
    input [31:0] rd_i,
    output reg [31:0] rs1_o,
    output reg [31:0] rs2_o,
    input [4:0] selRd_i,
    input [4:0] selRs1_i,
    input [4:0] selRs2_i
);

/*The register file*/
reg [31:0] registers [31:1];

/*writing to a register*/
always @(posedge(clk_i)) begin
    if(clk_i) begin
        if(selRd_i != 5'b0) registers[selRd_i] <= rd_i;
    end
end

/*reading from register*/
always @(*) begin
    if (selRs1_i != 5'b0) rs1_o = registers[selRs1_i];
    else rs1_o = 32'b0;
end
always @(*) begin
    if (selRs2_i != 5'b0) rs2_o = registers[selRs2_i];
    else rs2_o = 32'b0;
end

endmodule
