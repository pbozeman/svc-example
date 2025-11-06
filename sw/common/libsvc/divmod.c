#include <stdint.h>

//
// Software implementation of unsigned division and modulo
//
// RV32I base ISA does not include hardware division/modulo instructions.
// These are required for printf's number formatting.
//

//
// Unsigned 32-bit division
//
uint32_t __udivsi3(uint32_t dividend, uint32_t divisor) {
  if (divisor == 0) {
    return 0;  // Undefined behavior, but safe fallback
  }

  uint32_t quotient = 0;
  uint32_t remainder = 0;

  // Long division algorithm
  for (int i = 31; i >= 0; i--) {
    remainder = (remainder << 1) | ((dividend >> i) & 1);
    if (remainder >= divisor) {
      remainder -= divisor;
      quotient |= (1u << i);
    }
  }

  return quotient;
}

//
// Unsigned 32-bit modulo
//
uint32_t __umodsi3(uint32_t dividend, uint32_t divisor) {
  if (divisor == 0) {
    return 0;  // Undefined behavior, but safe fallback
  }

  uint32_t remainder = 0;

  // Long division algorithm - only track remainder
  for (int i = 31; i >= 0; i--) {
    remainder = (remainder << 1) | ((dividend >> i) & 1);
    if (remainder >= divisor) {
      remainder -= divisor;
    }
  }

  return remainder;
}
