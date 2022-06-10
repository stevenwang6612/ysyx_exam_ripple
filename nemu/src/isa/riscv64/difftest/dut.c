#include <isa.h>
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  bool flag = true;
  if(ref_r->pc == cpu.pc){
    for(int i=0; i<32; i++){
      if(cpu.gpr[i] != ref_r->gpr[i]){
        flag = false;
        break;
      }
    }
  }else{
    flag = false;
  }
  if(!flag){
    printf("reg\tdut\t\t\tref\n");
    printf("pc\t0x%-16lx\t0x%-16lx\n",cpu.pc,ref_r->pc);
    for(int i=0; i<32; i++){
      printf("%s\t0x%-16lx\t0x%-16lx\n",reg_name(i),gpr(i),ref_r->gpr[i]);
    }
  }
  return flag;
}

void isa_difftest_attach() {
}
