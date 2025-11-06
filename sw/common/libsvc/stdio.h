#ifndef LIBSVC_STDIO_H
#define LIBSVC_STDIO_H

#include <stdarg.h>

//
// Standard I/O Functions
//
// Provides standard C library I/O function names that wrap the
// underlying UART hardware layer.
//

//
// Write a character to standard output
//
// This is the standard C library putchar() function. It writes
// a single character to stdout (UART in our case).
//
// Args:
//   c: Character to write (passed as int per C standard)
//
// Returns:
//   The character written, or EOF on error (we always succeed)
//
int putchar(int c);

//
// Write a string to standard output with newline
//
// This is the standard C library puts() function. It writes
// a null-terminated string to stdout (UART) and automatically
// appends a newline character ('\n').
//
// Args:
//   s: Pointer to null-terminated string
//
// Returns:
//   Non-negative value on success, EOF on error (we always succeed)
//
int puts(const char *s);

//
// Formatted output to standard output
//
// Minimal printf implementation supporting:
//   %d - signed decimal integer
//   %u - unsigned decimal integer
//   %x - lowercase hexadecimal
//   %X - uppercase hexadecimal
//   %s - null-terminated string
//   %c - single character
//   %% - literal '%'
//
// Note: No field width, precision, or padding flags.
//
// Args:
//   fmt: Format string
//   ...: Variable arguments matching format specifiers
//
// Returns:
//   Number of characters written
//
int printf(const char *fmt, ...);

#endif  // LIBSVC_STDIO_H
