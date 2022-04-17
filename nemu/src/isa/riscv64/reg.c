#include <isa.h>
#include "local-include/reg.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
  printf("reg\thex\t\t\tdec\n");
  printf("pc\t0x%-16lx\t%ld\n",cpu.pc,cpu.pc);
  for(int i=0; i<32; i++){
    printf("%s\t0x%-16lx\t%ld\n",regs[i],gpr(i),gpr(i));
  }
}

word_t isa_reg_str2val(const char *s, bool *success) {
  int i=0;
  if(strcmp(s,"pc")==0){
    *success = true;
    return cpu.pc;
  }
  for(i=0; i<ARRLEN(regs); i++){
    if(strcmp(s,regs[i])==0){break;}
  }
  if(i<32){
    *success = true;
    return gpr(i);
  }else{
    *success = false;
    return 0;
  }
}
