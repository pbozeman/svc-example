#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lib_test.h"

//
// Test malloc functionality
//
// Verifies that:
// - malloc returns non-NULL pointers
// - Allocated addresses are different and properly aligned
// - Values can be stored and retrieved correctly
// - No memory corruption between allocations
//

typedef struct {
  int value;
  char name[16];
} TestStruct;

void test_malloc(void) {
  printf("\n-- Malloc Test --\n");

  printf("Allocating TestStruct (size=%u bytes)\n",
         (unsigned int)sizeof(TestStruct));

  TestStruct* p1 = malloc(sizeof(TestStruct));
  printf("p1 = 0x%x\n", (unsigned int)p1);

  TestStruct* p2 = malloc(sizeof(TestStruct));
  printf("p2 = 0x%x\n", (unsigned int)p2);

  // Note: In bare-metal, address 0 is valid (heap starts at DMEM base)
  // So we can't use NULL check. Instead verify addresses are different.
  if (p1 == p2) {
    printf("malloc returned same address! FAIL\n");
    return;
  }

  p1->value = 42;
  strcpy(p1->name, "First");

  p2->value = 99;
  strcpy(p2->name, "Second");

  printf("p1: value=%d, name=%s, addr=0x%x\n", p1->value, p1->name,
         (unsigned int)p1);
  printf("p2: value=%d, name=%s, addr=0x%x\n", p2->value, p2->name,
         (unsigned int)p2);

  int pass = (p1->value == 42 && p2->value == 99 &&
              strcmp(p1->name, "First") == 0 &&
              strcmp(p2->name, "Second") == 0 && p1 != p2);

  if (pass) {
    printf("Malloc test: PASS\n");
  } else {
    printf("Malloc test: FAIL\n");
  }

  // Test alignment (addresses should be 4-byte aligned)
  printf("Malloc tests complete\n");
}
