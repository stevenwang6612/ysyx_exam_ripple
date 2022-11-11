#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>
#include <sys/time.h>
#include <fcntl.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
static int canvas_w = 0, canvas_h = 0;

uint32_t NDL_GetTicks() {
  struct timeval now;
  gettimeofday(&now, NULL);
  return now.tv_sec * 1000000 + now.tv_usec;
}

int NDL_PollEvent(char *buf, int len) {
  FILE *fp = fopen("/dev/events", "r");
  if(fp==NULL) return 0;
  char *res;
  res = fgets(buf, len, fp);
  if(buf[strlen(buf)-1]=='\n') buf[strlen(buf)] = '\0';
  fclose(fp);
  return res!=NULL;
}

void NDL_OpenCanvas(int *w, int *h) {
  if (*w == 0 || *w>screen_w) *w = screen_w;
  if (*h == 0 || *h>screen_h) *h = screen_h;
  canvas_w = *w;
  canvas_h = *h;

  if (getenv("NWM_APP")) {
    int fbctl = 4;
    fbdev = 5;
    screen_w = *w; screen_h = *h;
    char buf[64];
    int len = sprintf(buf, "%d %d", screen_w, screen_h);
    // let NWM resize the window and create the frame buffer
    write(fbctl, buf, len);
    while (1) {
      // 3 = evtdev
      int nread = read(3, buf, sizeof(buf) - 1);
      if (nread <= 0) continue;
      buf[nread] = '\0';
      if (strcmp(buf, "mmap ok") == 0) break;
    }
    close(fbctl);
  }
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  int wi = w>canvas_w ? canvas_w : w;
  int hi = h>canvas_h ? canvas_h : h;
  int fd = open("/dev/fb", O_WRONLY);
  // 向系统申请的画布尺寸和硬件的尺寸不一定一致
  // 要进行加数保持居中
  x = x % canvas_w;
  y = y % canvas_h;
  x += (screen_w - canvas_w) / 2;
  y += (screen_h - canvas_h) / 2;

  for (int i = 0; i < hi; ++ i) {
    lseek(fd, ((y + i) * screen_w + x) * sizeof(uint32_t), SEEK_SET);
    write(fd, pixels + i * w, wi * sizeof(uint32_t));
  }
}

void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  char buf[128];
  // 注意dispinfo的格式，"WIDTH:%d\nHEIGHT:%d"
  int dispinfo_fd = open("/proc/dispinfo", 0);
  read(dispinfo_fd, buf, sizeof(buf));
  close(dispinfo_fd);

  char *k_v = strtok(buf, "\n");
	while(k_v){
		int value = 0;
		char key[128];
    key[0] = '\0';
		sscanf(k_v, "%[a-zA-Z] : %d", key, &value);
    if(strncmp(key, "WIDTH", 5)==0) screen_w = value;
    if(strncmp(key, "HEIGHT", 5)==0) screen_h = value;
		k_v = strtok(NULL, "\n");
	}
	return 0;
}

void NDL_Quit() {
}
