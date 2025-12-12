#include "libsvc/stdio.h"
#include "libsvc/sys.h"

int main(void) {
  uint32_t freq = svc_clock_freq();

  printf("Hello World\n");
  printf("Freq: %d\n", freq);
  return 0;
}
