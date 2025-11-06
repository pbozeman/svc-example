#include "stdio.h"

#include <stddef.h>
#include <stdint.h>

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
  svc_uart_putc('\n');    // Append newline per C standard
  svc_uart_flush();       // Flush after newline (line-buffered behavior)
  return 0;               // Success
}

//
// Print unsigned integer in given base
//
// Helper function to convert unsigned integer to string and output
//
static int print_uint(uint32_t value, int base, int uppercase) {
  char buf[32];  // Large enough for 32-bit int in any base
  int pos = 0;
  int count = 0;
  const char *digits =
      uppercase ? "0123456789ABCDEF" : "0123456789abcdef";

  // Handle zero specially
  if (value == 0) {
    svc_uart_putc('0');
    return 1;
  }

  // Convert to string (reversed)
  while (value > 0) {
    buf[pos++] = digits[value % base];
    value /= base;
  }

  // Output in correct order
  while (pos > 0) {
    svc_uart_putc(buf[--pos]);
    count++;
  }

  return count;
}

//
// Print signed integer
//
static int print_int(int32_t value) {
  int count = 0;

  if (value < 0) {
    svc_uart_putc('-');
    count++;
    value = -value;
  }

  count += print_uint((uint32_t)value, 10, 0);
  return count;
}

//
// Formatted output to standard output
//
int printf(const char *fmt, ...) {
  va_list args;
  int count = 0;
  const char *p = fmt;
  int has_newline = 0;

  va_start(args, fmt);

  while (*p) {
    if (*p == '%') {
      p++;  // Skip '%'

      // Handle format specifiers
      switch (*p) {
        case 'd':  // Signed decimal
        {
          int32_t val = va_arg(args, int32_t);
          count += print_int(val);
          break;
        }

        case 'u':  // Unsigned decimal
        {
          uint32_t val = va_arg(args, uint32_t);
          count += print_uint(val, 10, 0);
          break;
        }

        case 'x':  // Lowercase hex
        {
          uint32_t val = va_arg(args, uint32_t);
          count += print_uint(val, 16, 0);
          break;
        }

        case 'X':  // Uppercase hex
        {
          uint32_t val = va_arg(args, uint32_t);
          count += print_uint(val, 16, 1);
          break;
        }

        case 's':  // String
        {
          const char *str = va_arg(args, const char *);
          if (str == NULL) {
            str = "(null)";
          }
          while (*str) {
            if (*str == '\n') {
              has_newline = 1;
            }
            svc_uart_putc(*str++);
            count++;
          }
          break;
        }

        case 'c':  // Character
        {
          char c = (char)va_arg(args, int);
          if (c == '\n') {
            has_newline = 1;
          }
          svc_uart_putc(c);
          count++;
          break;
        }

        case '%':  // Literal '%'
          svc_uart_putc('%');
          count++;
          break;

        default:
          // Unknown format specifier - print as-is
          svc_uart_putc('%');
          svc_uart_putc(*p);
          count += 2;
          break;
      }
      p++;
    } else {
      // Regular character
      if (*p == '\n') {
        has_newline = 1;
      }
      svc_uart_putc(*p++);
      count++;
    }
  }

  // Flush if we printed a newline (line-buffered behavior)
  if (has_newline) {
    svc_uart_flush();
  }

  va_end(args);
  return count;
}
