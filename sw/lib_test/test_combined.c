#include "stdio.h"

#include "libsvc/csr.h"
#include "libsvc/malloc.h"
#include "libsvc/string.h"
#include "lib_test.h"

//
// Combined test using all infrastructure together
//
// Creates a linked list using malloc, fills it with data using string
// functions, and times the whole operation using CSR counters. This
// validates that all pieces work together correctly before Dhrystone.
//

typedef struct Node {
  int data;
  struct Node* next;
} Node;

void test_combined(void) {
  printf("\n-- Combined Test --\n");

  uint64_t start = read_cycles();

  // Allocate linked list
  Node* head = malloc(sizeof(Node));
  Node* current = head;

  for (int i = 0; i < 10; i++) {
    current->data = i;
    if (i < 9) {
      current->next = malloc(sizeof(Node));
      current = current->next;
    } else {
      current->next = NULL;
    }
  }

  // Traverse and sum
  int sum = 0;
  current = head;
  while (current) {
    sum += current->data;
    current = current->next;
  }

  uint64_t end = read_cycles();

  printf("Sum: %d (expected 45)\n", sum);
  printf("Cycles: %u\n", (unsigned int)(end - start));

  if (sum == 45) {
    printf("Combined test: PASS\n");
  } else {
    printf("Combined test: FAIL\n");
  }

  // String test
  char buf[32];
  strcpy(buf, "Success!");
  printf("Result: %s\n", buf);
}
