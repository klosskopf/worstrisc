// For std::unique_ptr
#include <memory>
#include <verilated.h>
#include "../obj_dir/Vtst_registerfile.h"

double sc_time_stamp() { return 0; }

int main(int argc, char** argv, char** env)
{
    // Prevent unused variable warnings
    if (false && argc && argv && env) {}
    
    Verilated::mkdir("logs");
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    contextp->randReset(2);// Randomization reset policy
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    const std::unique_ptr<Vtst_registerfile> registerfile{new Vtst_registerfile{contextp.get(), "REGISTERFILE"}};
    registerfile->clk_i = 0;
    registerfile->selRd_i = 0;
    registerfile->selRs1_i = 0;
    registerfile->selRs2_i = 0;

    //Ensure a good reset from start on
    registerfile->rst_i = 0;
    registerfile->eval();
    registerfile->rst_i = 1;
    contextp->timeInc(1);
    registerfile->eval();
    registerfile->rst_i = 0;

    /*write i+1 to every register*/
    for (int i = 0; i<32; i++)
    {
        registerfile->clk_i = 1;
        registerfile->selRd_i = i;
        registerfile->rd_i = i+1;   //i+1 to check 0 in x0
        registerfile->eval();
        contextp->timeInc(1);
        registerfile->clk_i = 0;
        registerfile->eval();
        contextp->timeInc(1);
    }

    /*check 0 in x0 and 17 in x16*/
    registerfile->selRs1_i = 0;
    registerfile->selRs2_i = 16;
    registerfile->eval();
    contextp->timeInc(1);
    assert(registerfile->rs1_o == 0);
    assert(registerfile->rs2_o == 17);

    /*check all*/
    for (int i = 1; i<16; i++)
    {
        registerfile->selRs1_i = i;
        registerfile->selRs2_i = i+16;
        registerfile->eval();
        contextp->timeInc(1);
        assert(registerfile->rs1_o == i+1);
        assert(registerfile->rs2_o == i+17);
    }

    registerfile->final();

    // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    contextp->coveragep()->write("logs/coverage.dat");
#endif
}
