#ifndef LIBSVC_UART_H
#define LIBSVC_UART_H

//
// UART Hardware Layer
//
// Low-level UART I/O functions for SVC RISC-V SoC
//

//
// Check if UART TX is busy
//
// Returns:
//   1 if TX is busy (not ready to accept a new character)
//   0 if TX is ready
//
int svc_uart_tx_busy(void);

//
// Send a single character via UART
//
// This is the foundational putchar function. It waits for the UART
// TX to be ready, then writes the character.
//
// Args:
//   c: Character to transmit
//
void svc_uart_putc(char c);

//
// Send a null-terminated string via UART
//
// Args:
//   s: Pointer to null-terminated string
//
void svc_uart_puts(const char *s);

//
// Wait for UART TX to finish transmitting
//
// After writing the last character, wait for it to finish
// transmitting over the serial line before proceeding.
//
void svc_uart_flush(void);

#endif  // LIBSVC_UART_H
