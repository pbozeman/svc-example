# RISC-V Software

This directory contains RISC-V software applications for the SVC RISC-V SoC
demos.

## Architecture

- **ISA**: RV32I with Zicsr extension (for CSR access)
- **ABI**: ilp32 (32-bit integer, long, pointer)
- **Memory Model**: Harvard architecture with separate instruction and data
  memories
  - Instruction memory: starts at `0x00000000`
  - Data memory: starts at `0x00000000` (separate address space)
  - I/O space: starts at `0x80000000`

## Directory Structure

```
sw/
├── common/           # Shared infrastructure
│   ├── crt0.S       # Startup code
│   ├── link.ld      # Linker script
│   ├── mmio.h       # Memory-mapped I/O helpers
│   └── Makefile.common  # Common build rules
├── blinky/          # LED blink example (MMIO)
├── uart/            # UART echo example (planned)
└── dhrystone/       # Dhrystone benchmark (planned)
```

## Building

### Build all programs

```bash
make sw
```

### Build a single program

```bash
cd sw/blinky
make
```

### Clean all programs

```bash
make sw_clean
```

### List available programs

```bash
make sw_list
```

## Output Files

For each program, the build generates:

- `<program>.elf` - ELF executable with debug symbols
- `<program>.hex` - Verilog hex format for `$readmemh()` (used in RTL)
- `<program>.dis` - Disassembly listing
- `<program>.bin` - Raw binary (not currently used)

## Memory Map

### Instruction Memory (IMEM)

- Size: 8KB (configurable via `IMEM_AW` parameter in SoC)
- Access: Read-only from CPU perspective
- Initialized via `.hex` file at synthesis time

### Data Memory (DMEM)

- Size: 2KB (configurable via `DMEM_AW` parameter in SoC)
- Access: Read/write
- Stack grows down from end of DMEM (`0x800` with 2KB)

### I/O Space

- Base: `0x80000000`
- Access: Memory-mapped I/O via load/store instructions
- Device-specific offsets defined in each program

## Adding a New Program

1. Create directory: `mkdir sw/myprogram`
2. Create `main.c` with your application
3. Create `Makefile`:
   ```make
   PROGRAM = myprogram
   OBJS = main.o
   include ../common/Makefile.common
   ```
4. Add to `sw/Makefile` PROGRAMS list
5. Build with `make sw`

## Using Programs in RTL

To use a compiled program in your RTL design:

1. Build the program: `make sw`
2. Copy the `.hex` file to your RTL demo directory
3. Reference it in the `IMEM_INIT` parameter:
   ```systemverilog
   svc_rv_soc_bram #(
       .IMEM_INIT("path/to/program.hex")
   ) soc (...);
   ```

## Toolchain

The build system uses the RISC-V GNU toolchain:

- `riscv64-none-elf-gcc` - Compiler (targets RV32 via `-march=rv32i_zicsr`)
- `riscv64-none-elf-objcopy` - Binary utilities
- `riscv64-none-elf-objdump` - Disassembler

These tools are provided by the Nix flake development environment.

## Notes

- Programs are bare-metal (no OS, no standard C library)
- The `ebreak` instruction signals program completion to testbenches
- Infinite loops are fine for hardware demos (e.g., blinky)
- For proper stack usage, ensure DMEM is large enough for your application
