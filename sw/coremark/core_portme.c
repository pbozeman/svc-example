/*
 * CoreMark port for svc-example RISC-V bare-metal environment
 */
#include <stdarg.h>

#include "coremark.h"
#include "core_portme.h"
#include "libsvc/csr.h"
#include "libsvc/stdio.h"

/* Volatile seeds for CoreMark */
#if VALIDATION_RUN
volatile ee_s32 seed1_volatile = 0x3415;
volatile ee_s32 seed2_volatile = 0x3415;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PERFORMANCE_RUN
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PROFILE_RUN
volatile ee_s32 seed1_volatile = 0x8;
volatile ee_s32 seed2_volatile = 0x8;
volatile ee_s32 seed3_volatile = 0x8;
#endif

volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;

/*
 * Clock frequency - 25MHz for simulation
 * For accurate results, this must match actual clock frequency
 */
#ifndef CLOCKS_PER_SEC
#define CLOCKS_PER_SEC 25000000
#endif

#define TIMER_RES_DIVIDER 1
#define EE_TICKS_PER_SEC  (CLOCKS_PER_SEC / TIMER_RES_DIVIDER)
#define GETMYTIME(_t)     (*_t = (CORETIMETYPE)rdcycle())
#define MYTIMEDIFF(fin, ini) ((fin) - (ini))

/* Time measurement variables */
static CORETIMETYPE start_time_val, stop_time_val;

/* Number of contexts (single-threaded) */
ee_u32 default_num_contexts = 1;

/*
 * Start timing measurement
 */
void start_time(void) {
  GETMYTIME(&start_time_val);
}

/*
 * Stop timing measurement
 */
void stop_time(void) {
  GETMYTIME(&stop_time_val);
}

/*
 * Get elapsed time in ticks
 */
CORE_TICKS get_time(void) {
  CORE_TICKS elapsed =
      (CORE_TICKS)(MYTIMEDIFF(stop_time_val, start_time_val));
  return elapsed;
}

/*
 * Convert ticks to seconds
 * With HAS_FLOAT=0, secs_ret is ee_u32, so this returns integer seconds
 */
secs_ret time_in_secs(CORE_TICKS ticks) {
  secs_ret retval = ((secs_ret)ticks) / (secs_ret)EE_TICKS_PER_SEC;
  return retval;
}

/*
 * Target-specific initialization
 */
void portable_init(core_portable *p, int *argc, char *argv[]) {
  (void)argc;
  (void)argv;

  if (sizeof(ee_ptr_int) != sizeof(ee_u8 *)) {
    ee_printf(
        "ERROR! Please define ee_ptr_int to a type that holds a pointer!\n");
  }
  if (sizeof(ee_u32) != 4) {
    ee_printf("ERROR! Please define ee_u32 to a 32b unsigned type!\n");
  }
  p->portable_id = 1;
}

/*
 * Target-specific cleanup
 */
void portable_fini(core_portable *p) {
  p->portable_id = 0;
}

/*
 * ee_printf - wrapper around libsvc vprintf
 * CoreMark requires this function even when HAS_PRINTF=1
 */
int ee_printf(const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int ret = vprintf(fmt, args);
  va_end(args);
  return ret;
}
