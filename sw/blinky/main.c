#include "libsvc/sys.h"

#include "mmio.h"
#include "util.h"

#define LED_OFFSET 0x08

int main(void) {
  uint32_t led_state = 0;
  uint32_t freq = svc_clock_freq();

  while (1) {
    mmio_write(LED_OFFSET, led_state);
    led_state = ~led_state;
    svc_delay(freq / 8);
  }

  return 0;
}
