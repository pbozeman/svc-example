#include <stdio.h>
#include <string.h>

#include "lib_test.h"

//
// Test string function functionality
//
// Verifies that:
// - strcpy correctly copies strings
// - strcmp returns correct comparison results (negative/zero/positive)
// - strlen returns correct string lengths
//
void test_string(void) {
  printf("\n-- String Test --\n");

  char buf1[32], buf2[32];
  strcpy(buf1, "Hello");
  strcpy(buf2, "World");

  printf("buf1: %s\n", buf1);
  printf("buf2: %s\n", buf2);

  int cmp1 = strcmp(buf1, buf2);  // Should be negative
  int cmp2 = strcmp(buf1, buf1);  // Should be zero

  printf("strcmp(Hello, World): %d (%s)\n", cmp1, cmp1 < 0 ? "PASS" : "FAIL");
  printf("strcmp(Hello, Hello): %d (%s)\n", cmp2, cmp2 == 0 ? "PASS" : "FAIL");

  strcpy(buf2, buf1);
  int cmp3 = strcmp(buf1, buf2);
  printf("After copy, strcmp: %d (%s)\n", cmp3, cmp3 == 0 ? "PASS" : "FAIL");

  // Test strlen
  size_t len1 = strlen(buf1);
  size_t len2 = strlen("Test");
  printf("strlen(Hello): %u (%s)\n", (unsigned)len1,
         len1 == 5 ? "PASS" : "FAIL");
  printf("strlen(Test): %u (%s)\n", (unsigned)len2,
         len2 == 4 ? "PASS" : "FAIL");
}
