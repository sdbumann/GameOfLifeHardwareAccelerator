#ifndef UTILS_HPP
#define UTILS_HPP

void InitConsole();
void RestoreConsole();

void PrintStringNCurses(const char * string);
unsigned long long CalcTimeDiff(const struct timespec & time2, const struct timespec & time1);

#endif // UTILS_HPP

