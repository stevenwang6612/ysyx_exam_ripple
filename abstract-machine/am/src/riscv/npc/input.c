#include <am.h>
#include "npc.h"
#define KEYDOWN_MASK 0x8000

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
   uint32_t kbd_code = inw(KBD_ADDR);
   kbd->keydown = (kbd_code & KEYDOWN_MASK ? true : false);
   kbd->keycode = kbd_code & ~KEYDOWN_MASK;
}
