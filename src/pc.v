`ifndef PC_V
`define PC_V

`timescale 1ns/1ns

module pc (
    input rst_i,
    input clk_i,
    output [31:0] pc_o,
    input [31:0] pc_i,
    input setPc_i
);
parameter RESET = 32'h00000000;

reg [31:0] pcNormal;//use this instead of pc_o to ease implementation of interrupts in the future
assign pc_o = pcNormal;

always @(posedge(clk_i),posedge(rst_i)) begin
    if (rst_i) pcNormal <= RESET;
    else if (clk_i) begin
        if (setPc_i) pcNormal <= pc_i;
    end
end

endmodule

`endif //PC_V
