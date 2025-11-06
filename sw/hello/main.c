#include "mmio.h"

//
// UART register offsets
//
// UART TX data register at MMIO_BASE + 0x00
// UART status register at MMIO_BASE + 0x04 (bit 0 = TX ready)
//
#define UART_TX_OFFSET 0x00
#define UART_STATUS_OFFSET 0x04

//
// Halt the processor by calling ebreak in a loop
//
static void halt(void) {
  while (1) {
    __asm__ volatile("ebreak");
  }
}

//
// Check if UART TX is busy
//
static int uart_tx_busy(void) {
  // TX is busy if ready bit (bit 0) is 0
  return (mmio_read(UART_STATUS_OFFSET) & 0x1) == 0;
}

//
// Send a single character via UART
//
static void uart_putc(char c) {
  // Wait until UART TX is ready
  while (uart_tx_busy()) {
    // Busy wait
  }

  // Write character to TX register
  mmio_write(UART_TX_OFFSET, (uint32_t)c);
}

//
// Send a string via UART
//
static void uart_puts(const char *str) {
  while (*str) {
    uart_putc(*str);
    str++;
  }
}

//
// Wait for UART TX to finish transmitting
//
// The uart_putc function waits for TX ready before writing, which means
// the TX register is empty and ready to accept a new character. However,
// after writing the last character, we need to wait for it to finish
// transmitting over the serial line. We do this by waiting for TX ready
// again, which indicates the character has been transmitted.
//
static void uart_flush(void) {
  while (uart_tx_busy())
    ;
}

//
// Main hello world program
//
// Prints "Hello, World!" via UART then halts
//
int main(void) {
  // Print greeting
  uart_puts("Hello, World!\nGreetings!\n");

  // Wait for UART to finish transmitting before halting
  uart_flush();

  // Halt the processor
  halt();

  return 0;
}
