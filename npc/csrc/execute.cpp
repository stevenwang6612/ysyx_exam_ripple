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
#include "axi4_mem.hpp"
#include "axi4.hpp"

void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
static bool trap_flag = true;
bool get_trap_flag() {return trap_flag;}
static uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static char log_buf[128];

axi4<32,64,4> mem_sigs;
axi4_ref<32,64,4> mem_sigs_ref(mem_sigs);
extern axi4_mem<32,64,4> mem;
extern axi4_ref<32,64,4>* mem_ref;

#define MAX_IRINGBUF 16
static uint64_t iringbuf[MAX_IRINGBUF];
static int iringbuf_ptr = 0;
void display_iringbuf(){
  int read_ptr = (iringbuf_ptr+1) % MAX_IRINGBUF;
  uint64_t pc = 0;
  char buf[128];
  for(; read_ptr!=iringbuf_ptr; read_ptr=(read_ptr+1)%MAX_IRINGBUF){
    char *p = buf;
    pc = iringbuf[read_ptr];
    p += snprintf(p, sizeof(buf),  "0x%016lx:", pc);
    uint32_t inst = pc<0x80000000?0:(uint32_t)mem_read(pc);
    p += sprintf(p, "  %08x", inst);
    int ilen_max = 4;
    int space_len = ilen_max - 4;
    if (space_len < 0) space_len = 0;
    space_len = space_len * 3 + 1;
    memset(p, ' ', space_len);
    p += space_len;

    disassemble(p, buf + sizeof(buf) - p,
        pc, (uint8_t *)&inst, 4);
    printf("%s\n", buf);
  }
}

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
  iringbuf[iringbuf_ptr] = pc;
  iringbuf_ptr = (iringbuf_ptr + 1) % MAX_IRINGBUF;
  uint32_t instruction = getINST();
  disassemble(buf, sizeof(buf), pc, (uint8_t *)&instruction, 4);
  sprintf(log_buf, "0x%016lx: 0x%08x %s", pc, instruction, buf);
  log_write("%s\n", log_buf);
}

static void exec_once() {
  do{
    top->clock = 1;
    mem_sigs.update_input(*mem_ref);
    top->eval();
    mem.beat(mem_sigs_ref);
    mem_sigs.update_output(*mem_ref);
    Vtime++;
    if(dump_wave_enable())
      tfp->dump(Vtime);
    top->clock = 0;
    top->eval();
    Vtime++;
    if(dump_wave_enable())
      tfp->dump(Vtime);
  }while(!top->exec_once);
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
      if(!trap_flag) display_iringbuf();
      break;
    }
    if(!difftest_step()){
      printf("%s\n", log_buf);
      Log("%s", ASNI_FMT("ABORT: difftest error!", ASNI_FG_RED));
      display_iringbuf();
      trap_flag = false;
      break;
    }
    if(scan_wp()){
      break;
    }
  }
}


