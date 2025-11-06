#include "uart.h"

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
// Check if UART TX is busy
//
int svc_uart_tx_busy(void) {
  // TX is busy if ready bit (bit 0) is 0
  return (mmio_read(UART_STATUS_OFFSET) & 0x1) == 0;
}

//
// Send a single character via UART
//
void svc_uart_putc(char c) {
  // Wait until UART TX is ready
  while (svc_uart_tx_busy()) {
    // Busy wait
  }

  // Write character to TX register
  mmio_write(UART_TX_OFFSET, (uint32_t)c);
}

//
// Send a null-terminated string via UART
//
void svc_uart_puts(const char *s) {
  while (*s) {
    svc_uart_putc(*s);
    s++;
  }
}

//
// Wait for UART TX to finish transmitting
//
void svc_uart_flush(void) {
  while (svc_uart_tx_busy())
    ;
}
