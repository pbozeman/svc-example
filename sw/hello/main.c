#include "uart.h"
#include "util.h"

//
// Main hello world program
//
// Prints "Hello, World!" via UART then halts
//
int main(void) {
  // Print greeting
  svc_uart_puts("Hello, World!\nGreetings!\n");

  // Wait for UART to finish transmitting before halting
  svc_uart_flush();

  // Halt the processor
  svc_halt();

  return 0;
}
