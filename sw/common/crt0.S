.section .text.start
.global _start

_start:
    # Initialize stack pointer at end of data memory (2KB = 0x800)
    # Adjust based on actual DMEM size
    li sp, 0x800

    # Zero out .bss section (if needed in future)
    # For now, skip - blinky doesn't need it

    # Call main function
    call main

    # When main returns, trigger ebreak
    ebreak

    # Infinite loop (should never reach here)
1:
    j 1b
