#include "stdio.h"

#include "uart.h"

//
// Write a character to standard output
//
int putchar(int c) {
  svc_uart_putc((char)c);
  return c;
}

//
// Write a string to standard output with newline
//
int puts(const char *s) {
  svc_uart_puts(s);
  svc_uart_putc('\n');  // Append newline per C standard
  return 0;              // Success
}
