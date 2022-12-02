#ifndef __DEVICE_H__
#define __DEVICE_H__

#include <common.h>

void update_rtc();
uint64_t read_rtc(int addr);
void init_device();
bool mmio_read(unsigned int raddr, long unsigned int *rdata);
bool mmio_write(unsigned int waddr, long unsigned int wdata, int wlen);

#endif
