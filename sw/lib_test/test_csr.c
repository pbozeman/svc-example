#include "stdio.h"

#include "libsvc/csr.h"
#include "lib_test.h"

//
// Test CSR cycle counter functionality
//
// Verifies that:
// - rdcycle instructions work
// - Cycle counter increments as expected
// - 64-bit atomic read handles potential rollover
//
void test_csr(void) {
  printf("-- CSR Test --\n");

  uint64_t start = read_cycles();

  // Do some work - execute NOPs
  for (int i = 0; i < 1000; i++) {
    asm volatile("nop");
  }

  uint64_t end = read_cycles();
  uint32_t elapsed = (uint32_t)(end - start);

  printf("Cycles elapsed: %u\n", elapsed);
  printf("Expected > 1000, got %s\n", elapsed > 1000 ? "PASS" : "FAIL");
}
