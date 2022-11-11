#include <common.h>
#include <proc.h>
#include "syscall.h"

int fs_open(const char *pathname, int flags, int mode);
size_t fs_read(int fd, void *buf, size_t len);
size_t fs_write(int fd, const void *buf, size_t len);
size_t fs_lseek(int fd, size_t offset, int whence);
int fs_close(int fd);
void naive_uload(PCB *pcb, const char *filename);
int timer_gettimeofday(void *tv, void *tz);

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;

  switch (a[0]) {
    case SYS_exit: naive_uload(0, "/bin/nterm"); break;
    case SYS_yield: yield(); break;
    case SYS_open: c->GPRx = fs_open((void *)a[1], a[2], a[3]); break;
    case SYS_read: c->GPRx = fs_read(a[1], (void *)a[2], a[3]); break;
    case SYS_write: c->GPRx = fs_write(a[1], (void *)a[2], a[3]); break;
    case SYS_close: c->GPRx = fs_close(a[1]); break;
    case SYS_lseek: c->GPRx = fs_lseek(a[1], a[2], a[3]); break;
    case SYS_brk: c->GPRx = 0; break;
    case SYS_execve: naive_uload(0, (void *)a[1]);
    case SYS_gettimeofday: c->GPRx = timer_gettimeofday((void *)a[1], (void *)a[2]); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
