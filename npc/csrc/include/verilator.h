#ifndef __VERILATED_H__
#define __VERILATED_H__

#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"


extern Vtop* top;
extern VerilatedVcdC* tfp;
extern vluint64_t Vtime;


void init_Verilated();
void exit_Verilated();
void set_wave_file(char* file);
void init_wave();
bool dump_wave_enable();

#endif
