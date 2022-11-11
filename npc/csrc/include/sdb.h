#ifndef __SDB_H__
#define __SDB_H__


void init_sdb();
void sdb_set_batch_mode();
void sdb_mainloop();
uint64_t expr(char *e, bool *success);
void init_regex();
void init_wp_pool();
int new_wp(char *args);
int free_wp(char *args);
void info_wp();
bool scan_wp();
  
#endif
