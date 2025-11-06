#include "mmio.h"
#include "util.h"

//
// Memory-mapped LED register offset
//
// LED output is at MMIO_BASE + 0x08
//
#define LED_OFFSET 0x08

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
    svc_delay(1000);
  }

  return 0;
}
