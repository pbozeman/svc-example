//
// Picolibc syscall stubs for SVC RISC-V SoC
//
// Implements minimal POSIX syscalls required by picolibc, with UART-based I/O.
//

#include <errno.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>

#include "libsvc/csr.h"
#include "libsvc/sys.h"
#include "libsvc/uart.h"

// Heap bounds from linker script
extern char __heap_start;
extern char __heap_end;

//
// Write to file descriptor (UART for stdout/stderr)
//
ssize_t write(int fd, const void *buf, size_t count) {
  if (fd != STDOUT_FILENO && fd != STDERR_FILENO) {
    errno = EBADF;
    return -1;
  }

  const char *p = (const char *)buf;
  for (size_t i = 0; i < count; i++) {
    svc_uart_putc(p[i]);
  }

  return (ssize_t)count;
}

//
// Read from file descriptor (UART for stdin)
//
ssize_t read(int fd, void *buf, size_t count) {
  if (fd != STDIN_FILENO) {
    errno = EBADF;
    return -1;
  }

  char *p = (char *)buf;
  for (size_t i = 0; i < count; i++) {
    p[i] = svc_uart_getc();
  }

  return (ssize_t)count;
}

//
// Extend heap for malloc
//
void *sbrk(ptrdiff_t incr) {
  static char *heap_ptr = NULL;

  if (heap_ptr == NULL) {
    heap_ptr = &__heap_start;
  }

  char *prev_heap = heap_ptr;
  char *new_heap  = heap_ptr + incr;

  if (new_heap > &__heap_end) {
    errno = ENOMEM;
    return (void *)-1;
  }

  heap_ptr = new_heap;
  return prev_heap;
}

//
// Close file descriptor (stub)
//
int close(int fd) {
  (void)fd;
  errno = EBADF;
  return -1;
}

//
// Seek in file (stub)
//
off_t lseek(int fd, off_t offset, int whence) {
  (void)fd;
  (void)offset;
  (void)whence;
  errno = ESPIPE;
  return -1;
}

//
// Get file status (stub - report as character device)
//
int fstat(int fd, struct stat *st) {
  if (fd >= STDIN_FILENO && fd <= STDERR_FILENO) {
    st->st_mode = S_IFCHR;
    return 0;
  }
  errno = EBADF;
  return -1;
}

//
// Check if file descriptor is a terminal
//
int isatty(int fd) {
  if (fd >= STDIN_FILENO && fd <= STDERR_FILENO) {
    return 1;
  }
  errno = ENOTTY;
  return 0;
}

//
// Exit program
//
void _exit(int status) {
  (void)status;
  // Flush any pending output
  svc_uart_flush();
  // Halt - infinite loop
  while (1) {
    asm volatile("wfi");
  }
}

//
// Send signal to process (stub)
//
int kill(pid_t pid, int sig) {
  (void)pid;
  (void)sig;
  errno = ESRCH;
  return -1;
}

//
// Get process ID (stub)
//
pid_t getpid(void) {
  return 1;
}

//
// Get time of day (stub - returns 0)
//
// Note: RV32I has no hardware division, and we don't link libgcc.
// A proper implementation would need soft division routines.
//
int gettimeofday(struct timeval *tv, void *tz) {
  (void)tz;

  if (tv == NULL) {
    errno = EFAULT;
    return -1;
  }

  tv->tv_sec  = 0;
  tv->tv_usec = 0;

  return 0;
}
