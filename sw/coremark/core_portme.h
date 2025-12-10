/*
 * CoreMark port for svc-example RISC-V bare-metal environment
 */
#ifndef CORE_PORTME_H
#define CORE_PORTME_H

#include <stddef.h>
#include <stdint.h>

/* Data types and settings */

/* No floating point needed for CoreMark */
#ifndef HAS_FLOAT
#define HAS_FLOAT 0
#endif

/* No time.h in bare-metal */
#ifndef HAS_TIME_H
#define HAS_TIME_H 0
#endif

#ifndef USE_CLOCK
#define USE_CLOCK 0
#endif

/* No standard stdio.h - we provide our own via libsvc */
#ifndef HAS_STDIO
#define HAS_STDIO 0
#endif

/* We provide ee_printf, so don't map it to printf */
#ifndef HAS_PRINTF
#define HAS_PRINTF 0
#endif

/* Compiler version and flags */
#ifndef COMPILER_VERSION
#ifdef __GNUC__
#define COMPILER_VERSION "GCC" __VERSION__
#else
#define COMPILER_VERSION "Unknown"
#endif
#endif

#ifndef COMPILER_FLAGS
#define COMPILER_FLAGS FLAGS_STR
#endif

#ifndef MEM_LOCATION
#define MEM_LOCATION "STACK"
#endif

/* Data types for 32-bit RISC-V */
typedef int16_t  ee_s16;
typedef uint16_t ee_u16;
typedef int32_t  ee_s32;
typedef double   ee_f32;
typedef uint8_t  ee_u8;
typedef uint32_t ee_u32;
typedef uint32_t ee_ptr_int;
typedef size_t   ee_size_t;

#define NULL ((void *)0)

/* Align to 32-bit boundary */
#define align_mem(x) (void *)(4 + (((ee_ptr_int)(x)-1) & ~3))

/* Timing type - use 32-bit cycle count */
#define CORETIMETYPE ee_u32
typedef ee_u32 CORE_TICKS;

/* Seed method - use volatile variables */
#ifndef SEED_METHOD
#define SEED_METHOD SEED_VOLATILE
#endif

/* Memory method - use stack allocation */
#ifndef MEM_METHOD
#define MEM_METHOD MEM_STACK
#endif

/* Single thread only */
#ifndef MULTITHREAD
#define MULTITHREAD 1
#define USE_PTHREAD 0
#define USE_FORK    0
#define USE_SOCKET  0
#endif

/* No argc/argv support */
#ifndef MAIN_HAS_NOARGC
#define MAIN_HAS_NOARGC 1
#endif

/* main returns int */
#ifndef MAIN_HAS_NORETURN
#define MAIN_HAS_NORETURN 0
#endif

/* Number of contexts */
extern ee_u32 default_num_contexts;

/* Portable structure */
typedef struct CORE_PORTABLE_S {
  ee_u8 portable_id;
} core_portable;

/* Target specific init/fini */
void portable_init(core_portable *p, int *argc, char *argv[]);
void portable_fini(core_portable *p);

/* Run type selection based on TOTAL_DATA_SIZE */
#if !defined(PROFILE_RUN) && !defined(PERFORMANCE_RUN) && \
    !defined(VALIDATION_RUN)
#if (TOTAL_DATA_SIZE == 1200)
#define PROFILE_RUN 1
#elif (TOTAL_DATA_SIZE == 2000)
#define PERFORMANCE_RUN 1
#else
#define VALIDATION_RUN 1
#endif
#endif

/* Printf replacement */
int ee_printf(const char *fmt, ...);

#endif /* CORE_PORTME_H */
