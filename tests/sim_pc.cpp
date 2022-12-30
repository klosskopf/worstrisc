// For std::unique_ptr
#include <memory>
#include <verilated.h>
#include "../obj_dir/Vtst_pc.h"

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

    const std::unique_ptr<Vtst_pc> pc{new Vtst_pc{contextp.get(), "PC"}};
    pc->clk_i = 0;

    //Ensure a good reset from start on
    pc->rst_i = 0;
    pc->eval();
    pc->rst_i = 1;
    pc->eval();
    assert(pc->pc_o == 0x12345678);
    while (!contextp->gotFinish() && contextp->time() < 10)
    {
        if (contextp->time() == 1) pc->rst_i = 0;
        if (contextp->time() == 3) {pc->pc_i = 0x87654321; pc->setPc_i=1;}
        if (contextp->time() == 5) {pc->pc_i = 0; pc->setPc_i=0;}
        if (contextp->time() == 6) {assert(pc->pc_o == 0x87654321);}

        pc->clk_i ^= 1;

        pc->eval();
        contextp->timeInc(1);  
    }

    pc->final();

    // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    contextp->coveragep()->write("logs/coverage.dat");
#endif
}
