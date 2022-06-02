#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <curses.h>
#include <unistd.h>
#include <time.h>
extern "C" {
#include <libxlnk_cma.h>
}
#include "OverlayControl.h"
#include "utils.hpp"

#define FRAME_BUFFER 0x16B00000

#define FRAME_BUFFER_WIDTH 640
#define FRAME_BUFFER_HEIGHT 480
#define FRAME_BUFFER_PIXELS (FRAME_BUFFER_WIDTH*FRAME_BUFFER_HEIGHT)
#define FRAME_BUFFER_SIZE (FRAME_BUFFER_WIDTH*FRAME_BUFFER_HEIGHT*4)

const uint32_t CHECKERBOARD_LENGTH (1024*1024/32);
const uint32_t MEM_IS_CACHEABLE = 0;

const uint32_t MAP_SIZE = 64*1024;
const uint32_t BASE_ADDR = 0x43C00000;

const uint32_t WINDOW_LEFT_MIN = 0;
const uint32_t WINDOW_TOP_MIN = 0;
const uint32_t WINDOW_LEFT_MAX = 1024-FRAME_BUFFER_WIDTH;
const uint32_t WINDOW_TOP_MAX = 1024-FRAME_BUFFER_HEIGHT;
const uint32_t WINDOW_INCREMENT = 100;

// Register offsets.
enum {START = 0, STOP = 1, DONE = 2, GAME_OF_LIFE_ADDRESS = 3, FRAME_BUFFER_ADDRESS = 4, WINDOW_TOP = 5, WINDOW_LEFT = 6};


