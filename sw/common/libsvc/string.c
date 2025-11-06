#include "libsvc/string.h"

//
// Copy string from src to dst
//
char* strcpy(char* dst, const char* src) {
  char* d = dst;
  while ((*d++ = *src++))
    ;
  return dst;
}

//
// Calculate length of string
//
size_t strlen(const char* s) {
  const char* p = s;
  while (*p) p++;
  return p - s;
}
