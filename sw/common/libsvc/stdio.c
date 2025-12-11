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
// Print unsigned integer in given base with optional width and zero-padding
//
// Helper function to convert unsigned integer to string and output
//
static int print_uint(uint32_t value, int base, int uppercase, int width,
                      int zero_pad) {
  char buf[32];  // Large enough for 32-bit int in any base
  int pos = 0;
  int count = 0;
  const char *digits =
      uppercase ? "0123456789ABCDEF" : "0123456789abcdef";

  // Convert to string (reversed)
  if (value == 0) {
    buf[pos++] = '0';
  } else {
    while (value > 0) {
      buf[pos++] = digits[value % base];
      value /= base;
    }
  }

  // Add padding if needed
  char pad_char = zero_pad ? '0' : ' ';
  while (pos < width) {
    buf[pos++] = pad_char;
  }

  // Output in correct order
  while (pos > 0) {
    svc_uart_putc(buf[--pos]);
    count++;
  }

  return count;
}

//
// Print signed integer with optional width and zero-padding
//
static int print_int(int32_t value, int width, int zero_pad) {
  int count = 0;

  if (value < 0) {
    svc_uart_putc('-');
    count++;
    value = -value;
    // Reduce width by 1 for the minus sign
    if (width > 0) width--;
  }

  count += print_uint((uint32_t)value, 10, 0, width, zero_pad);
  return count;
}

//
// Formatted output with va_list
//
int vprintf(const char *fmt, va_list args) {
  int count = 0;
  const char *p = fmt;
  int has_newline = 0;

  while (*p) {
    if (*p == '%') {
      p++;  // Skip '%'

      // Parse optional flags and width
      int zero_pad = 0;
      int width = 0;

      // Check for '0' flag (zero-padding)
      if (*p == '0') {
        zero_pad = 1;
        p++;
      }

      // Parse width (digits)
      while (*p >= '0' && *p <= '9') {
        width = width * 10 + (*p - '0');
        p++;
      }

      // Parse length modifier (l, ll - ignored on 32-bit, sizes are same)
      while (*p == 'l') {
        p++;
      }

      // Handle format specifiers
      switch (*p) {
        case 'd':  // Signed decimal
        {
          int32_t val = va_arg(args, int32_t);
          count += print_int(val, width, zero_pad);
          break;
        }

        case 'u':  // Unsigned decimal
        {
          uint32_t val = va_arg(args, uint32_t);
          count += print_uint(val, 10, 0, width, zero_pad);
          break;
        }

        case 'x':  // Lowercase hex
        {
          uint32_t val = va_arg(args, uint32_t);
          count += print_uint(val, 16, 0, width, zero_pad);
          break;
        }

        case 'X':  // Uppercase hex
        {
          uint32_t val = va_arg(args, uint32_t);
          count += print_uint(val, 16, 1, width, zero_pad);
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

  return count;
}

//
// Formatted output to standard output
//
int printf(const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int count = vprintf(fmt, args);
  va_end(args);
  return count;
}
