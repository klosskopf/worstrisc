#pragma once

#include <stdint.h>

class wishbone
{
public:
    wishbone(){rst = 1; clk =0; adr = 0; datMosi = 0; datMiso = 0; we = 0; sel = 0; stb = 0; ack = 0; cyc = 0;}
    bool rst;
    bool clk;
    uint32_t adr;
    uint32_t datMosi;
    uint32_t datMiso;
    bool we;
    uint8_t sel;
    bool stb;
    bool ack;
    bool cyc;
};