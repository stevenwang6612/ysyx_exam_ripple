/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-04-22 20:38
#
# Filename: main.cpp
#
# Description: 
#
=========================================================*/
#include <common.h>

int main(int argc, char** argv, char** env) {
  init_Verilated();

  init_monitor(argc, argv);

  sdb_mainloop();

  statistic();

  exit_Verilated();

  return !get_trap_flag();
}

//verilator -Wall --cc --exe --build --trace sim_main.cpp our.v
//
