OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  /* Harvard architecture: separate instruction and data spaces */
  /* Both start at 0x00000000 in their respective address spaces */
  IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 8K
  DMEM (rw)  : ORIGIN = 0x00000000, LENGTH = 16K
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
    *(.rodata*)
  } > IMEM

  /* Initialized data */
  .data : {
    *(.data*)
  } > DMEM

  /* Uninitialized data */
  .bss : {
    __bss_start = .;
    *(.bss*)
    *(COMMON)
    __bss_end = .;
  } > DMEM

  /* Stack grows down from end of DMEM */
  PROVIDE(__stack_top = ORIGIN(DMEM) + LENGTH(DMEM));
}
