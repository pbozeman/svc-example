#include "mmio.h"

//
// Memory-mapped LED register offset
//
// Assumes LED output is at MMIO_BASE + 0x00
//
#define LED_OFFSET 0x00

//
// Simple delay loop
//
// Note: This is not cycle-accurate. Adjust count based on clock frequency.
//
static void delay(uint32_t count) {
  for (volatile uint32_t i = 0; i < count; i++) {
    // Busy wait
  }
}

//
// Main blinky program
//
// Toggles LED via memory-mapped I/O
//
int main(void) {
  uint32_t led_state = 0;

  while (1) {
    // Write current LED state
    mmio_write(LED_OFFSET, led_state);

    // Toggle LED state
    led_state = ~led_state;

    // Delay
    delay(100000);
  }

  return 0;
}
