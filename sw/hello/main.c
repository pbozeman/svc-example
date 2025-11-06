#include "stdio.h"
#include "uart.h"
#include "util.h"

//
// Main hello world program
//
// Demonstrates libsvc standard I/O functions: putchar() and puts()
//
int main(void) {
  // Print greeting using puts() - automatically adds newline
  puts("Hello, World!");
  puts("Greetings from libsvc!");

  // Demonstrate putchar() - print a simple message character by character
  putchar('O');
  putchar('K');
  putchar('\n');

  // Wait for UART to finish transmitting before halting
  svc_uart_flush();

  // Halt the processor
  svc_halt();

  return 0;
}
