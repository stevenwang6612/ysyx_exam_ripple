#include <NDL.h>
#include <SDL.h>
#include <string.h>
#include <stdio.h>

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};
// 计算所有按键的数量
static int kb_len = sizeof(keyname) / sizeof(keyname[0]);

// 记录所有按键的状态
static uint8_t key_state[sizeof(keyname) / sizeof(keyname[0])] = {0};

int SDL_PushEvent(SDL_Event *ev) {
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
  char buf[64];
  if (NDL_PollEvent(buf, 64)) {
    int pos = 0;
    if(buf[pos] != 'k') return 0;
    if(buf[pos + 1] != 'd' && buf[pos + 1] != 'u') return 0;

    // 判断是按键按下还是抬起
    ev->key.type = (buf[pos + 1] == 'd') ? SDL_KEYDOWN : SDL_KEYUP;
    ev->type = ev->key.type;

    // 逐个对比，找到对应的键值，赋给ev->key.keysym.sym
    // 并更新key_state中对应的状态
    char *namebuf = strtok(buf+3, "\n");
    ev->key.keysym.sym = 0;
    for (int i = 0; i < kb_len; ++i) {
      if (strcmp(namebuf, keyname[i]) == 0) {
        ev->key.keysym.sym = i;
        switch (ev->key.type) {
          case SDL_KEYDOWN:
            key_state[i] = 1;
            break;
          case SDL_KEYUP:
            key_state[i] = 0;
            break;
          default:
            break;
        }
        break;
      }
    }
    return 1;
  }
  return 0;
}

int SDL_WaitEvent(SDL_Event *event) {
  while (SDL_PollEvent(event) == 0);
  return 1;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  if (numkeys != NULL)
    *numkeys = sizeof(key_state) / sizeof(uint8_t);
  return key_state;
}
