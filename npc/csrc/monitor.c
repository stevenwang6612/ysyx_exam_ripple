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
      //case 'p': sscanf(optarg, "%d", &difftest_port); break;
      //case 'l': log_file = optarg; break;
      //case 'd': diff_so_file = optarg; break;
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
  //init_log(log_file);

  /* Initialize memory. */
  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = init_mem();

  /* Initialize devices. */
  //IFDEF(CONFIG_DEVICE, init_device());

  /* Initialize dump wave file. */
  init_wave();

  /* Initialize differential testing. */
  //init_difftest(diff_so_file, img_size, difftest_port);

  /* Initialize the simple debugger. */
  init_sdb();

  /* Display welcome message. */
}
