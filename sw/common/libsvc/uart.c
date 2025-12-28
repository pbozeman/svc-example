#include "uart.h"

#ifndef SVC_DISABLE_MMIO

#include "mmio.h"

//
// UART register offsets
//
// UART TX data register at MMIO_BASE + 0x00
// UART TX status register at MMIO_BASE + 0x04 (bit 0 = TX ready)
// UART RX data register at MMIO_BASE + 0x14 (read clears valid)
// UART RX status register at MMIO_BASE + 0x18 (bit 0 = data available)
//
#define UART_TX_OFFSET 0x00
#define UART_TX_STATUS_OFFSET 0x04
#define UART_RX_OFFSET 0x14
#define UART_RX_STATUS_OFFSET 0x18

//
// Check if UART TX is busy
//
int svc_uart_tx_busy(void) {
  // TX is busy if ready bit (bit 0) is 0
  return (mmio_read(UART_TX_STATUS_OFFSET) & 0x1) == 0;
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

//
// Check if UART RX has data available
//
int svc_uart_rx_ready(void) {
  return (mmio_read(UART_RX_STATUS_OFFSET) & 0x1) != 0;
}

//
// Receive a single character via UART (blocking)
//
char svc_uart_getc(void) {
  // Wait until data is available
  while (!svc_uart_rx_ready()) {
    // Busy wait
  }

  // Read and return the character (read clears valid)
  return (char)(mmio_read(UART_RX_OFFSET) & 0xFF);
}

//
// Receive a single character via UART (non-blocking)
//
int svc_uart_getc_nb(void) {
  if (!svc_uart_rx_ready()) {
    return -1;
  }

  // Read and return the character (read clears valid)
  return (int)(mmio_read(UART_RX_OFFSET) & 0xFF);
}

#else  // SVC_DISABLE_MMIO

//
// Silent I/O mode - all UART operations are no-ops with deterministic values
//

int svc_uart_tx_busy(void) {
  return 0;
}

void svc_uart_putc(char c) {
  (void)c;
}

void svc_uart_puts(const char *s) {
  (void)s;
}

void svc_uart_flush(void) {
}

int svc_uart_rx_ready(void) {
  return 0;
}

char svc_uart_getc(void) {
  return 0;
}

int svc_uart_getc_nb(void) {
  return 0;
}

#endif  // SVC_DISABLE_MMIO
