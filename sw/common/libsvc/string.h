#ifndef STRING_H
#define STRING_H

#include <stddef.h>

//
// String manipulation functions
//
// Basic string operations for bare-metal RISC-V programs.
// strcmp uses optimized RISC-V assembly for performance.
//

//
// Copy string from src to dst
// Returns dst
//
char* strcpy(char* dst, const char* src);

//
// Compare two strings lexicographically
// Returns: negative if s1 < s2, 0 if s1 == s2, positive if s1 > s2
//
int strcmp(const char* s1, const char* s2);

//
// Calculate length of string
// Returns number of characters before null terminator
//
size_t strlen(const char* s);

#endif  // STRING_H
