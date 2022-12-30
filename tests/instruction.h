#include <stdint.h>

#define NOP i_type(0,0,0,0,0b0010011) //ADDI 0 + x0 to x0
#define LUI(imm, rd) u_type(imm,rd,0b0110111)
#define AUIPC(imm, rd) u_type(imm,rd,0b0010111)
#define JAL(imm, rd) j_type(imm,rd,0b1101111)
#define ADDI(rs1, imm, rd) i_type(imm,rs1,0,rd,0b0010011)
#define SB(imm, rs1, rs2) s_type(imm, rs2, rs1, 0, 0b0100011)
#define SH(imm, rs1, rs2) s_type(imm, rs2, rs1, 1, 0b0100011)
#define SW(imm, rs1, rs2) s_type(imm,rs2,rs1,2,0b0100011)
#define BEQ(rs1, rs2, imm) b_type(imm, rs2, rs1, 0, 0b1100011)
#define BNE(rs1, rs2, imm) b_type(imm, rs2, rs1, 1, 0b1100011)
#define BLT(rs1, rs2, imm) b_type(imm, rs2, rs1, 4, 0b1100011)
#define BGE(rs1, rs2, imm) b_type(imm, rs2, rs1, 5, 0b1100011)
#define BLTU(rs1, rs2, imm) b_type(imm, rs2, rs1, 6, 0b1100011)
#define BGEU(rs1, rs2, imm) b_type(imm, rs2, rs1, 7, 0b1100011)
#define LW(imm, rs1, rd) i_type(imm, rs1, 2, rd, 0b0000011)
#define SLLI(shamt, rs1, rd) i_type(shamt, rs1, 1, rd, 0b0010011)
#define SRLI(shamt, rs1, rd) i_type(shamt, rs1, 5, rd, 0b0010011)
#define SRAI(shamt, rs1, rd) i_type(shamt + 1024, rs1, 5, rd, 0b0010011)
#define SLL(rs1, rs2, rd) r_type(0, rs2, rs1, 1, rd, 0b0110011)
#define SRL(rs1, rs2, rd) r_type(0, rs2, rs1, 5, rd, 0b0110011)
#define SRA(rs1, rs2, rd) r_type(0b0100000, rs2, rs1, 5, rd, 0b0110011)
#define LB(imm, rs1, rd) i_type(imm, rs1, 0, rd, 0b0000011)
#define LH(imm, rs1, rd) i_type(imm, rs1, 1, rd, 0b0000011)
#define LW(imm, rs1, rd) i_type(imm, rs1, 2, rd, 0b0000011)
#define LBU(imm, rs1, rd) i_type(imm, rs1, 4, rd, 0b0000011)
#define LHU(imm, rs1, rd) i_type(imm, rs1, 5, rd, 0b0000011)


class instruction
{
public:
    uint32_t asBinary;
    operator uint32_t() const
    {
        return asBinary;
    }
    uint32_t put(uint32_t input, uint8_t upper, uint8_t lower, uint8_t base) const
    {
        uint32_t result = 0;
        for(uint32_t i = lower; i<=upper; i++)
        {
            if (input & 1<<i)
            {
                result |= 1 << (base + i - lower);
            } 
        }
        return result;
    }
};

class r_type : public instruction
{
public:
    r_type(uint8_t funct7, uint8_t rs2, uint8_t rs1, uint8_t funct3, uint8_t rd, uint8_t opcode)
    {
        asBinary = 0;
        asBinary = put(funct7,6,0,25) | put(rs2,4,0,20) | put(rs1,4,0,15) | put(funct3,2,0,12) | put(rd,4,0,7) | put(opcode,6,0,0);
    }
};

class i_type : public instruction
{
public:
    i_type(uint16_t imm, uint8_t rs1, uint8_t funct3, uint8_t rd, uint8_t opcode)
    {
        asBinary = 0;
        asBinary = put(imm,11,0,20) | put(rs1,4,0,15) | put(funct3,2,0,12) | put(rd,4,0,7) | put(opcode,6,0,0);
    }
};

class s_type : public instruction
{
public:
    s_type(uint16_t imm, uint8_t rs2, uint8_t rs1, uint8_t funct3, uint8_t opcode)
    {
        asBinary = 0;
        asBinary = put(imm,11,5,25) | put(rs2,4,0,20) | put(rs1,4,0,15) | put(funct3,2,0,12) | put(imm,4,0,7) | put(opcode,6,0,0);
    }
};

class b_type : public instruction
{
public:
    b_type(uint16_t imm, uint8_t rs2, uint8_t rs1, uint8_t funct3, uint8_t opcode)
    {
        asBinary = 0;
        asBinary = put(imm,12,12,31) | put(imm,10,5,25) | put(rs2,4,0,20) | put(rs1,4,0,15) | put(funct3,2,0,12) | put(imm,4,1,8) | put(imm,11,11,7) | put(opcode,6,0,0);
    }
};

class u_type : public instruction
{
public:
    u_type(uint32_t imm, uint8_t rd, uint8_t opcode)
    {
        asBinary = 0;
        asBinary = put(imm,31,12,12) | put(rd,4,0,7) | put(opcode,6,0,0);
    }
};

class j_type : public instruction
{
public:
    j_type(uint32_t imm, uint8_t rd, uint8_t opcode)
    {
        asBinary = 0;
        asBinary = put(imm,20,20,31) | put(imm,10,1,21) | put(imm,11,11,20) | put(imm,19,12,12) | put(rd,4,0,7) | put(opcode, 6,0,0);
    }
};