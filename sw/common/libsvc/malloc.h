#ifndef MALLOC_H
#define MALLOC_H

#include <stddef.h>

//
// Simple memory allocation for bare-metal RISC-V programs
//
// Uses a bump allocator - allocations always succeed (until heap exhausted),
// but free() is a no-op. Suitable for programs that allocate at startup
// and never free, like Dhrystone.
//

//
// Allocate size bytes of memory
// Returns pointer to allocated memory, or NULL if out of memory
// Memory is 4-byte aligned
//
void* malloc(size_t size);

//
// Free allocated memory (no-op for bump allocator)
//
void free(void* ptr);

#endif  // MALLOC_H
