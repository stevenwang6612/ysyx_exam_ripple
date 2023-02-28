#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if(user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      case 0xb: ev.event = c->GPR1==-1?EVENT_YIELD:EVENT_SYSCALL;
                c->mepc += 4;
                break;
      case 0xc: ev.event = EVENT_PAGEFAULT; break;
      case 0x8000000000000003: ev.event = EVENT_SYSCALL; break;
      case 0x8000000000000007: ev.event = EVENT_IRQ_TIMER; break;
      case 0x800000000000000b: ev.event = EVENT_IRQ_IODEV; break;
      default: ev.event = EVENT_ERROR; break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  Context *cp = kstack.end - (sizeof(Context));
  cp->mepc = (uintptr_t)entry;
  cp->GPR2 = (uintptr_t)arg;
  return cp;
}

void yield() {
  asm volatile("li a7, -1; ecall");
}

bool ienabled() {
  int mstatus = 0;
  asm volatile("csrr %0, mstatus" : "=r"(mstatus));
  return mstatus|0x8;
}

void iset(bool enable) {
  if(enable){
    asm volatile("csrs  mstatus, 0x8");
  }else{
    asm volatile("csrc  mstatus, 0x8");
  }
}
