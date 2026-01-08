OUTPUT_ARCH("riscv")
ENTRY(_start)

/* Memory sizes provided by Makefile via --defsym */
/* Defaults only used if not provided (should not happen in normal builds) */
__imem_size = DEFINED(__imem_size) ? __imem_size : 40960;  /* 10KB default */
__dmem_size = DEFINED(__dmem_size) ? __dmem_size : 16384;  /* 16KB default */

MEMORY
{
  /* Harvard architecture: separate instruction and data spaces */
  /* Both start at 0x00000000 in their respective address spaces */
  IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = __imem_size
  DMEM (rw)  : ORIGIN = 0x00000000, LENGTH = __dmem_size
}

SECTIONS
{
  /* Code section goes to instruction memory */
  .text : {
    *(.text.start)    /* Startup code first */
    *(.text*)         /* All other code */
  } > IMEM

  /* Read-only data (constants) */
  .rodata : {
    *(.srodata*)
    *(.rodata*)
  } > IMEM

  /* Reserve space in DMEM for .text and .rodata loaded from hex file.
     Since both IMEM and DMEM are initialized with the same hex file
     (to allow reading .rodata constants from DMEM in Harvard architecture),
     we need to account for this when placing .data and .bss in DMEM. */
  .imem_mirror (NOLOAD) : {
    . = SIZEOF(.text) + SIZEOF(.rodata);
  } > DMEM

  /* Initialized data */
  .data : {
    *(.data*)
    *(.sdata*)
  } > DMEM

  /* Uninitialized data */
  .bss : {
    __bss_start = .;
    *(.sbss*)
    *(.bss*)
    *(COMMON)
    __bss_end = .;
  } > DMEM

  /* Heap starts after BSS, grows up toward stack */
  PROVIDE(__heap_start = __bss_end);

  /* Stack grows down from end of DMEM */
  PROVIDE(__stack_top = ORIGIN(DMEM) + LENGTH(DMEM));

  /* Heap ends where stack begins (reserve 1KB for stack minimum) */
  PROVIDE(__heap_end = __stack_top - 1024);
}
