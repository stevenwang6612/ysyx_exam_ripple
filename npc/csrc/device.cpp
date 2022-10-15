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

uint64_t read_rtc(long long addr){
  return *(uint64_t*)(rtc + (addr<32&addr>=0?addr:32));
}
