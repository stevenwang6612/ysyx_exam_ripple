#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <verilator.h>

typedef uint64_t word_t;
typedef uint64_t vaddr_t;
typedef struct {
  word_t gpr[32];
  vaddr_t pc;
} CPU_state;

#include <monitor.h>
#include <sdb.h>
#include <memory.h>
#include <device.h>
#include <debug.h>
#include <execute.h>


#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))
#define RESET_VECTOR 0x80000000
#define DEVICE_BASE 0xa0000000

#endif
