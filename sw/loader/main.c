// Placeholder - actual program is loaded via debug bridge
// This just does ebreak in case it somehow runs
int main(void) {
  __asm__ volatile("ebreak");
  return 0;
}
