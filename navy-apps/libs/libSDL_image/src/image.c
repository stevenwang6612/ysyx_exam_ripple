#define SDL_malloc  malloc
#define SDL_free    free
#define SDL_realloc realloc

#define SDL_STBIMAGE_IMPLEMENTATION
#include "SDL_stbimage.h"

SDL_Surface* IMG_Load_RW(SDL_RWops *src, int freesrc) {
  assert(src->type == RW_TYPE_MEM);
  assert(freesrc == 0);
  return NULL;
}

SDL_Surface* IMG_Load(const char *filename) {
  FILE *fp = fopen(filename, "r");
  assert(fp);

  // 跳转到文件末尾，然后读取偏移，获取文件大小
  fseek(fp, 0, SEEK_END);
  int size = ftell(fp);

  // 返回文件开头
  fseek(fp, 0, SEEK_SET);

  // 申请一段大小为size的内存区间buf
  char *buf = malloc(size + 1);

  // 将整个文件读取到buf中并关闭文件
  fread(buf, 1, size, fp);
  fclose(fp);
  buf[size] = 0;

  // 将buf和size作为参数, 调用STBIMG_LoadFromMemory(), 它会返回一个SDL_Surface结构的指针
  SDL_Surface *surface = STBIMG_LoadFromMemory(buf, size);

  // 释放内存
  free(buf);

  // 返回SDL_Surface结构指针
  return surface;
}

int IMG_isPNG(SDL_RWops *src) {
  return 0;
}

SDL_Surface* IMG_LoadJPG_RW(SDL_RWops *src) {
  return IMG_Load_RW(src, 0);
}

char *IMG_GetError() {
  return "Navy does not support IMG_GetError()";
}
