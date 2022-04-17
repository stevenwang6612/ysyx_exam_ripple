#ifndef __SDB_H__
#define __SDB_H__

#include <common.h>

word_t expr(char *e, bool *success);
void init_regex();
void init_wp_pool();
int new_wp(char *args);
int free_wp(char *args);
void info_wp();
bool scan_wp();

#endif
