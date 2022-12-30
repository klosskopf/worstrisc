// For std::unique_ptr
#include <memory>
#include <verilated.h>
#include <iostream>
#include <bitset>
#include "../obj_dir/Vtst_alu.h"

double sc_time_stamp() { return 0; }

const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

/**
 * @brief Check a alu opertion
 * 
 * @param alu   The ALU that should be checked
 * @param arg1  The Argument #1
 * @param arg2  The Argument #2
 * @param funct The Opertion that should be checked
 * @param subSr The subtrackt / Shift right signal
 * @param result The result to be checked against
 */
void op(const std::unique_ptr<Vtst_alu>& alu, uint32_t arg1, uint32_t arg2, uint8_t funct, bool subSr, uint32_t result)
{
    bool done = false;
    uint32_t aluResult;
    do
    {
        alu->clk_i = 0;
        alu->aluArg1_i = arg1;
        alu->aluArg2_i = arg2;
        alu->funct3_i = funct;
        alu->subSr_i = subSr;
        alu->eval();
        contextp->timeInc(1);
        done = alu->done_o;
        aluResult = alu->aluRes_o;
        alu->clk_i = 1;
        alu->eval();
        contextp->timeInc(1);
    } while (!done && (contextp->time() < 1000));
    
    std::cout << "Expected:" << std::bitset<32>(result) << "; Actual:" <<  std::bitset<32>(aluResult) << "\n";
    assert(aluResult == result);
}

int main(int argc, char** argv, char** env)
{
    Verilated::mkdir("logs");
    contextp->randReset(2);// Randomization reset policy
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);
    const std::unique_ptr<Vtst_alu> alu{new Vtst_alu{contextp.get(), "ALU"}};

    //reset
    alu->clk_i = 0;
    alu->rst_i = 0;
    alu->eval();
    alu->rst_i = 1;
    alu->eval();
    contextp->timeInc(1);

    alu->rst_i = 0;
    alu->eval();
    contextp->timeInc(1);

    op(alu, 1374, 1375, 0, 0, 2749);
    op(alu, 1374, 1375, 0, 1, -1);
    op(alu, -1, 34, 1, 0, -4);
    op(alu, -1, 1, 2, 0, 1);
    op(alu, -1, 1, 3, 0, 0);
    op(alu, 5, 3, 4, 0, 6);
    op(alu, -1, 1, 5, 1, -1);
    op(alu, -1, 1025, 5, 1, -1);
    op(alu, -1, 1, 5, 0, 0x7FFFFFFF);
    op(alu, 5, 3, 6, 0, 7);
    op(alu, 5, 3, 7, 0, 1);

    alu->final();

    // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    contextp->coveragep()->write("logs/coverage.dat");
#endif
}
