/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified:	2022-09-08 16:01
#
# Filename:		memory.cpp
#
# Description: 
#
=========================================================*/
#include <common.h>
#include "verilated_dpi.h"

#define IMEM_DEPTH 0x10000000

static char* image_file = NULL;
uint8_t imem_ptr[IMEM_DEPTH];
uint64_t *gpr_ptr = NULL;
extern bool difftest_skip;
extern bool difftest_skiped;

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

extern "C" void pmem_read(long long raddr, long long *rdata){
  if(raddr >= RESET_VECTOR && raddr < RESET_VECTOR + IMEM_DEPTH){
    *rdata = *(uint64_t *)(imem_ptr + raddr - RESET_VECTOR);
  }else if(raddr >= DEVICE_BASE + 0x48 && raddr < DEVICE_BASE + 0x68){
    update_rtc();
    *rdata = read_rtc(raddr - DEVICE_BASE - 0x48);
    difftest_skip = true;
  }else if(raddr>=0x2000000 && raddr<0x200BFFF){
    difftest_skip = true;
  }else{
    *rdata = 0;
    //difftest_skip = true;
    //printf("0x%llx\n", raddr);
  }
}
extern "C" void pmem_write(long long waddr, long long wdata, char wmask) {
  if(waddr >= RESET_VECTOR && waddr < RESET_VECTOR + IMEM_DEPTH){
    uint8_t *wdata_byte = (uint8_t *)(&wdata);
    for(int i=0; i<8; i++)
      if(wmask>>i & 1)
        imem_ptr[waddr - RESET_VECTOR + i] = *(wdata_byte + i);
  }else if(waddr == DEVICE_BASE + 0x3f8 && wmask & 1){//uart
    putchar((char)wdata);
    difftest_skip = true;
    //printf("0x%llx\n", waddr);
  }else if(waddr==0){
    difftest_skiped = true;//for difftest of interrupt
  }else{
    difftest_skip = true;
    //printf("0x%llx\n", waddr);
  }
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
