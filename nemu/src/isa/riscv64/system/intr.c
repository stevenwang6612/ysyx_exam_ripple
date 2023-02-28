#include <isa.h>
#include "../local-include/reg.h"

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  /* TODO: Trigger an interrupt/exception with ``NO''.
   * Then return the address of the interrupt/exception vector.
   */
  cpu.csr[CSR_MEPC] = epc;
  cpu.csr[CSR_MCAUSE] = NO;
  cpu.csr[0x300] = 0xa00001800;

  return cpu.csr[CSR_MTVEC];
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
