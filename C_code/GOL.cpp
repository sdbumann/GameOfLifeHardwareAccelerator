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
#include "types.hpp"
#include "utils.hpp"

#define FRAME_BUFFER 0x16B00000
#define FRAME_BUFFER_SIZE (640*480*4)
#define FRAME_BUFFER_PIXELS (640*480)
#define VSYNC_BASEADDR  0x43C80000
enum {VSYNC_ENABLE = 1, VSYNC_ENABLE_INTERRUPT = 2, VSYNC_POLL = 4};

uint32_t backBuffer[FRAME_BUFFER_PIXELS];

const uint32_t CHECKERBOARD_LENGTH (1024*1024);
const uint32_t MEM_IS_CACHEABLE = 0;

const uint32_t MAP_SIZE = 64*1024;
const uint32_t BASE_ADDR = 0x43C00000;

const uint32_t WINDOW_LEFT_MIN = 0;
const uint32_t WINDOW_TOP_MIN = 0;
const uint32_t WINDOW_LEFT_MAX = 1024-320;
const uint32_t WINDOW_TOP_MAX = 1024-240;
const uint32_t WINDOW_INCREMENT = 100;


// Register offsets.
enum {START = 0, STOP = 1, DONE = 2, GAME_OF_LIFE_ADDRESS = 3, FRAME_BUFFER_ADDRESS = 4, WINDOW_TOP = 5, WINDOW_LEFT = 6};

///////////////////////////////////////////////////////////////////////////////
int main(int argc, char ** argv)
{
  uint32_t * fb = (uint32_t*)cma_mmap(FRAME_BUFFER, FRAME_BUFFER_SIZE);
  phy_fb = (uint32_t*)((uint32_t)cma_get_phy_addr(fb)); // [TODO]???? does this work?

  volatile uint32_t * vsync = MapMemIO(VSYNC_BASEADDR, 64*1024);
  if (vsync == NULL) {
    printf("Error mmaping vsync device.\n");
    return -1;
  }
  *(vsync + VSYNC_ENABLE_INTERRUPT) = 1;
  *(vsync + VSYNC_ENABLE) = 1;
  
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
    gol_checkerboard[ii] = rand();

  // Fill the screen with solid colors to verify proper functioning.
  FillColor(fb, gameInfo.frameWidth, gameInfo.frameHeight, 0x000000FF); // Red
  usleep(500000);
  FillColor(fb, gameInfo.frameWidth, gameInfo.frameHeight, 0x0000FF00); // Green
  usleep(500000);
  FillColor(fb, gameInfo.frameWidth, gameInfo.frameHeight, 0x00FF0000); // Blue
  usleep(500000);
  FillColor(fb, gameInfo.frameWidth, gameInfo.frameHeight, 0); // Black

  PrintStringNCurses("------\nINSTRUCTIONS\n------\n\n"
        "Use the arrow keys to move the window.\n"
        "Use 'r' to kill al living cells and to revive dead ones.\n"
        "Press 'q' to exit the simulation.\n");


  uint32_t window_top_current = (uint32_t)WINDOW_TOP_INIT;
  uint32_t window_left_current = (uint32_t)WINDOW_LEFT_INIT;






  // Program the accelerator and start it.
  *(accelRegs + GAME_OF_LIFE_ADDRESS) = (uint32_t)phy_gol_checkerboard;
  *(accelRegs + FRAME_BUFFER_ADDRESS) = (uint32_t)phy_fb;
  *(accelRegs + WINDOW_TOP) = window_top_current;
  *(accelRegs + WINDOW_LEFT) = window_left_current;
  *(accelRegs + START) = 1;

  //*(accelRegs + START) = 0;
  //*(accelRegs + STOP) = 1;

  // Wait for completion.
  if*(accelRegs + DONE){
    printf("Game of Life Accelerator has done one iteration\n")
  }








  // Main loop. Ends with keypress of 'q'.
  *(accelRegs + GAME_OF_LIFE_ADDRESS) = (uint32_t)phy_gol_checkerboard;
  *(accelRegs + FRAME_BUFFER_ADDRESS) = (uint32_t)phy_fb;
  *(accelRegs + START) = 1;
  int ch;
  do {
    while (! *(vsync + VSYNC_POLL));  // Wait for vertical blanking period.
    memcpy(fb, backBuffer, FRAME_BUFFER_SIZE);

    // Wait for completion.
    if*(accelRegs + DONE){
      printf("Game of Life Accelerator has done one iteration\n")
    }

    if (ch = 'd'){//window_left is moved to the right
        printf("'d' press detected\n");
        if (window_left_current+WINDOW_INCREMENT < WINDOW_LEFT_MAX){
          printf("Move window to the right.\n");
          window_left_current=window_left_current+WINDOW_INCREMENT;
        }
        else{
          printf("Window can not be moved to the right.\n");
        }
    }

    if (ch = 'a'){//window_left is moved to the left
      printf("'a' press detected\n");
      if (window_left_current-WINDOW_INCREMENT >= WINDOW_LEFT_MIN){
        printf("Move window to the left.\n");
        window_left_current=window_left_current-WINDOW_INCREMENT;
      }
      else{
        printf("Window can not be moved to the left.\n");
      }
    }

    if (ch = 'w'){//window_top is moved up
      printf("'w' press detected\n");
      if (window_top_current+WINDOW_INCREMENT < WINDOW_LEFT_MAX){
        printf("Move window up.\n");
        window_top_current=window_top_current+WINDOW_INCREMENT;
      }
      else{
        printf("Window can not be moved further up.\n");
      }
    }

    if (ch = 's'){//window_top is moved down
      printf("'s' press detected\n");
      if (window_top_current-WINDOW_INCREMENT >= WINDOW_LEFT_MIN){
        printf("Move window down.\n");
        window_top_current=window_top_current-WINDOW_INCREMENT;
      }
      else{
        printf("Window can not be moved further down.\n");
      }
    }

    *(accelRegs + WINDOW_TOP) = window_top_current;
    *(accelRegs + WINDOW_LEFT) = window_left_current;

    if (ch = 'r'){//Dead cells are now alive and vice versa
      printf("r press detected\n");
      *(accelRegs + START) = 0;
      *(accelRegs + STOP) = 1;
      while (*(accelRegs + DONE) = 0){
        usleep(5000);
      }
      
      for (uint32_t ii = 0; ii < CHECKERBOARD_LENGTH; ++ ii)
        gol_checkerboard[ii] = ~gol_checkerboard[ii];
      printf("Dead cells are now alive and vice versa.\n");
      *(accelRegs + START) = 1;
      *(accelRegs + STOP) = 0;
    }

    ch = getch(); // Returns a key or ERR if there are no keypresses.
    if (ch != ERR)
      //[TODO]
  } while ( ch != 'q');

  RestoreConsole(); // If your program crashes and you loose the terminal, write: stty sane^J
  UnmapMemIO();
  return 0;
}
