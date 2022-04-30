#ifndef __MEMORY_H__
#define __MEMORY_H__

#include <common.h>

void set_image_file(char* file);
long init_mem();
uint64_t mem_read(uint64_t addr);
void isa_reg_display();
word_t isa_reg_str2val(const char *s, bool *success);

static inline int check_reg_idx(int idx) {
  assert(idx >= 0 && idx < 32);
  return idx;
}

uint64_t gpr_read(int idx);

static inline const char* reg_name(int idx) {
  extern const char* regs[];
  return regs[check_reg_idx(idx)];
}


#endif
