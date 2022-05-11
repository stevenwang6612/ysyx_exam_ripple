#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = inw(VGACTL_ADDR+2), .height = inw(VGACTL_ADDR),
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  uint32_t *dst = (uint32_t *)(uintptr_t)FB_ADDR;
  uint32_t *src = (uint32_t *)ctl->pixels;
  int swidth = inw(VGACTL_ADDR+2);
  int sheight = inw(VGACTL_ADDR);
  if(ctl->x < swidth && ctl->y < sheight){
    dst += ctl->x + ctl->y*swidth;
    int dwidth = ctl->w;
    if(ctl->x + ctl->w > swidth)
      dwidth = swidth - ctl->x;
    int dheight = ctl->h;
    if(ctl->y + ctl->h > sheight)
      dheight = sheight - ctl->y;
    for(int i=0; i<dheight; i++)
      for(int j=0; j<dwidth; j++)
        dst[j+swidth*i] = src[j+i*ctl->w];
  }
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
