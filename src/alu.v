`ifndef ALU_V
`define ALU_V

`timescale 1ns/1ns

module alu (
    input rst_i,
    input clk_i,
    input [31:0] aluArg1_i,
    input [31:0] aluArg2_i,
    output reg [31:0] aluRes_o,
    input [2:0] funct3_i,
    input subSr_i,
    output reg done_o
);

//ADD/SUB IMPORTANT: To not make a total mess, always perform add/sub in one cycle (We don't want to wait for the alu before making a memory request)
reg [31:0] addRes;
reg addDone = 1'b1;
always @(*) begin
    if (subSr_i) addRes = aluArg1_i - aluArg2_i;
    else addRes = aluArg1_i + aluArg2_i;
end

//SLL/SRL/SRA
reg [31:0] shiftRes;
reg shiftDone = 1'b1;
`define SHIFT_IDLE 0
`define SHIFT_DO 1
reg [0:0] shiftState;
reg [4:0] shiftCounter;
always @(posedge(clk_i),posedge(rst_i)) begin
    if (rst_i) shiftState <= `SHIFT_IDLE;
    else if (clk_i) begin
        case (shiftState)
            `SHIFT_IDLE: if ((funct3_i == 3'b001) || (funct3_i == 3'b101)) begin shiftState <= `SHIFT_DO; shiftCounter <= aluArg2_i[4:0]; end
            `SHIFT_DO: begin
                if (shiftCounter == 5'b0) shiftState <= `SHIFT_IDLE;
                else shiftCounter <= shiftCounter - 1'b1;
            end
            default: shiftState <= `SHIFT_IDLE;
        endcase
    end
end
always @(posedge(clk_i)) begin
    if (clk_i) begin
        case (shiftState)
            `SHIFT_IDLE: shiftRes <= aluArg1_i;
            `SHIFT_DO: begin
                if (funct3_i == 3'b001) shiftRes <= {shiftRes[30:0], 1'b0};//shiftRes <= shiftRes << 1;
                else if (funct3_i == 3'b101) begin
                    if (subSr_i | aluArg2_i[10]) shiftRes <= {shiftRes[31], shiftRes[31:1]};//shiftRes <= $signed(shiftRes) >>> 1;
                    else shiftRes <= {1'b0, shiftRes[31:1]};//shiftRes <= shiftRes >> 1;
                end
            end
            default: shiftRes <= 32'hxxxxxxxx;
        endcase
    end
end
always @(*) begin
    shiftDone = 1'b0;
    if (shiftState == `SHIFT_DO) begin
        if (shiftCounter == 5'b0) shiftDone = 1'b1;
    end
end

//SLT
reg [31:0] sltRes;
reg sltDone = 1'b1;
always @(*) begin
    sltRes = ($signed(aluArg1_i) < $signed(aluArg2_i)) ? 32'b1 : 32'b0;
end

//SLTU
reg [31:0] sltuRes;
reg sltuDone = 1'b1;
always @(*) begin
    sltuRes = (aluArg1_i < aluArg2_i) ? 32'b1 : 32'b0;
end

//XOR
reg [31:0] xorRes;
reg xorDone = 1'b1;
always @(*) begin
    xorRes = aluArg1_i ^ aluArg2_i;
end

//OR
reg [31:0] orRes;
reg orDone = 1'b1;
always @(*) begin
    orRes = aluArg1_i | aluArg2_i;
end

//AND
reg [31:0] andRes;
reg andDone = 1'b1;
always @(*) begin
    andRes = aluArg1_i & aluArg2_i;
end

always @(*) begin
    case (funct3_i)
        3'b000: begin aluRes_o = addRes; done_o = addDone; end//ADD/SUB
        3'b001,3'b101: begin aluRes_o = shiftRes; done_o = shiftDone; end//SLL/SRL/SRA
        3'b010: begin aluRes_o = sltRes; done_o = sltDone; end//SLT
        3'b011: begin aluRes_o = sltuRes; done_o = sltuDone; end//SLTU
        3'b100: begin aluRes_o = xorRes; done_o = xorDone; end//XOR
        3'b110: begin aluRes_o = orRes; done_o = orDone; end//OR
        3'b111: begin aluRes_o = andRes; done_o = andDone; end//AND
        default: begin aluRes_o = 32'hxxxxxxxx; done_o = 1'b1; end
    endcase
end
    
endmodule

`endif //ALU_V
