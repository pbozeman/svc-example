#include "util.h"

//
// Halt the processor
//
void svc_halt(void) {
  while (1) {
    __asm__ volatile("ebreak");
  }
}

//
// Simple delay loop
//
void svc_delay(uint32_t count) {
  for (volatile uint32_t i = 0; i < count; i++) {
    // Busy wait
  }
}