///////////////////////////////////////////////////////////////////////////////
int main(){
  uint32_t * fb = (uint32_t*)cma_mmap(FRAME_BUFFER, FRAME_BUFFER_SIZE);

  volatile uint32_t * accelRegs = NULL;
  uint32_t * gol_checkerboard, * phy_gol_checkerboard;
  
  printf("This program has to be run with sudo.\n");
  printf("Press ENTER to confirm that the bitstream is loaded (proceeding without it can crash the board).\n\n");
  getchar();
  // Obtain a pointer to access the peripherals in the address map.
  if ( (accelRegs = (uint32_t*) MapMemIO(BASE_ADDR, MAP_SIZE)) == NULL ) { // [info] allocate virtual memory for cpp program in linux
    printf("Error opening accelRegs!\n");
    return -1;
  }
  printf("Mmap done. Accelerator registers mapped at 0x%08X\n", (uint32_t)accelRegs);

  printf("Allocating DMA memory...\n");
  gol_checkerboard = (uint32_t *)cma_alloc(CHECKERBOARD_LENGTH * sizeof(uint32_t), MEM_IS_CACHEABLE); // [info] returns pointer to virtual DMA memory
  phy_gol_checkerboard = (uint32_t*)((uint32_t)cma_get_phy_addr(gol_checkerboard)); // [info] returns pointer to physical DMA memory
  
  printf("DMA memory allocated.\n");
  printf("gol_checkerboard: Virt: 0x%.8X (%u) // Phys: 0x%.8X (%u)\n", (uint32_t)gol_checkerboard, (uint32_t)gol_checkerboard, (uint32_t)phy_gol_checkerboard, (uint32_t)phy_gol_checkerboard);

  if (gol_checkerboard == NULL) {
    printf("Error allocating DMA memory for %u bytes.\n", CHECKERBOARD_LENGTH * 4);
  }

  srand(time(NULL));
  InitConsole(); // Prepare ncurses for non-blocking keyboard reads with getch().

  // fill game of life checkerboard randomly
  for (uint32_t ii = 0; ii < CHECKERBOARD_LENGTH; ++ ii)
    gol_checkerboard[ii] = 1;//rand();

  PrintStringNCurses("------\nINSTRUCTIONS\n------\n\n"
        "Use the wasd keys to move the window.\n"
        "Press 'n' to start next iteration.\n"
        "Use 'r' to kill all living cells and to revive dead ones.\n"
        "Press 'q' to exit the simulation.\n");


  uint32_t window_top_current = (uint32_t)WINDOW_TOP_MIN;
  uint32_t window_left_current = (uint32_t)WINDOW_LEFT_MIN;

  // Main loop. Ends with keypress of 'q'.
  *(accelRegs + GAME_OF_LIFE_ADDRESS) = (uint32_t)phy_gol_checkerboard;
  *(accelRegs + FRAME_BUFFER_ADDRESS) = (uint32_t)FRAME_BUFFER;
  *(accelRegs + WINDOW_TOP) = window_top_current;
  *(accelRegs + WINDOW_LEFT) = window_left_current;
  *(accelRegs + START) = 0;
  *(accelRegs + STOP) = 1; 

  struct timespec start, end;
  
  int ch;
  do {
    ch = getch(); // Returns a key or ERR if there are no keypresses.
    if (ch == 'd'){//window_left is moved to the right
        printf("----------------------------------------------\r\n");
        printf("'d' press detected\r\n");
        printf("----------------------------------------------\r\n");
        if (window_left_current+WINDOW_INCREMENT < WINDOW_LEFT_MAX){
          printf("Move window to the right.\r\n");
          window_left_current=window_left_current+WINDOW_INCREMENT;
        }
        else{
          printf("Window can not be moved to the right.\r\n");
        }
    }

    if (ch == 'a'){//window_left is moved to the left
      printf("----------------------------------------------\r\n");
      printf("'a' press detected\r\n");
      printf("----------------------------------------------\r\n");
      if ((int)(window_left_current-WINDOW_INCREMENT) >= (int)WINDOW_LEFT_MIN){
        printf("Move window to the left.\r\n");
        window_left_current=window_left_current-WINDOW_INCREMENT;
      }
      else{
        printf("Window can not be moved to the left.\r\n");
      }
    }

    if (ch == 'w'){//window_top is moved up
      printf("----------------------------------------------\r\n");
      printf("'w' press detected\r\n");
      printf("----------------------------------------------\r\n");
      if (window_top_current+WINDOW_INCREMENT < WINDOW_LEFT_MAX){
        printf("Move window up.\r\n");
        window_top_current=window_top_current+WINDOW_INCREMENT;
      }
      else{
        printf("Window can not be moved further up.\r\n");
      }
    }

    if (ch == 's'){//window_top is moved down
      printf("----------------------------------------------\r\n");
      printf("'s' press detected\r\n");
      printf("----------------------------------------------\r\n");
      if ((int)(window_top_current-WINDOW_INCREMENT) >= (int)WINDOW_LEFT_MIN){
        printf("Move window down.\r\n");
        window_top_current=window_top_current-WINDOW_INCREMENT;
      }
      else{
        printf("Window can not be moved further down.\r\n");
      }
    }

    *(accelRegs + WINDOW_TOP) = window_top_current;
    *(accelRegs + WINDOW_LEFT) = window_left_current;

    if (ch == 'r'){//Dead cells are now alive and vice versa
      printf("----------------------------------------------\r\n");
      printf("'r' press detected\r\n");
      printf("----------------------------------------------\r\n");
      *(accelRegs + START) = 0;
      *(accelRegs + STOP) = 1;
      while ((*(accelRegs + DONE) = 0)){
        usleep(5);
      }
      
      for (uint32_t ii = 0; ii < CHECKERBOARD_LENGTH; ++ ii)
        gol_checkerboard[ii] = ~gol_checkerboard[ii];
      printf("Dead cells are now alive and vice versa.\r\n");
      *(accelRegs + START) = 1;
      *(accelRegs + STOP) = 1;
    }

    *(accelRegs + START) = 0;
    *(accelRegs + STOP) = 1; 

    if (ch == 'n'){//next iteration please
      printf("----------------------------------------------\r\n");
      printf("'n' press detected\r\n");
      printf("----------------------------------------------\r\n");
      clock_gettime(CLOCK_MONOTONIC_RAW, &start);

      *(accelRegs + START) = 1;
      *(accelRegs + STOP) = 1; 
      *(accelRegs + START) = 0;

      while ((*(accelRegs + DONE) == 0)){
        usleep(5);
      }

      clock_gettime(CLOCK_MONOTONIC_RAW, &end);
      unsigned long long elapsed = CalcTimeDiff(end, start);
      printf("Iteration done\r\n");
      printf("Iteration took %llu ns\r\n", elapsed);
    }

    if (ch == 'p'){
      printf("----------------------------------------------\r\n");
      printf("'p' press detected\r\n");
      printf("----------------------------------------------\r\n");
    }

  } while ( ch != 'q');
  *(accelRegs + START) = 0;
  *(accelRegs + STOP) = 1; 
  printf("we are done with all this stuff\r\n");
  usleep(5000000);
  RestoreConsole(); // If your program crashes and you loose the terminal, write: stty sane^J
  UnmapMemIO();
  return 0;
}



///////////////////////////////////////////////////////////////////////////////
// Fills a framebuffer with a given solid color.
// It's equivalent to memset().
void FillColor(uint32_t * frame, uint32_t width, uint32_t height, uint32_t color)
{
  uint32_t * pp = frame;
  for (uint32_t yy = 0; yy < height; ++ yy) {
    for (uint32_t xx = 0; xx < width; ++ xx) {
      *pp++ = color;
    }
  }
}