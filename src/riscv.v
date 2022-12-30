`timescale 1ns/1ns

module riscv(
   input rst_i,               //reset riscv; active high
   input clk_i,               //clock input
   output reg req_o,              //marks the request for a transaction. Must be answered by done_i
   output reg we_o,           //marks a cycle as write to memory
   output reg [31:0] adr_o,       //32bit address bus
   input [31:0] dat_i,        //32bit Data in
   output reg [31:0] dat_o,   //32bit Data out
   output reg [2:0] byteNr_o, //marks the data bytes used in a transaction
   input done_i               //marks the complete transaction; set by slave
);
parameter RESET = 32'h0;   //reset the pc to 0
   
//The Prozessor State
`define FETCH_STATE 0   //Fetch a new comannd
`define EXECUTE_STATE 1 //Execute the command
`define FAULT_STATE 2
reg [1:0] state;
//The Instruction register
reg [31:0] ir;
//The instruction opcode like store, load immediate alu; used for data flows; Maybe make these individual wires (makes debugging worse, but improves readability)
`define LUI 1
`define AUIPC 2
`define JAL 4
`define JALR 8
`define BRANCH 16
`define LOAD 32
`define STORE 64
`define OP_IMM 128
`define OP 256
`define MISC_MEM 512
`define SYSTEM 1024
reg [10:0] instOpcode;
//The instruction type as defined by riscv. mostly used for further decoding and immediate generation
`define R_TYPE 1
`define I_TYPE 2
`define S_TYPE 4
`define B_TYPE 8
`define U_TYPE 16
`define J_TYPE 32
reg [5:0] instType;
//The immediate generated from the instruction register
reg [31:0] immediate;

//Instruction complete. Indicates a instruction is done and the next can be fetched
reg instDone;

/*Instantiate the PC*/
wire [31:0] pc_o; //outputs always the current pc
reg [31:0] pc_i;  //input of the new pc
reg setPc_i;      //apply pc_i to the pc
pc #(.RESET(RESET)) pc(
   .rst_i(rst_i),
   .clk_i(clk_i),
   .pc_o(pc_o),
   .pc_i(pc_i),
   .setPc_i(setPc_i)
);

/*Instantiate the Registerfile*/
wire [31:0] rs1_o;   //output of a register
wire [31:0] rs2_o;   //output of a second register
reg [31:0] rd_i;     //input to write a register
reg [4:0] selRd_i;   //choose the register to be written to (write to x0 des nothing)
reg [4:0] selRs1_i;  //choose the register to be output on rs1_o
reg [4:0] selRs2_i;  //choose the register to be output on rs2_o
registerfile registerfile(
   .rst_i(rst_i),
   .clk_i(clk_i),
   .rs1_o(rs1_o),
   .rs2_o(rs2_o),
   .rd_i(rd_i),
   .selRd_i(selRd_i),
   .selRs1_i(selRs1_i),
   .selRs2_i(selRs2_i)
);

/*Instantiate the ALU*/
reg [31:0] aluArg1_i;   //The first argument of the alu
reg [31:0] aluArg2_i;   //The second argument of the alu (aluArg1-aluArg2; aluArg1<<aluArg2)
wire [31:0] aluRes_o;   //The result of the alu operation
reg [2:0] funct3_i;     //choose the alu operation
reg subSr_i;            //OP instructions use this to choose SUB and SRA; OPIMM instructions use the 10th bit of the immediate 
wire aluDone_o;         //Value at aluRes_o is valid
alu alu(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .aluArg1_i(aluArg1_i),
    .aluArg2_i(aluArg2_i),
    .aluRes_o(aluRes_o),
    .funct3_i(funct3_i),
    .subSr_i(subSr_i),
    .done_o(aluDone_o)
);


reg fault;
/*CPU Cycles(Not a pipelined CPU)*/
always @(posedge(clk_i),posedge(rst_i)) begin
   if (rst_i) state <= `FETCH_STATE;            //start in a fetch state
   else if(clk_i) begin
      if (state == `FETCH_STATE) begin
         if (done_i) begin
            if (fault) state <= `FAULT_STATE;
            else state <= `EXECUTE_STATE;    //if fetch is complete (done_i) change to execution state
         end
      end
      else if (state == `EXECUTE_STATE) begin
         if (instDone) state <= `FETCH_STATE;  //if execution is complete change to fetch state 
      end
   end
end

/*Instruction done*/
always @(*) begin
   case (instOpcode)
      `OP, `OP_IMM: instDone = aluDone_o; //Alu may use multiple cycles
      `LOAD, `STORE: instDone = done_i;    //Load and Store can be halted by a slave
      default: instDone = 1'b1;           //All others are always ready
   endcase
end

/*address output*/
always @(*) begin
   adr_o = 32'h0;
   if (state == `FETCH_STATE) adr_o = pc_o;
   else if (state == `EXECUTE_STATE) begin
      if (instOpcode == `LOAD | instOpcode == `STORE) adr_o = aluRes_o;
   end
end

/*Wishbone Interface*/
always @(*) begin
   if (rst_i) begin
      dat_o = 32'b0;
      we_o = 1'b0;
      byteNr_o = 3'd0;
      req_o = 1'b0;
   end
   else if (state == `FETCH_STATE) begin
      dat_o = 32'b0;    //Maybe change to 32'hxxxxxxxx
      we_o = 1'b0;
      byteNr_o = 3'd4;  //Only 32bit instructions
      req_o = 1'b1;
   end
   else if (state == `EXECUTE_STATE) begin
      case (instOpcode)
         `LOAD: begin
            dat_o = 32'h0;    //Maybe change to 32'hxxxxxxxx
            we_o = 1'b0;
            if (ir[13:12] == 2'b00) byteNr_o = 3'd1;      //LB / LBU
            else if (ir[13:12] == 2'b01) byteNr_o = 3'd2; //LH / LHU
            else if (ir[13:12] == 2'b10) byteNr_o = 3'd4; //LW
            else byteNr_o = 3'dx;
            req_o = 1'b1;
         end
         `STORE: begin
            we_o = 1'b1;
            dat_o = rs2_o;
            if (ir[13:12] == 2'b00) byteNr_o = 3'd1;      //SB
            else if (ir[13:12] == 2'b01) byteNr_o = 3'd2; //SH
            else if (ir[13:12] == 2'b10) byteNr_o = 3'd4; //SW
            else byteNr_o = 3'dx;
            req_o = 1'b1;
         end
         default: begin
            dat_o = 32'hx;
            we_o = 1'bx;
            byteNr_o = 3'dx;
            req_o = 1'b0;
         end
      endcase
   end
   else begin
      dat_o = 32'hxxxxxxxx;
      we_o = 1'bx;
      byteNr_o = 3'dx;
      req_o = 1'bx;
   end
end

/*Instruction register*/
always @(posedge(clk_i), posedge(rst_i)) begin
   if (rst_i) ir <= 32'h13;  //NOP
   else if (clk_i) begin
      if (state == `FETCH_STATE && done_i) begin //if the fetch state is finished (done_i) load the next instruction
         ir <= dat_i;
      end
   end
end
/*opcode decoding*/
always @(*) begin
   fault = 1'b0;
   case (ir[6:0]) //This could obviously improved with a little bit of logic and KV
      7'b0110111: instOpcode = `LUI;
      7'b0010111: instOpcode = `AUIPC;
      7'b1101111: instOpcode = `JAL;
      7'b1100111: instOpcode = `JALR;
      7'b1100011: instOpcode = `BRANCH;
      7'b0000011: instOpcode = `LOAD;
      7'b0100011: instOpcode = `STORE;
      7'b0010011: instOpcode = `OP_IMM;
      7'b0110011: instOpcode = `OP;
      default: begin
         fault = 1'b1;
         instOpcode = 11'bxxxxxxxxxxx;
      end
   endcase
end
/*type decoding*/
always @(*) begin
   case (instOpcode)   //Every opcode has one immediate type
      `OP: instType = `R_TYPE;
      `LOAD, `OP_IMM, `JALR: instType = `I_TYPE;
      `STORE: instType = `S_TYPE;
      `BRANCH: instType = `B_TYPE;
      `LUI, `AUIPC: instType = `U_TYPE;
      `JAL: instType = `J_TYPE;
      default: instType = 6'bxxxxxx;
   endcase
end
/*Immediate generation*/
always @(*) begin
   case (instType)  //See RISCV-Spec unpriv. Page 17.
      `I_TYPE: immediate = {{21{ir[31]}},ir[30:20]};
      `S_TYPE: immediate = {{21{ir[31]}},ir[30:25],ir[11:7]};
      `B_TYPE: immediate = {{20{ir[31]}},ir[7],ir[30:25],ir[11:8],1'b0};
      `U_TYPE: immediate = {ir[31:12],12'b0};
      `J_TYPE: immediate = {{12{ir[31]}},ir[19:12],ir[20],ir[30:21],1'b0};
      default: immediate = 32'hxxxxxxxx;
   endcase
end

/*Program Counter control interface*/
always @(*) begin
   if(state == `FETCH_STATE) setPc_i = 1'b0;
   else if (state == `EXECUTE_STATE && instDone) setPc_i = 1'b1; //only change the pc at the end of a executed state
   else setPc_i = 1'b0; //Yeah, no idea how I should get here
end
/*Program Counter data interface*/
always @(*) begin
   if(state == `FETCH_STATE) pc_i = 32'hxxxxxxxx;
   else if (state == `EXECUTE_STATE) begin
      case (instOpcode)
         `JAL, `JALR: pc_i = aluRes_o; //unconditional branches
         `BRANCH: begin                //conditional branches
            if ((ir[14:12] == 3'b000) && (rs1_o == rs2_o)) pc_i = aluRes_o;                        //BEQ
            else if ((ir[14:12] == 3'b001) && (rs1_o != rs2_o)) pc_i = aluRes_o;                   //BNE
            else if ((ir[14:12] == 3'b100) && ($signed(rs1_o) < $signed(rs2_o))) pc_i = aluRes_o;  //BLT
            else if ((ir[14:12] == 3'b101) && ($signed(rs1_o) >= $signed(rs2_o))) pc_i = aluRes_o; //BGE
            else if ((ir[14:12] == 3'b110) && (rs1_o < rs2_o)) pc_i = aluRes_o;                    //BLTU
            else if ((ir[14:12] == 3'b111) && (rs1_o >= rs2_o)) pc_i = aluRes_o;                   //BGEU
            else pc_i = pc_o + 32'h4;                                                              //invalid branch instruction or false condition
         end
         default: pc_i = pc_o + 32'h4; //every other instruction advances the PC 
      endcase
   end
   else pc_i = 32'hxxxxxxxx;
end

/*Registerfile control interface read*/
always @(*) begin
   if (state == `EXECUTE_STATE) begin
      case (instOpcode)
         `OP_IMM, `JALR, `LOAD: begin
            selRs1_i = ir[19:15];
            selRs2_i = 5'bxxxxx;
         end
         `OP, `STORE, `BRANCH: begin
            selRs1_i = ir[19:15];
            selRs2_i = ir[24:20];
         end
         default: begin
            selRs1_i = 5'bxxxxx;
            selRs2_i = 5'bxxxxx;
         end
      endcase
   end
   else begin
      selRs1_i = 5'bxxxxx;
      selRs2_i = 5'bxxxxx;
   end
end
/*Registerfile control interface write*/
always @(*) begin
   if (state == `EXECUTE_STATE && instDone) begin
      case (instOpcode)
         `LUI, `AUIPC, `LOAD, `OP_IMM, `OP, `JAL,`JALR : selRd_i = ir[11:7];  //These instructions write back to the registerfile
         default: selRd_i = 5'b0;                                             //Other ones don't selRd_i means no write
      endcase
   end
   else selRd_i = 5'b0;
end
/*Registerfile data interface*/
always @(*) begin
   if (state == `EXECUTE_STATE) begin
      case (instOpcode)
         `LUI: rd_i = immediate; //LUI just loads the immediate in a register
         `AUIPC, `OP_IMM, `OP: rd_i = aluRes_o; //AUIPC uses the alu for offset calculation
         `LOAD: begin //ir[14] marks if the load is unsigned or signed
            if (ir[13:12] == 2'b00) rd_i = {{24{dat_i[7] & !ir[14]}},dat_i[7:0]}; //LB / LBU
            else if (ir[13:12] == 2'b01) rd_i = {{16{dat_i[15] & !ir[14]}},dat_i[15:0]}; //LH / LHU
            else if (ir[13] == 1'b1) rd_i = dat_i; //LW
            else rd_i = 32'hxxxxxxxx; //invalid Load. You are free to load garbage
         end
         `JAL, `JALR: rd_i = pc_o + 32'h00000004; //JAL and JALR store the instruction after the jump in a link register
         default: rd_i = 32'hxxxxxxxx;
      endcase
   end
   else rd_i = 32'hxxxxxxxx;
end

/*ALU control interface*/
always @(*) begin
   if (state == `EXECUTE_STATE) begin
      case (instOpcode)
         `OP: begin
            funct3_i = ir[14:12];   //A normal operation instruction
            subSr_i = ir[30];       //tells the ALU if operation is SUB or SRA
         end
         `OP_IMM: begin
            funct3_i = ir[14:12];   //A normal operation instruction
            subSr_i = 1'b0;         //SRAI is encoded in aluArg2_i, because ir[30] can be set by a immediate of ex. a ADDI instruction. Why the fuck didn't they just spend another funct3 bit
         end
         `JAL, `JALR, `LOAD, `STORE, `BRANCH, `AUIPC: begin
            funct3_i = 3'b0;        //These instructions use the ALUs adder to perform offsets
            subSr_i = 1'b0;
         end
         default: begin
            funct3_i = 3'b000;      //leaving this x, could start a shift
            subSr_i = 1'b0;
         end
      endcase
   end
   else begin
      funct3_i = 3'b000;
      subSr_i = 1'b0;
   end
end
/*ALU data interface*/
always @(*) begin
   case (instOpcode)
      `OP: begin
         aluArg1_i = rs1_o;      //OP uses rs1 and rs2
         aluArg2_i = rs2_o;
      end
      `OP_IMM, `JALR, `LOAD, `STORE: begin
         aluArg1_i = rs1_o;      //OPIMM uses rs1 and a immediate; JALR, LOAD and Store perform offsets of a register value 
         aluArg2_i = immediate;
      end
      `JAL, `BRANCH, `AUIPC: begin
         aluArg1_i = pc_o;       //JAL, BRANCH and AUIPC perform offsets of the PC
         aluArg2_i = immediate;
      end
      default: begin
         aluArg1_i = 32'hxxxxxxxx;
         aluArg2_i = 32'hxxxxxxxx;
      end
   endcase
end

endmodule
