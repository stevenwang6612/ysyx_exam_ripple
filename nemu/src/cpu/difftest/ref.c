#include <isa.h>
#include <cpu/cpu.h>
#include <cpu/decode.h>
#include <difftest-def.h>
#include <memory/paddr.h>

void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (direction == DIFFTEST_TO_REF) {
    memcpy(guest_to_host(addr), buf, n);
  } else {
    memcpy(buf, guest_to_host(addr), n);
  }
}

void difftest_regcpy(void *dut, bool direction) {
  extern CPU_state cpu;
  CPU_state *diffdut = (CPU_state *)dut;
  if (direction == DIFFTEST_TO_REF) {
    for(int i=0; i<32; i++)
      cpu.gpr[i] = diffdut->gpr[i];
    cpu.pc = diffdut->pc;
  } else {
    for(int i=0; i<32; i++)
      diffdut->gpr[i] = cpu.gpr[i];
    diffdut->pc = cpu.pc;
  }
}

void difftest_exec(uint64_t n) {
  Decode s;
  extern CPU_state cpu;
  for (;n > 0; n --) {
    s.pc = cpu.pc;
    s.snpc = cpu.pc;
    isa_exec_once(&s);
    cpu.pc = s.dnpc;
  }
}
void difftest_raise_intr(word_t NO) {
  assert(0);
}

void difftest_init() {
  /* Perform ISA dependent initialization. */
  //init_isa();
  cpu.csr[300]=0xa00001800;
}
