#include <fs.h>

typedef size_t (*ReadFn) (void *buf, size_t offset, size_t len);
typedef size_t (*WriteFn) (const void *buf, size_t offset, size_t len);

size_t ramdisk_read(void *buf, size_t offset, size_t len);
size_t ramdisk_write(const void *buf, size_t offset, size_t len);

typedef struct {
  char *name;
  size_t size;
  size_t disk_offset;
  ReadFn read;
  WriteFn write;
  size_t open_offset;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_EVENTS, FD_DISP, FD_FB};

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}
size_t serial_write(const void *buf, size_t offset, size_t len);
size_t fb_write(const void *buf, size_t offset, size_t len);
size_t events_read(void *buf, size_t offset, size_t len);
size_t dispinfo_read(void *buf, size_t offset, size_t len);

/* This is the information about all files in disk. */
#define num_VF 6
static Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, invalid_read, serial_write},
  [FD_STDERR] = {"stderr", 0, 0, invalid_read, serial_write},
  [FD_EVENTS] = {"/dev/events", 0, 0, events_read, invalid_write},
  [FD_DISP]   = {"/proc/dispinfo", 0, 0, dispinfo_read, invalid_write},
  [FD_FB]     = {"/dev/fb", 0, 0, invalid_read, fb_write},
#include "files.h"
};
static int fcnt = sizeof(file_table) / sizeof(file_table[0]);

int fs_open(const char *pathname, int flags, int mode){
  for(int i=0; i<fcnt; i++)
    if(strcmp(pathname, file_table[i].name)==0){
      file_table[i].open_offset = 0;
      return i;
    }
  return -1;
}
int fs_close(int fd){return 0;}

size_t fs_read(int fd, void *buf, size_t len){
  size_t offset;
  if(fd>=fcnt){
    return -1;
  }else if(fd<num_VF){
    offset = 0;
  }else{
    if(file_table[fd].open_offset > file_table[fd].size)
      len = 0;
    else if(file_table[fd].open_offset+len > file_table[fd].size)
      len = file_table[fd].size - file_table[fd].open_offset;
    offset = file_table[fd].disk_offset + file_table[fd].open_offset;
  }
  file_table[fd].open_offset += len;
  return file_table[fd].read(buf, offset, len);
}
size_t fs_write(int fd, const void *buf, size_t len){
  size_t offset;
  if(fd>=fcnt || fd<0){
    return -1;
  }else if(fd<num_VF && fd!=FD_FB){
    offset = 0;
  }else{
    if(file_table[fd].open_offset > file_table[fd].size)
      len = 0;
    else if(file_table[fd].open_offset+len > file_table[fd].size)
      len = file_table[fd].size - file_table[fd].open_offset;
    offset = file_table[fd].disk_offset + file_table[fd].open_offset;
  }
  file_table[fd].open_offset += len;
  return file_table[fd].write(buf, offset, len);
}

size_t fs_lseek(int fd, size_t offset, int whence){
  if(fd>=fcnt || fd<0)
    return -1;
  switch(whence){
    case SEEK_SET: file_table[fd].open_offset = offset;
                   break;
    case SEEK_CUR: file_table[fd].open_offset += offset;
                   break;
    case SEEK_END: file_table[fd].open_offset=offset+file_table[fd].size;
                   break;
    default: return -1;
  }
  return file_table[fd].open_offset;
}

void init_fs() {
  for(int i=num_VF; i<fcnt; i++){
    file_table[i].read = ramdisk_read;
    file_table[i].write = ramdisk_write;
  }
  // TODO: initialize the size of /dev/fb
  if(io_read(AM_GPU_CONFIG).present){
    int w = io_read(AM_GPU_CONFIG).width;
    int h = io_read(AM_GPU_CONFIG).height;
    file_table[FD_FB].size = w * h * 4;
  }
}
