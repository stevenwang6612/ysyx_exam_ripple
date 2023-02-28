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
#include <SDL2/SDL.h>
extern bool difftest_skip;
extern bool difftest_skiped;

//----------------------screen-----------------------
#define CONFIG_VGA_SIZE_400x300 1
#define SCREEN_W (MUXDEF(CONFIG_VGA_SIZE_400x300, 400, 800))
#define SCREEN_H (MUXDEF(CONFIG_VGA_SIZE_400x300, 300, 600))

static uint32_t screen_size() {
  return SCREEN_W * SCREEN_H * sizeof(uint32_t);
}

static void *vmem = NULL;
static uint32_t vga_sync = 0;


static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;
static SDL_Window *window = NULL;

static void init_screen() {
  char title[128];
  sprintf(title, "RISCV64-RIPPLE001");
  SDL_Init(SDL_INIT_VIDEO);
  SDL_CreateWindowAndRenderer(
      SCREEN_W * (MUXDEF(CONFIG_VGA_SIZE_400x300, 1, 2)),
      SCREEN_H * (MUXDEF(CONFIG_VGA_SIZE_400x300, 1, 2)),
      0, &window, &renderer);
  SDL_SetWindowTitle(window, title);
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
      SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
}

static inline void update_screen() {
  SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}

void vga_update_screen() {
  if(vga_sync){
    update_screen();
    vga_sync=0;
  }
  //call `update_screen()` when the sync register is non-zero,
  //then zero out the sync register
}
//---------------------KEYBOARD----------------------
#define KEYDOWN_MASK 0x8000
// Note that this is not the standard
#define _KEYS(f) \
  f(ESCAPE) f(F1) f(F2) f(F3) f(F4) f(F5) f(F6) f(F7) f(F8) f(F9) f(F10) f(F11) f(F12) \
f(GRAVE) f(1) f(2) f(3) f(4) f(5) f(6) f(7) f(8) f(9) f(0) f(MINUS) f(EQUALS) f(BACKSPACE) \
f(TAB) f(Q) f(W) f(E) f(R) f(T) f(Y) f(U) f(I) f(O) f(P) f(LEFTBRACKET) f(RIGHTBRACKET) f(BACKSLASH) \
f(CAPSLOCK) f(A) f(S) f(D) f(F) f(G) f(H) f(J) f(K) f(L) f(SEMICOLON) f(APOSTROPHE) f(RETURN) \
f(LSHIFT) f(Z) f(X) f(C) f(V) f(B) f(N) f(M) f(COMMA) f(PERIOD) f(SLASH) f(RSHIFT) \
f(LCTRL) f(APPLICATION) f(LALT) f(SPACE) f(RALT) f(RCTRL) \
f(UP) f(DOWN) f(LEFT) f(RIGHT) f(INSERT) f(DELETE) f(HOME) f(END) f(PAGEUP) f(PAGEDOWN)

#define _KEY_NAME(k) _KEY_##k,

enum {
  _KEY_NONE = 0,
  MAP(_KEYS, _KEY_NAME)
};

#define SDL_KEYMAP(k) keymap[concat(SDL_SCANCODE_, k)] = concat(_KEY_, k);
static uint32_t keymap[256] = {};

static void init_keymap() {
  MAP(_KEYS, SDL_KEYMAP)
}

#define KEY_QUEUE_LEN 1024
static int key_queue[KEY_QUEUE_LEN] = {};
static int key_f = 0, key_r = 0;

static void key_enqueue(uint32_t am_scancode) {
  key_queue[key_r] = am_scancode;
  key_r = (key_r + 1) % KEY_QUEUE_LEN;
  Assert(key_r != key_f, "key queue overflow!");
}

static uint32_t key_dequeue() {
  uint32_t key = _KEY_NONE;
  if (key_f != key_r) {
    key = key_queue[key_f];
    key_f = (key_f + 1) % KEY_QUEUE_LEN;
  }
  return key;
}

void send_key(uint8_t scancode, bool is_keydown) {
  if (keymap[scancode] != _KEY_NONE) {
    uint32_t am_scancode = keymap[scancode] | (is_keydown ? KEYDOWN_MASK : 0);
    key_enqueue(am_scancode);
  }
}
//--------------------RTC-------------------------

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

uint64_t read_rtc(int addr){
  return *(uint64_t*)(rtc + (addr<32&addr>=0?addr:32));
}

//-------------------------------------------------------------
#define TIMER_HZ 50
bool device_update() {
  static uint64_t last = 0;
  uint64_t now = get_time_internal();
  if (now - last < 1000000 / TIMER_HZ) {
    return false;
  }
  last = now;

  vga_update_screen();

  SDL_Event event;
  while (SDL_PollEvent(&event)) {
    switch (event.type) {
      case SDL_QUIT:
        return true;
        break;
      // If a key was pressed
      case SDL_KEYDOWN:
      case SDL_KEYUP: {
        uint8_t k = event.key.keysym.scancode;
        bool is_keydown = (event.key.type == SDL_KEYDOWN);
        send_key(k, is_keydown);
        break;
      }
      default: break;
    }
  }
  return false;
}

void sdl_clear_event_queue() {
  SDL_Event event;
  while (SDL_PollEvent(&event));
}
void init_device(){
  if (boot_time == 0) boot_time = get_time_internal();
  init_keymap();
  vmem = malloc(screen_size());
  memset(vmem, 0, screen_size());
  init_screen();
}

void destroy_device(){
  free(vmem);
}

//------------------------MMIO-------------------------------

bool mmio_read(unsigned int raddr, long unsigned int *rdata){
  difftest_skip = true;
  if(raddr == KBD_ADDR ){
    *rdata = key_dequeue();
  }else if(raddr >= RTC_ADDR && raddr < RTC_ADDR + 0x20){
    update_rtc();
    *rdata = read_rtc((raddr - RTC_ADDR)&~0x7);
  }else if(raddr == VGACTL_ADDR | raddr == VGACTL_ADDR+2){
    *rdata = SCREEN_H + (SCREEN_W<<16);
  }else{
    *rdata = 0;
  }
}
bool mmio_write(unsigned int waddr, long unsigned int wdata, int wlen){
  difftest_skip = true;
  if(waddr>=FB_ADDR && waddr<FB_ADDR+screen_size() && wlen<=8){
    memcpy((char *)vmem+waddr-FB_ADDR, ((char *)(&wdata))+(waddr&0x7), wlen);
  }else if(waddr==SERIAL_PORT && wlen==1){//uart
    putchar((char)wdata);
  }else if(waddr==VGACTL_ADDR+4 && wlen==4){
    vga_sync = (uint32_t)(wdata>>32);
  }else{
    //printf("0x%x\t%d\n", waddr, wlen);
  }
}
