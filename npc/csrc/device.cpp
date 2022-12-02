/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-09-08 16:01
#
# Filename: device.cpp
#
# Description: 
#
=========================================================*/

#include <common.h>
#include <time.h>
#include <sys/time.h>

static char rtc[40];
static uint64_t boot_time = 0;
extern bool difftest_skip;
extern bool difftest_skiped;

static uint64_t get_time_internal() {
  struct timeval now;
  gettimeofday(&now, NULL);
  uint64_t us = now.tv_sec * 1000000 + now.tv_usec;
  return us;
}

uint64_t get_runtime() {
  if (boot_time == 0) boot_time = get_time_internal();
  uint64_t now = get_time_internal();
  return now - boot_time;
}
void update_rtc(){
  *(uint64_t*)rtc = get_runtime();
  time_t now;
  struct tm *tm_now;
  time(&now);
  tm_now = localtime(&now);
  *(int*)(rtc+8)  = tm_now->tm_sec;
  *(int*)(rtc+12) = tm_now->tm_min;
  *(int*)(rtc+16) = tm_now->tm_hour;
  *(int*)(rtc+20) = tm_now->tm_mday;
  *(int*)(rtc+24) = 1 + tm_now->tm_mon;
  *(int*)(rtc+28) = 1900 + tm_now->tm_year;
}

uint64_t read_rtc(int addr){
  return *(uint64_t*)(rtc + (addr<32&addr>=0?addr:32));
}

void init_device(){
  if (boot_time == 0) boot_time = get_time_internal();
}

bool mmio_read(unsigned int raddr, long unsigned int *rdata){
  ;
}
bool mmio_write(unsigned int waddr, long unsigned int wdata, int wlen){
  ;
}

// bool pmem_read(long long raddr, long long *rdata){
//   if(raddr >= RESET_VECTOR && raddr < RESET_VECTOR + IMEM_DEPTH){
//     *rdata = *(uint64_t *)(imem_ptr + raddr - RESET_VECTOR);
//   }else if(raddr >= DEVICE_BASE + 0x48 && raddr < DEVICE_BASE + 0x68){
//     update_rtc();
//     *rdata = read_rtc(raddr - DEVICE_BASE - 0x48);
//     difftest_skip = true;
//   }else if(raddr>=0x2000000 && raddr<0x200BFFF){
//     difftest_skip = true;
//   }else{
//     *rdata = 0;
//     //difftest_skip = true;
//     //printf("0x%llx\n", raddr);
//   }
// }
// extern "C" void pmem_write(long long waddr, long long wdata, char wmask) {
//   if(waddr >= RESET_VECTOR && waddr < RESET_VECTOR + IMEM_DEPTH){
//     uint8_t *wdata_byte = (uint8_t *)(&wdata);
//     for(int i=0; i<8; i++)
//       if(wmask>>i & 1)
//         imem_ptr[waddr - RESET_VECTOR + i] = *(wdata_byte + i);
//   }else if(waddr == DEVICE_BASE + 0x3f8 && wmask & 1){//uart
//     putchar((char)wdata);
//     difftest_skip = true;
//     //printf("0x%llx\n", waddr);
//   }else if(waddr==0){
//     difftest_skiped = true;//for difftest of interrupt
//   }else{
//     difftest_skip = true;
//     //printf("0x%llx\n", waddr);
//   }
// }