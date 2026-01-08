#include <stdint.h>

//
// Software implementation of division and modulo (signed and unsigned)
//
// RV32I base ISA does not include hardware division/modulo instructions.
// These are required for printf's number formatting and Dhrystone calculations.
//

//
// Unsigned 32-bit division
//
uint32_t __udivsi3(uint32_t dividend, uint32_t divisor) {
  if (divisor == 0) {
    return 0;  // Undefined behavior, but safe fallback
  }

  uint32_t quotient  = 0;
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

//
// Signed 32-bit division
//
int32_t __divsi3(int32_t dividend, int32_t divisor) {
  if (divisor == 0) {
    return 0;  // Undefined behavior, but safe fallback
  }

  // Handle signs
  int negative = 0;
  if (dividend < 0) {
    negative = !negative;
    dividend = -dividend;
  }
  if (divisor < 0) {
    negative = !negative;
    divisor  = -divisor;
  }

  // Perform unsigned division
  uint32_t quotient = __udivsi3((uint32_t)dividend, (uint32_t)divisor);

  // Apply sign
  return negative ? -(int32_t)quotient : (int32_t)quotient;
}

//
// Signed 32-bit modulo
//
int32_t __modsi3(int32_t dividend, int32_t divisor) {
  if (divisor == 0) {
    return 0;  // Undefined behavior, but safe fallback
  }

  // Modulo result should have the same sign as dividend
  int negative = dividend < 0;
  if (dividend < 0) dividend = -dividend;
  if (divisor < 0) divisor = -divisor;

  uint32_t remainder = __umodsi3((uint32_t)dividend, (uint32_t)divisor);

  return negative ? -(int32_t)remainder : (int32_t)remainder;
}
