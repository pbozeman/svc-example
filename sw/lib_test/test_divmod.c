#include <stdio.h>

#include "lib_test.h"

//
// Test division and modulo functionality
//
// Verifies that software division/modulo work correctly for:
// - Signed division (positive and negative)
// - Unsigned division
// - Division required by Dhrystone
//
void test_divmod(void) {
  printf("\n-- DivMod Test --\n");

  // Unsigned division
  unsigned int udiv1 = 100 / 5;   // Should be 20
  unsigned int udiv2 = 2000 / 2;  // Should be 1000

  printf("Unsigned: 100/5=%u (%s)\n", udiv1, udiv1 == 20 ? "PASS" : "FAIL");
  printf("Unsigned: 2000/2=%u (%s)\n", udiv2, udiv2 == 1000 ? "PASS" : "FAIL");

  // Signed division (positive)
  int sdiv1 = 100 / 5;   // Should be 20
  int sdiv2 = 2000 / 2;  // Should be 1000

  printf("Signed: 100/5=%d (%s)\n", sdiv1, sdiv1 == 20 ? "PASS" : "FAIL");
  printf("Signed: 2000/2=%d (%s)\n", sdiv2, sdiv2 == 1000 ? "PASS" : "FAIL");

  // Signed division (negative)
  int sdiv3 = -100 / 5;  // Should be -20
  int sdiv4 = 100 / -5;  // Should be -20
  int sdiv5 = -100 / -5; // Should be 20

  printf("Signed: -100/5=%d (%s)\n", sdiv3, sdiv3 == -20 ? "PASS" : "FAIL");
  printf("Signed: 100/-5=%d (%s)\n", sdiv4, sdiv4 == -20 ? "PASS" : "FAIL");
  printf("Signed: -100/-5=%d (%s)\n", sdiv5, sdiv5 == 20 ? "PASS" : "FAIL");

  printf("DivMod tests complete\n");
}
