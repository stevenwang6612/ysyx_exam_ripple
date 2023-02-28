#ifndef __DEVICE_H__
#define __DEVICE_H__

#include <common.h>


#define DEVICE_BASE 0xa0000000

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR        (DEVICE_BASE + 0x00000a0)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define AUDIO_ADDR      (DEVICE_BASE + 0x0000200)
#define DISK_ADDR       (DEVICE_BASE + 0x0000300)
#define FB_ADDR         (DEVICE_BASE + 0x1000000)
#define AUDIO_SBUF_ADDR (DEVICE_BASE + 0x1200000)


void update_rtc();
uint64_t read_rtc(int addr);
void init_device();
bool device_update();
void destroy_device();
bool mmio_read(unsigned int raddr, long unsigned int *rdata);
bool mmio_write(unsigned int waddr, long unsigned int wdata, int wlen);

#endif
