// For std::unique_ptr
#include <memory>
#include <verilated.h>
#include "../obj_dir/Vtst_riscvWb.h"
#include "wishbone.h"
#include "memory.h"
//#include "firmware.h"

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

    //Instantiate the rsicv-cpu
    const std::unique_ptr<Vtst_riscvWb> riscvWb{new Vtst_riscvWb{contextp.get(), "RISCV"}};

    //Instantiate the wishbone bus
    wishbone bus;

    #define PROGSIZE 16 //in multiples of 4 byte (16 => 64byte)
    uint32_t program[PROGSIZE] = {
        LUI(0x87654321,1),
        ADDI(1,0x87654321,1),
        SW(0x30,0,1),

        LBU(0x33,0,2),
        SW(0x34,0,2)
    };

    //Instantiate the memory
    memory speicher(bus,program,PROGSIZE);

    //Ensure a good reset from start on
    riscvWb->rst_i = 0;
    riscvWb->eval();
    riscvWb->rst_i = 1;
    riscvWb->eval();
    while (!contextp->gotFinish() && contextp->time() < 1000)
    {
        //change reset and clk
        if (contextp->time() == 1) bus.rst = 0;
        bus.clk ^= 1;

        //evaluate the peripherals
        speicher.eval();

        //read the wishbone changes from the riscv
        riscvWb->rst_i = bus.rst;
        riscvWb->clk_i = bus.clk;
        riscvWb->dat_i = bus.datMiso;
        riscvWb->ack_i = bus.ack;

        //evaluate the nect step
        riscvWb->eval();

        //write the wishbone bus
        bus.datMosi = riscvWb->dat_o;
        bus.we = riscvWb->we_o;
        bus.sel = riscvWb->sel_o;
        bus.stb = riscvWb->stb_o;
        bus.adr = riscvWb->adr_o;
        bus.cyc = riscvWb->cyc_o;
        contextp->timeInc(1);  
    }

    speicher.dump();


    riscvWb->final();

    // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    contextp->coveragep()->write("logs/coverage.dat");
#endif
}
