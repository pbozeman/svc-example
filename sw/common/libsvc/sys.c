#include "sys.h"

#include "mmio.h"

//
// System register offsets
//
// Clock frequency register at MMIO_BASE + 0x10
//
#define SYS_CLOCK_FREQ_OFFSET 0x10

//
// Get the system clock frequency in Hz
//
uint32_t svc_clock_freq(void) {
  return mmio_read(SYS_CLOCK_FREQ_OFFSET);
}
