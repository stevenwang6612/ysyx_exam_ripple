#include <stdio.h>
#include <NDL.h>
#include <assert.h>

int main() {
  NDL_Init(0);
  uint32_t time;
  time = NDL_GetTicks();
  while(1){
    if(NDL_GetTicks() - time > 500000){
      time = NDL_GetTicks();
      printf("Hello! 0.5s passed!\n");
    }
  }
  NDL_Quit();
}
