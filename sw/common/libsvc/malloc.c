#include "libsvc/malloc.h"

//
// Simple bump allocator - no free support
//
// Heap is a static buffer. malloc() bumps the heap_pos pointer forward,
// free() does nothing. This is sufficient for programs like Dhrystone
// that allocate a few objects at startup and never free them.
//

// Static heap buffer (4KB)
static char heap[4096] __attribute__((aligned(4)));
static size_t heap_pos = 0;

//
// Allocate size bytes from heap
//
void* malloc(size_t size) {
  // 4-byte alignment
  size = (size + 3) & ~3;

  if (heap_pos + size > sizeof(heap)) {
    return NULL;  // Out of memory
  }

  void* ptr = &heap[heap_pos];
  heap_pos += size;
  return ptr;
}

//
// Free memory (no-op - bump allocator doesn't support free)
//
void free(void* ptr) {
  // No-op - bump allocator doesn't support free
  (void)ptr;
}
