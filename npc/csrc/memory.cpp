/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-04-28 18:31
#
# Filename: memory.c
#
# Description: 
#
=========================================================*/
#include <common.h>
#include "verilated_dpi.h"

#define IMEM_DEPTH 1024

static char* image_file = NULL;
uint8_t *imem_ptr = NULL;
uint64_t *gpr_ptr = NULL;

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

extern "C" void set_mem_ptr(const svOpenArrayHandle r) {
  imem_ptr = (uint8_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

extern "C" void set_gpr_ptr(const svOpenArrayHandle r) {
  gpr_ptr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

void set_image_file(char* file){
  image_file = file;
}

long init_mem(){
  if (image_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    image_file = (char *)"dummy.bin";
  }
  FILE *fp = fopen(image_file, "rb");
  Assert(fp, "Can not open '%s'", image_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  Log("The image is %s, size = %ld", image_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(imem_ptr, size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

uint64_t mem_read(uint64_t addr){
  return *(uint64_t *)(imem_ptr + addr - RESET_VECTOR);
}

uint64_t gpr_read(int idx){
  return gpr_ptr[check_reg_idx(idx)];
}

void isa_reg_display() {
  printf("reg\thex\t\t\tdec\n");
  printf("pc\t0x%-16llx\t%lld\n", getPC(),getPC());
  assert(gpr_ptr);
  for(int i=0; i<32; i++){
    printf("%s\t0x%-16lx\t%ld\n",regs[i],gpr_read(i),gpr_read(i));
  }
}

word_t isa_reg_str2val(const char *s, bool *success) {
  int i=0;
  if(strcmp(s,"pc")==0){
    *success = true;
    return getPC();
  }
  for(i=0; i<ARRLEN(regs); i++){
    if(strcmp(s,regs[i])==0){break;}
  }
  if(i<32){
    *success = true;
    return gpr_read(i);
  }else{
    *success = false;
    return 0;
  }
}
