#ifndef MMIO_H
#define MMIO_H

#include <stdint.h>

//
// Memory-mapped I/O base addresses
//
// I/O space starts at 0x80000000 (bit 31 set)
//
#define MMIO_BASE 0x80000000

//
// Helper macros for memory-mapped I/O
//
#define MMIO_REG(offset) (*(volatile uint32_t *)(MMIO_BASE + (offset)))

//
// Write to memory-mapped register
//
static inline void mmio_write(uint32_t offset, uint32_t value) {
  MMIO_REG(offset) = value;
}

//
// Read from memory-mapped register
//
static inline uint32_t mmio_read(uint32_t offset) {
  return MMIO_REG(offset);
}

//
// Device-specific offsets (to be defined per application)
//
// Example for blinky:
// #define LED_OFFSET 0x00
//
// Example for UART:
// #define UART_TX_OFFSET  0x00
// #define UART_RX_OFFSET  0x04
// #define UART_STATUS_OFFSET 0x08
//

#endif  // MMIO_H
