#include "stdio.h"

//
// Main hello world program
//
// Demonstrates libsvc standard I/O functions: putchar(), puts(), and printf()
//
int main(void) {
  // Greeting with puts()
  puts("--- libsvc printf() demo ---");
  puts("");

  // Test %s (string)
  printf("String: %s\n", "Hello, World!");

  // Test %c (character)
  printf("Character: %c\n", 'A');

  // Test %d (signed decimal)
  printf("Signed decimal: %d\n", -42);
  printf("Positive: %d\n", 12345);
  printf("Zero: %d\n", 0);

  // Test %u (unsigned decimal)
  printf("Unsigned: %u\n", 4294967295u); // Max uint32_t

  // Test %x (lowercase hex)
  printf("Hex (lower): 0x%x\n", 0xdeadbeef);

  // Test %X (uppercase hex)
  printf("Hex (upper): 0x%X\n", 0xCAFEBABE);

  // Test %% (literal percent)
  printf("Percent: 100%%\n");

  // Mixed format test
  printf("Mixed: val=%d, hex=0x%x, str=%s\n", 42, 0x2a, "same!");

  puts("");
  puts("--- Test complete ---");

  return 0;
}
