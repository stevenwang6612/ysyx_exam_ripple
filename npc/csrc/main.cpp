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
  Verilated::commandArgs(argc, argv);
  init_Verilated();

  init_monitor(0, argv);

  sdb_mainloop();

  exit_Verilated();
  return 0;
}

//verilator -Wall --cc --exe --build --trace sim_main.cpp our.v
//
