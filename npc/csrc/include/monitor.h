#ifndef __MONITOR_H__
#define __MONITOR_H__


void init_monitor(int argc, char *argv[]);
bool difftest_step();
enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
  
#endif
