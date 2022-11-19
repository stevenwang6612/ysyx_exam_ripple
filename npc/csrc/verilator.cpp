/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-04-28 14:30
#
# Filename: verilated.cpp
#
# Description: 
#
=========================================================*/
#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include <debug.h>

Vtop* top;
VerilatedVcdC* tfp;
vluint64_t Vtime = 0;
static bool dump_wave_flag = false;
static char *wave_file = NULL;

void init_Verilated(){
  top = new Vtop;
  svSetScope(svGetScopeFromName("TOP.top"));
  top->clock = 0;
  top->reset = 1;
  top->eval();
}


void exit_Verilated(){
  top->final();
  if(dump_wave_flag){
    tfp->close();
  }
}


void init_wave(){
  if(dump_wave_flag){
    tfp = new VerilatedVcdC;
    top->trace(tfp, 0);
    Verilated::traceEverOn(true);
    if(!wave_file) wave_file = (char *)"./build/wave.vcd";
    tfp->open(wave_file);
    tfp->dump(Vtime);
    Log("dump wave: %s", ASNI_FMT("ON", ASNI_FG_GREEN));
    Log("The wave file is %s", wave_file);
  }else{
    Log("dump wave: %s", ASNI_FMT("OFF", ASNI_FG_RED));
  }
}


bool dump_wave_enable(){
  return dump_wave_flag;
}

void set_wave_file(char* file){
  dump_wave_flag = true;
  wave_file = file;
}
