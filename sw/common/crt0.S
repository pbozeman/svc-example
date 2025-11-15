.section .text.start
.global _start

_start:
    # Initialize stack pointer at end of data memory
    la sp, __stack_top

    # Zero out .bss section
    la a0, __bss_start
    la a1, __bss_end
    bge a0, a1, bss_done
clear_bss:
    sw zero, 0(a0)
    addi a0, a0, 4
    blt a0, a1, clear_bss
bss_done:

    # Call main function
    call main

    # When main returns, trigger ebreak
    ebreak

    # Infinite loop (should never reach here)
halt:
    j halt
