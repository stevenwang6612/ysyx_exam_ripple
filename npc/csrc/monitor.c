/*========================================================
#
# Author: Steven
#
# QQ : 935438447 
#
# Last modified: 2022-04-28 16:28
#
# Filename: monitor.c
#
# Description: 
#
=========================================================*/
#include <common.h>
#include <getopt.h>
#include <dlfcn.h>


FILE *log_fp = NULL;
char *log_file = NULL;
static char *diff_so_file = NULL;
static int difftest_port = 1234;


void init_disasm(const char *triple);
static void init_log();
static void init_difftest(long img_size);
static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , 0, NULL, 'b'},
    {"image"    , 1, NULL, 'i'},
    {"wave"     , 2, NULL, 'w'},
    {"log"      , 1, NULL, 'l'},
    {"diff"     , 1, NULL, 'd'},
    {"port"     , 1, NULL, 'p'},
    {"help"     , 0, NULL, 'h'},
    {0          , 0, NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhi:l:d:p:w::", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'i': set_image_file(optarg); break;
      case 'w': set_wave_file(optarg); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'l': log_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      default:
        printf("Usage: %s [OPTION...] \n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-i,--image=FILE         load image from FILE\n");
        printf("\t-w,--wave[=FILE]        dump wave to (FILE: default is `./build/wave.vcd`\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[]) {
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);

  /* Set random seed. */
  //init_rand();

  /* Open the log file. */
  init_log();

  /* Initialize memory. */
  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = init_mem();
  /* Initialize devices. */
  //IFDEF(CONFIG_DEVICE, init_device());

  /* Initialize dump wave file. */
  init_wave();

  /* Initialize differential testing. */
  init_difftest(img_size);

  /* Initialize the simple debugger. */
  init_sdb();

  init_disasm("riscv64-pc-linux-gnu");

  /* Display welcome message. */
}


//log
static void init_log() {
  if (log_file != NULL) {
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    log_fp = fp;
  }else
    log_fp = stdout;
  Log("Log is written to %s", log_file ? log_file : "stdout");
}

//difftest
void (*ref_difftest_memcpy)(word_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;
extern uint8_t *imem_ptr;

static void init_difftest(long img_size) {
  if(diff_so_file == NULL){
  Log("Differential testing: %s", ASNI_FMT("OFF", ASNI_FG_RED));
    return;
  }

  void *handle;
  handle = dlopen(diff_so_file, RTLD_LAZY);
  if(!handle)
    printf("%s\n", dlerror());

  ref_difftest_memcpy = (void(*)(word_t, void*, size_t, bool))dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void (*)(void*, bool))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint64_t))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void (*)(uint64_t))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = (void (*)(int))dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s", ASNI_FMT("ON", ASNI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. ", diff_so_file);

  CPU_state cpu;
  cpu.pc = RESET_VECTOR;
  for(int i=0; i<32; i++)
    cpu.gpr[i] = 0;

  ref_difftest_init(difftest_port);
  ref_difftest_memcpy(RESET_VECTOR, imem_ptr, img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

static bool checkregs(CPU_state *ref_r) {
  bool flag = true;
  if(ref_r->pc == getPC()){
    for(int i=0; i<32; i++){
      if(gpr_read(i) != ref_r->gpr[i]){
        flag = false;
        break;
      }
    }
  }else{
    flag = false;
  }
  if(!flag){
    printf("reg\tdut\t\t\tref\n");
    printf("pc\t0x%-16llx\t0x%-16lx\n",getPC(),ref_r->pc);
    for(int i=0; i<32; i++){
      printf("%s\t0x%-16lx\t0x%-16lx\n",reg_name(i),gpr_read(i),ref_r->gpr[i]);
    }
  }
  return flag;
}

bool difftest_step() {
  if(diff_so_file){
    CPU_state ref_r;
    ref_difftest_exec(1);
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
    return checkregs(&ref_r);
  }else{
    return true;
  }
}

