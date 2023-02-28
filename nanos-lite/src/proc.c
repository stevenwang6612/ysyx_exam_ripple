#include <proc.h>

#define MAX_NR_PROC 4


void naive_uload(PCB *pcb, const char *filename);

void context_kload(PCB *pcb, void (*entry)(void *), void *arg);
void context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]);

static PCB pcb[MAX_NR_PROC] __attribute__((used)) = {};
static PCB pcb_boot = {};
PCB *current = NULL;

void switch_boot_pcb() {
  current = &pcb_boot;
}

void hello_fun(void *arg) {
  int j = 1;
  while (1) {
    Log("Hello World from Nanos-lite with arg '%p' for the %dth time!", (uintptr_t)arg, j);
    j ++;
    yield();
  }
}

void init_proc() {
  char *argv[2] = {"20", NULL};
  //context_kload(&pcb[0], hello_fun, (void *) 0);
  context_uload(&pcb[0], "/bin/pal", argv, NULL);
  switch_boot_pcb();

  Log("Initializing processes...");

  // load program here
  //naive_uload(NULL, "/bin/hello");

}

void context_kload(PCB *pcb, void (*entry)(void *), void *arg){
  Area kstack = {pcb->stack, pcb->stack + sizeof(pcb->stack)};
  pcb->cp = kcontext(kstack, entry, arg);
}

Context* schedule(Context *prev) {
  // save the context pointer
  current->cp = prev;

  current = (current == &pcb[0] ? &pcb[0] : &pcb[0]);
  // then return the new context
  return current->cp;
}
