#pragma once
#include <cstdint>
#include <iostream>
#include <bitset>
#include <stdint.h>
#include "wishbone.h"
#include "instruction.h"

using namespace std;

class memory
{
public:
    enum STATE {IDLE,WAIT,READ,WRITE};

    memory(wishbone& bus, uint32_t* new_program, uint32_t progsize) : m_bus(bus), m_program(new_program), m_progSize(progsize) { m_state = IDLE;}

    wishbone& m_bus;
    STATE m_state;
    uint32_t* m_program;
    uint32_t m_progSize;    //in words

    void eval()
    {
        if (!m_bus.clk) //falling clock
        {
            switch (m_state)
            {
            case IDLE:
                if (m_bus.cyc) m_state = WAIT;
                break;
            case WAIT:
                if (m_bus.cyc && m_bus.we) m_state = WRITE;
                else if (m_bus.cyc && !m_bus.we) m_state = READ;
                break;
            case WRITE:
            case READ:
                if (m_bus.cyc) m_state = WAIT;
                else m_state = IDLE;
                break;
            default:
                break;
            }
            switch (m_state)
            {
            case IDLE:
                m_bus.ack = 0;
                m_bus.datMiso = 0;
                break;
            case WAIT:
                m_bus.ack = 0;
                m_bus.datMiso = 0;
                break;
            case READ:
                m_bus.ack = 1;
                m_bus.datMiso = readmem(m_bus.adr);
                break;
            case WRITE:
                m_bus.ack = 1;
                m_bus.datMiso = 0;
                break;
            }
        }
        else    //rising clock
        {
            switch (m_state)
            {
            case READ:
                std::cout << std::hex << "read 0x" << m_bus.datMiso << " from 0x" << m_bus.adr*4 << " sel: 0x" << (uint32_t)m_bus.sel << "\n";
                break;
            case WRITE:
            {
                uint32_t current = readmem(m_bus.adr);
                if (m_bus.sel == 0b1000) writemem(m_bus.adr, (current & 0x00FFFFFF) | (m_bus.datMosi & 0xFF000000));       //address ending with 00
                else if (m_bus.sel == 0b0100) writemem(m_bus.adr, (current & 0xFF00FFFF) | (m_bus.datMosi & 0x00FF0000));  //address ending with 01
                else if (m_bus.sel == 0b0010) writemem(m_bus.adr, (current & 0xFFFF00FF) | (m_bus.datMosi & 0x0000FF00));  //address ending with 10
                else if (m_bus.sel == 0b0001) writemem(m_bus.adr, (current & 0xFFFFFF00) | (m_bus.datMosi & 0x000000FF));  //address ending with 11
                else if (m_bus.sel == 0b1100) writemem(m_bus.adr, (current & 0x0000FFFF) | (m_bus.datMosi & 0xFFFF0000));  //address ending with 00
                else if (m_bus.sel == 0b0011) writemem(m_bus.adr, (current & 0xFFFF0000) | (m_bus.datMosi & 0x0000FFFF));  //address ending with 10
                else if (m_bus.sel == 0b1111) writemem(m_bus.adr, m_bus.datMosi);                                          //address ending with 00
                std::cout << std::hex << "write 0x" << m_bus.datMosi << " to 0x" << m_bus.adr*4 << " sel: 0x" << (uint32_t)m_bus.sel << "\n"; 
                break;
            }
            default:
                break;
            }
        }
    }
    uint32_t readmem(uint32_t address)
    {
        if (address < m_progSize*4) return m_program[address];
        else return 0; 
    }
    void writemem(uint32_t address, uint32_t datum)
    {
        if (address < m_progSize*4)
        {
            m_program[address] = datum;
        }
        else return;
    }
    void dump()
    {
        std::cout << "\n**** Memory Dump ****\n";
        for (int i = 0; i < m_progSize; i++)
            std::cout << std::hex << "Address 0x" << i*4 << ": 0x" << readmem(i) << "\n";
    }

};