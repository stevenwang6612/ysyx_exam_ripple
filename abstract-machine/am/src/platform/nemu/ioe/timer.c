#include <am.h>
#include <nemu.h>
#include <time.h>

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = inl(RTC_ADDR+4)+inl(RTC_ADDR);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
  //  time_t now;
  //  struct tm *tm_now;
  //  time(&now);
  //  tm_now = localtime(&now);
  //  rtc->second = tm_now->tm_sec;
  //  rtc->minute = tm_now->tm_min;
  //  rtc->hour   = tm_now->tm_hour;
  //  rtc->day    = tm_now->tm_mday;
  //  rtc->month  = 1 + tm_now->tm_mon;
  //  rtc->year   = 1900 + tm_now->tm_year;
}
