#include <am.h>
#include <sys/time.h>

#define LENGTH(arr)         (sizeof(arr) / sizeof((arr)[0]))

static void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime){
  struct timeval now;
  gettimeofday(&now, NULL);
  uptime->us = now.tv_sec * 1000000 + now.tv_usec;
}
static void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd){
  kbd->keydown = 0;
  kbd->keycode = AM_KEY_NONE;
}

static void __am_timer_rtc(AM_TIMER_RTC_T *t){}

static void __am_timer_config(AM_TIMER_CONFIG_T *cfg) { cfg->present = true; cfg->has_rtc = true; }
static void __am_input_config(AM_INPUT_CONFIG_T *cfg) { cfg->present = true;  }
static void fail(void *buf) { printf("[AM] access nonexist register\n"); }

typedef void (*handler_t)(void *buf);
static void *lut[128] = {
  [AM_TIMER_CONFIG] = __am_timer_config,
  [AM_TIMER_RTC   ] = __am_timer_rtc,
  [AM_TIMER_UPTIME] = __am_timer_uptime,
  [AM_INPUT_CONFIG] = __am_input_config,
  [AM_INPUT_KEYBRD] = __am_input_keybrd,
};

bool ioe_init() {
  for (int i = 0; i < LENGTH(lut); i++)
    if (!lut[i]) lut[i] = fail;
  return true;
}
void ioe_read (int reg, void *buf) { ((handler_t)lut[reg])(buf); }
void ioe_write(int reg, void *buf) { ((handler_t)lut[reg])(buf); }

