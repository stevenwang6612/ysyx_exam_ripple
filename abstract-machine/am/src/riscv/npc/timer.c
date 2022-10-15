#include <am.h>
#include "npc.h"

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = inL(RTC_ADDR);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = inl(RTC_ADDR+8);
  rtc->minute = inl(RTC_ADDR+12);
  rtc->hour   = inl(RTC_ADDR+16);
  rtc->day    = inl(RTC_ADDR+20);
  rtc->month  = inl(RTC_ADDR+24);
  rtc->year   = inl(RTC_ADDR+28);
}
