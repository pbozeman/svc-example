#include "stdio.h"

#include "lib_test.h"

//
// Main test dispatcher for libsvc infrastructure tests
//
// Runs a suite of tests to verify CSR, string, malloc, and other
// library functionality before integrating Dhrystone benchmark.
//
int main(void) {
  puts("=== libsvc Test Suite ===");
  puts("");

  test_csr();
  test_string();
  test_malloc();
  test_combined();
  test_divmod();
  test_printf();

  puts("");
  puts("=== All tests complete ===");

  return 0;
}
