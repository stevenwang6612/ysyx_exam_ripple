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
#include <sys/time.h>

void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
static bool trap_flag = true;
bool get_trap_flag() {return trap_flag;}
static uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static char log_buf[128];
uint64_t get_time() {
  struct timeval now;
  gettimeofday(&now, NULL);
  uint64_t us = now.tv_sec * 1000000 + now.tv_usec;
  return us;
}
void statistic() {
  Log("host time spent = %ld us", g_timer);
  Log("total guest instructions = %ld", g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = %ld inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}
void disasm(){
  char buf[32];
  uint64_t pc = getPC();
  uint32_t instruction = getINST();
  disassemble(buf, sizeof(buf), pc, (uint8_t *)&instruction, 4);
  sprintf(log_buf, "0x%016lx: 0x%08x %s", pc, instruction, buf);
  log_write("%s\n", log_buf);
}

static void exec_once() {
  top->clk = 1;
  top->eval();
  Vtime++;
  if(dump_wave_enable())
    tfp->dump(Vtime);
  top->clk = 0;
  top->eval();
  Vtime++;
  if(dump_wave_enable())
    tfp->dump(Vtime);
}

void execute(uint64_t n) {
  for(; n>0; n--){
    disasm();
    uint64_t timer_start = get_time();
    exec_once();
    uint64_t timer_end = get_time();
    g_nr_guest_inst++;
    g_timer += timer_end - timer_start;
    if(getINST()==0x00100073){
      trap_flag = gpr_read(10) == 0;
      Log("%s", trap_flag ? ASNI_FMT("HIT GOOD TRAP", ASNI_FG_GREEN) : ASNI_FMT("HIT BAD TRAP", ASNI_FG_RED));
      break;
    }
    if(!difftest_step()){
      printf("%s\n", log_buf);
      Log("%s", ASNI_FMT("ABORT: difftest error!", ASNI_FG_RED));
      trap_flag = false;
      break;
    }
  }
}


