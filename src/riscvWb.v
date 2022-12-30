`timescale 1ns/1ns

module riscvWb (
    input rst_i,               //reset wishbone and riscv; active high
    input clk_i,               //clock input
    output [31:2] adr_o,       //32bit address bus
    input [31:0] dat_i,        //32bit Data in
    output reg [31:0] dat_o,   //32bit Data out
    output we_o,           //marks a cycle as write to memory
    output reg [3:0] sel_o,    //marks the data bytes used in a transaction
    output stb_o,              //marks the request for a transaction. Must be answered by a ack; In this case identical with cyc_o
    input ack_i,               //marks the complete transaction; set by slave
    output cyc_o           //if high, a cycle is requested/active
);
parameter RESET = 32'h0;   //reset the pc to 0

wire [31:0] reqAdr;
reg [31:0] datMiso;
wire [31:0] datMosi;
wire [2:0] byteNr;
wire req;
assign adr_o = reqAdr[31:2];
assign stb_o = req;
assign cyc_o = req;

riscv #(.RESET(RESET)) cpu(
   .rst_i(rst_i),
   .clk_i(clk_i),
   .req_o(req),
   .we_o(we_o),
   .adr_o(reqAdr),
   .dat_i(datMiso),
   .dat_o(datMosi),
   .byteNr_o(byteNr),
   .done_i(ack_i)
);

//calculate select
always @(*) begin
    sel_o = 4'hx;
    if (byteNr == 3'd1) begin
        if (reqAdr[1:0] == 2'b00) sel_o = 4'b0001;
        else if (reqAdr[1:0] == 2'b01) sel_o = 4'b0010;
        else if (reqAdr[1:0] == 2'b10) sel_o = 4'b0100;
        else if (reqAdr[1:0] == 2'b11) sel_o = 4'b1000;
    end
    else if (byteNr == 3'd2) begin
        if (reqAdr[1]) sel_o = 4'b1100;
        else sel_o = 4'b0011;
    end
    else if (byteNr == 3'd4) sel_o = 4'b1111;   
end
//shift data out acording to alingment
always @(*) begin
    dat_o = 32'hxxxxxxxx;
    if (reqAdr[1:0] == 2'b00) dat_o = datMosi;
    else if (reqAdr[1:0] == 2'b01) dat_o = {16'hxxxx,datMosi[7:0],8'hxx};
    else if (reqAdr[1:0] == 2'b10) dat_o = {datMosi[15:0],16'hxxxx};
    else if (reqAdr[1:0] == 2'b11) dat_o = {datMosi[7:0],24'hxxxxxx};
end
//shift data in acording to alignment
always @(*) begin
    datMiso = 32'hxxxxxxxx;
    if (reqAdr[1:0] == 2'b00) datMiso = dat_i;
    else if (reqAdr[1:0] == 2'b01) datMiso = {24'hxxxxxx,dat_i[15:8]};
    else if (reqAdr[1:0] == 2'b10) datMiso = {16'hxxxx,dat_i[31:16]};
    else if (reqAdr[1:0] == 2'b11) datMiso = {24'hxxxxxx,dat_i[31:24]};
end

endmodule
