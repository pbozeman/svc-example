#ifndef CSR_H
#define CSR_H

#include <stdint.h>

//
// RISC-V CSR (Control and Status Register) access functions
//
// Provides inline assembly functions for reading cycle counters and other CSRs
// using the Zicsr extension (rv32i_zicsr).
//

//
// Read lower 32 bits of cycle counter
//
static inline uint32_t rdcycle(void) {
  uint32_t val;
  asm volatile("rdcycle %0" : "=r"(val));
  return val;
}

//
// Read upper 32 bits of cycle counter
//
static inline uint32_t rdcycleh(void) {
  uint32_t val;
  asm volatile("rdcycleh %0" : "=r"(val));
  return val;
}

//
// Read lower 32 bits of instruction counter
//
static inline uint32_t rdinstret(void) {
  uint32_t val;
  asm volatile("rdinstret %0" : "=r"(val));
  return val;
}

//
// Read upper 32 bits of instruction counter
//
static inline uint32_t rdinstreth(void) {
  uint32_t val;
  asm volatile("rdinstreth %0" : "=r"(val));
  return val;
}

//
// Read 64-bit cycle counter atomically
//
// Handles potential rollover of lower 32 bits by reading high twice
// and retrying if it changes between reads.
//
static inline uint64_t read_cycles(void) {
  uint32_t hi, lo;
  // Read high, low, high again to detect rollover
  do {
    hi = rdcycleh();
    lo = rdcycle();
  } while (hi != rdcycleh());
  return ((uint64_t)hi << 32) | lo;
}

//
// Read 64-bit instruction counter atomically
//
static inline uint64_t read_instret(void) {
  uint32_t hi, lo;
  // Read high, low, high again to detect rollover
  do {
    hi = rdinstreth();
    lo = rdinstret();
  } while (hi != rdinstreth());
  return ((uint64_t)hi << 32) | lo;
}

#endif  // CSR_H
