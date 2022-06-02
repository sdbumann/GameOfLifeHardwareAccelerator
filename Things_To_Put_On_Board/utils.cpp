#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <curses.h>
#include <unistd.h>
#include "utils.hpp"

void InitConsole()
{
  initscr();
  cbreak();
  noecho();
  nodelay(stdscr, TRUE);
  keypad(stdscr, TRUE);
}

void RestoreConsole()
{
  endwin();
}

void PrintStringNCurses(const char * string)
{
  char * p = (char*)string;
  while (*p != '\0') {
    waddch(stdscr, *p | A_BLINK);
    ++ p;
  }
  wrefresh(stdscr);
}

///////////////////////////////////////////////////////////////////////////////
unsigned long long CalcTimeDiff(const struct timespec & time2, const struct timespec & time1)
{
  return time2.tv_sec == time1.tv_sec ?
    time2.tv_nsec - time1.tv_nsec :
    (time2.tv_sec - time1.tv_sec - 1) * 1e9 + (1e9 - time1.tv_nsec) + time2.tv_nsec;
}

/*  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC_RAW, &start);
  clock_gettime(CLOCK_MONOTONIC_RAW, &end);
  unsigned long long elapsed = CalcTimeDiff(end, start);
  printf("Time: %0.3lf s (%llu ns)\n", elapsed/1e9, elapsed);
*/


