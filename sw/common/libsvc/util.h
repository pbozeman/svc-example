#ifndef LIBSVC_UTIL_H
#define LIBSVC_UTIL_H

#include <stdint.h>

//
// Utility Functions
//
// Common utility functions for SVC RISC-V SoC
//

//
// Halt the processor
//
// Triggers ebreak in an infinite loop. This signals program
// completion to testbenches and prevents further execution.
//
void svc_halt(void) __attribute__((noreturn));

//
// Simple delay loop
//
// Note: This is not cycle-accurate. The actual delay depends on
// clock frequency and compiler optimization. Adjust count based
// on your target hardware.
//
// Args:
//   count: Number of iterations to delay
//
void svc_delay(uint32_t count);

#endif  // LIBSVC_UTIL_H
