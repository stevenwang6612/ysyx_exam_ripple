#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

word_t vaddr_read(vaddr_t addr, int len);

static int is_batch_mode = false;

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  return -1;
}


static int cmd_s(char *args);
static int cmd_x(char *args);
static int cmd_p(char *args);
static int cmd_w(char *args);
static int cmd_d(char *args);
static int cmd_help(char *args);
static int cmd_info(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display informations about all supported commands", cmd_help },
  { "info", "Display informations about the system", cmd_info },
  { "c", "Continue the execution of the program", cmd_c },
  { "s", "Step N instructions", cmd_s },
  { "x", "Scan memory in hexadecimal", cmd_x },
  { "p", "Expression Evaluation" ,cmd_p },
  { "w", "Set watchpoint" ,cmd_w },
  { "d", "Delete watchpoint" ,cmd_d },
  { "q", "Exit NEMU", cmd_q },
  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}


static int cmd_s(char *args){
  char *arg = strtok(NULL, " ");
  u_int64_t step_num = 1;
  if(arg != NULL){sscanf(arg,"%ld",&step_num);}
  cpu_exec(step_num);
  return 0;
}

static int cmd_x(char *args){
  int length = 0;
  vaddr_t addr;
  char *arg = strtok(NULL, " ");
  if(arg!=NULL){
    sscanf(arg,"%d",&length);
    arg = strtok(NULL, " ");
  }else{
    printf("please input `length` and `address`!\n");
    return 0;
  }
  if(arg!=NULL){
    bool success = true;
    addr = expr(arg,&success);
    if(success){
      for(int i=0; i<length;i++){
        printf("0x%016lx: 0x%016lx\n",addr,vaddr_read(addr,8));
        addr += 8;
      }
    }
  }else{
    printf("please input `address`!\n");
  }
  return 0;
}

static int cmd_p(char *args) {
  //printf("Expression : '%s'\n", args);
  bool success = true;
  word_t result;
  if(args == NULL){
    printf("Please input expression!\n");
  }
  else{
    result = expr(args,&success);
    if(success){
      printf("%-24ld0x%lx\n", result, result);
    }
    else{
      printf("Invalid expression : '%s'\n", args);
    }
  }
  return 0;
}

static int cmd_w(char *args){
  int flag = new_wp(args);
  if(flag==-1){
    printf("the free watchpoing pool is empty, please retry after deleting some watchpoints\n");
  }else if(flag==-2){
    printf("Invalid expression : '%s'\n", args);
  }else{
    printf("watchpoint %d: %s has been set\n", flag, args);
  }
  return 0;
}

static int cmd_d(char *args){
  int flag = free_wp(args);
  if(flag==-1){
    printf("the used watchpoing pool is empty, please retry after setting some watchpoints\n");
  }else if(flag==-2){
    printf("Not found the watchpoint~\n");
  }else{
    printf("watchpoint %d: %s has been deleted\n", flag, args);
  }
  return 0;
}

static int cmd_info(char *args){
  if(args==NULL){
    printf("No argument! you can try 'w' or 'r'~\n");
  }else if(*args=='r'){
    isa_reg_display();
  }else if(*args=='w'){
    info_wp();
  }else{
    printf("invalid argument! you can try 'w' or 'r'~\n");
  }
  return 0;
}
