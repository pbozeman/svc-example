#include "lib_test.h"
#include "stdio.h"

#include <stdint.h>

//
// Test printf format specifiers with width and zero-padding
//
void test_printf(void) {
  printf("=== Printf Format Tests ===\n");

  // Basic unsigned decimal
  printf("Basic %%u: %u\n", 42);

  // Width without zero-padding
  printf("Width 5: [%5u]\n", 42);

  // Width with zero-padding
  printf("Zero-pad 3: [%03u]\n", 5);
  printf("Zero-pad 4: [%04u]\n", 42);
  printf("Zero-pad 5: [%05u]\n", 123);

  // DMIPS/MHz format test (like Dhrystone uses)
  uint32_t dmips_x1000 = 567;  // Represents 0.567 DMIPS/MHz
  printf("DMIPS/MHz: %u.%03u\n", dmips_x1000 / 1000, dmips_x1000 % 1000);

  // Hex with zero-padding
  printf("Hex zero-pad 8: 0x%08x\n", 0xDEAD);

  // Signed integers
  printf("Signed: %d\n", -42);
  printf("Signed zero-pad: %05d\n", -7);

  // Edge cases
  printf("Zero: %03u\n", 0);
  printf("Large: %010u\n", 123456789);

  printf("Printf tests complete\n");
}
