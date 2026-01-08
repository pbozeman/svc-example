#include <stdio.h>

#include "libsvc/uart.h"

int main(void) {
  char c;

  printf("Echo with toupper:\n");

  while (1) {
    c = svc_uart_getc();

    // Uppercase if lowercase to prove C code processed it
    if (c >= 'a' && c <= 'z') {
      c = c - 'a' + 'A';
    }

    svc_uart_putc(c);

    if (c == 0x04) {
      break;
    }
  }

  printf("\n");
  return 0;
}
