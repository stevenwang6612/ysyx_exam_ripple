#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <verilator.h>

typedef uint64_t word_t;
typedef uint64_t vaddr_t;

#include <monitor.h>
#include <sdb.h>
#include <memory.h>
#include <debug.h>
#include <execute.h>


#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))
#define RESET_VECTOR 0x80000000

#endif
