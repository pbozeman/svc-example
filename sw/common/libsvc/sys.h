#ifndef LIBSVC_SYS_H
#define LIBSVC_SYS_H

#include <stdint.h>

//
// System Information Layer
//
// Functions to read system configuration from hardware registers
//

//
// Get the system clock frequency in Hz
//
// Returns the clock frequency that the SoC is running at,
// as configured by the hardware.
//
uint32_t svc_clock_freq(void);

#endif  // LIBSVC_SYS_H
