/*
 * CoreMark port for svc-example RISC-V bare-metal environment
 */
#include <stdarg.h>

#include "coremark.h"
#include "core_portme.h"
#include "libsvc/csr.h"
#include "libsvc/stdio.h"
#include "libsvc/sys.h"

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
 * Clock frequency - read from hardware at runtime
 *
 * The system clock frequency is read from the MMIO clock frequency register.
 * This allows the same binary to report accurate results regardless of the
 * actual clock speed (simulation vs FPGA).
 */
#define TIMER_RES_DIVIDER 1
#define GETMYTIME(_t)     (*_t = (CORETIMETYPE)rdcycle())
#define MYTIMEDIFF(fin, ini) ((fin) - (ini))

/* Clock frequency cached from hardware */
static uint32_t cached_clock_freq = 0;

/* Time measurement variables */
static CORETIMETYPE start_time_val, stop_time_val;

/* Saved for final report */
static uint32_t saved_iterations = 0;

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
  /* Save iterations for final report - seed4_volatile holds ITERATIONS */
  saved_iterations = (uint32_t)seed4_volatile;
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
 * Get ticks per second (clock frequency / timer divider)
 */
static uint32_t get_ticks_per_sec(void) {
  return cached_clock_freq / TIMER_RES_DIVIDER;
}

/*
 * Convert ticks to seconds
 * With HAS_FLOAT=0, secs_ret is ee_u32, so this returns integer seconds
 */
secs_ret time_in_secs(CORE_TICKS ticks) {
  secs_ret retval = ((secs_ret)ticks) / (secs_ret)get_ticks_per_sec();
  return retval;
}

/*
 * Target-specific initialization
 */
void portable_init(core_portable *p, int *argc, char *argv[]) {
  (void)argc;
  (void)argv;

  /* Read clock frequency from hardware */
  cached_clock_freq = svc_clock_freq();

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
 *
 * Print CoreMark/MHz for easy comparison across different clock frequencies.
 */
void portable_fini(core_portable *p) {
  p->portable_id = 0;

  /* Calculate and print CoreMark/MHz */
  if (saved_iterations > 0 && cached_clock_freq > 0) {
    CORE_TICKS elapsed = get_time();
    uint32_t mhz = cached_clock_freq / 1000000;

    /*
     * CoreMark/MHz = (iterations / seconds) / MHz
     *              = iterations / (seconds * MHz)
     *              = iterations / (elapsed_ticks / clock_freq * MHz)
     *              = iterations / (elapsed_ticks / (clock_freq / MHz))
     *              = iterations / (elapsed_ticks / 1000000)
     *              = (iterations * 1000000) / elapsed_ticks
     *
     * To get 2 decimal places, multiply by 100 first:
     * result_x100 = (iterations * 100 * 1000000) / elapsed_ticks
     *             = (iterations * 100000000) / elapsed_ticks
     *
     * For 100 iterations with ~400M cycles:
     * = 100 * 100000000 / 400000000 = 25 (i.e., 0.25 CM/MHz)
     *
     * To avoid 64-bit division, we can do this in steps using 32-bit ops
     * since elapsed >> iterations typically.
     *
     * elapsed_per_iter = elapsed / iterations
     * cm_mhz_x100 = 100000000 / elapsed_per_iter
     */
    uint32_t elapsed_per_iter = elapsed / saved_iterations;
    uint32_t cm_mhz_x100 = 100000000 / elapsed_per_iter;
    uint32_t cm_mhz_int = cm_mhz_x100 / 100;
    uint32_t cm_mhz_frac = cm_mhz_x100 % 100;

    ee_printf("\n");
    ee_printf("Clock frequency  : %d MHz\n", mhz);
    ee_printf("CoreMark/MHz     : %d.%02d\n", cm_mhz_int, cm_mhz_frac);
  }
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
