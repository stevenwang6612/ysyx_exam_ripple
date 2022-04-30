/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-04-29 14:34
#
# Filename: execute.cpp
#
# Description: 
#
=========================================================*/
#include <common.h>


static void exec_once() {
    top->clk = 0;
    top->eval();
    Vtime++;
    if(dump_wave_enable())
      tfp->dump(Vtime);
    top->clk = 1;
    top->eval();
    Vtime++;
    if(dump_wave_enable())
      tfp->dump(Vtime);
    if(getINST()==0x00100073){
      printf("ebreak\n");
      return;
    }
}
  
void execute(uint64_t n) {
  for(; n>0; n--){
    exec_once();
  }
}

