#include <common.h>
#include <sys/time.h>

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  yield();
  int i = 0;
  for(i=0; i<len; i++)
    putch(*(char *)(buf++));
  return i;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  yield();
  if(io_read(AM_INPUT_CONFIG).present == false) return -1;
  AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
  static char key_buf[16];
  static int ptr = 0;
  size_t ret = 0;
  if(ptr){
    while(ret<len){
      *(char *)(buf++) = key_buf[ptr++];
      ret++;
      if(key_buf[ptr]=='\0'){
        ptr = 0;
        break;
      }
    }
  }
  while(ev.keycode != AM_KEY_NONE){
    sprintf(key_buf, "k%c %s\n", ev.keydown ? 'd' : 'u', keyname[ev.keycode]);
    while(ret<len){
      *(char *)(buf++) = key_buf[ptr++];
      ret++;
      if(key_buf[ptr]=='\0'){
        ptr = 0;
        break;
      }
    }
    ev = io_read(AM_INPUT_KEYBRD);
  }
  return ret;
}

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  int w = io_read(AM_GPU_CONFIG).width;
  int h = io_read(AM_GPU_CONFIG).height;
  snprintf(buf, len, "WIDTH : %d\nHEIGHT: %d\n", w, h);
  return strlen(buf);
}

size_t fb_write(const void *buf, size_t offset, size_t len) {
  yield();
  io_write(AM_GPU_MEMCPY, offset, (void *)buf, len);
  return len;
}

int timer_gettimeofday(struct timeval *tv, struct timezone *tz){
  if(tv==NULL) return -1;
  AM_TIMER_UPTIME_T uptime;
  uptime = io_read(AM_TIMER_UPTIME);
  tv->tv_sec = uptime.us / 1000000;
  tv->tv_usec = uptime.us % 1000000;
  return 0;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
