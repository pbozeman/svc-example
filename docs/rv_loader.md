# RISC-V Debug Loader

The debug loader allows loading programs into the RISC-V SoC via UART without
resynthesizing the FPGA bitstream or rebuilding the simulation.

## Using the Loader

The loader script is at `scripts/rv_loader.py`. It supports both ELF files
(recommended) and legacy hex files.

### Loading ELF Files (Recommended)

```bash
# Load ELF and run
./scripts/rv_loader.py -p /dev/ttyUSB0 --run .build/sw/rv32i/hello/hello.elf

# Load, reset, then run
./scripts/rv_loader.py -p /dev/ttyUSB0 --reset --run program.elf

# Just check status
./scripts/rv_loader.py -p /dev/ttyUSB0 --status

# Verbose output
./scripts/rv_loader.py -p /dev/ttyUSB0 -v --run program.elf
```

### Memory Mirroring

For Harvard architecture with mirrored DMEM, the loader writes each segment to
both memories:

- **IMEM**: segment loaded at its ELF address
- **DMEM**: segment loaded at `dmem_base + ELF address` (default dmem_base:
  `0x00010000`)

This mirrors the hex-init behavior where the same file is loaded to both IMEM
and DMEM, allowing the CPU to fetch instructions from IMEM and read data
(including `.rodata`) from DMEM at the same offsets.

### Legacy Hex Files

Hex files are loaded starting at address 0x0. They don't contain address
information, so they're only suitable for simple cases:

```bash
./scripts/rv_loader.py -p /dev/ttyUSB0 --run program.hex
```

### Loader Options

| Option          | Description                             |
| --------------- | --------------------------------------- |
| `--port, -p`    | Serial port (required for hardware)     |
| `--baud, -b`    | Baud rate (default: 115200)             |
| `--dmem-base`   | DMEM base address (default: 0x00010000) |
| `--burst`       | Words per burst (default: 256)          |
| `--status, -s`  | Read and display CPU status             |
| `--reset, -r`   | Reset CPU after loading                 |
| `--run`         | Release stall after loading (start CPU) |
| `--verbose, -v` | Show protocol debug output              |

## Example Session

### Loading to Hardware

```bash
# 1. Build the program
make sw/blinky

# 2. Connect to FPGA
./scripts/rv_loader.py -p /dev/ttyUSB0 -v --status
# Output: Status: stall=True, reset=True

# 3. Load and run
./scripts/rv_loader.py -p /dev/ttyUSB0 --run .build/sw/rv32i/blinky/blinky.elf
# Output:
# Loading ELF: .build/sw/rv32i/blinky/blinky.elf
# Loading 1 segment(s), 34 words (mirrored to IMEM and DMEM)
#   0x00000000 - 0x00000088 (34 words)
# Load complete: 34 words to each memory
# Starting CPU...
```

### Typical Load Sequence

The loader performs these steps:

1. **Read status** - Verify CPU is stalled and in reset
2. **Load segments** - Write each ELF segment to its target address
3. **Release reset** - `write_ctrl(stall=True, reset=False)`
4. **Release stall** - `write_ctrl(stall=False, reset=False)`

## Compiling Programs

### Quick Start

Build a program for the loader:

```bash
# Build hello program (default RV32I)
make sw/hello

# Build with M extension
make sw/hello RV_ARCH=rv32im
```

Output files are in `.build/sw/<arch>/<program>/`:

- `program.elf` - ELF binary (recommended for loading)
- `program.hex` - Legacy hex file (32-bit words, one per line)
- `program.dis` - Disassembly

### Program Structure

Each program needs a `Makefile`:

```makefile
# Program name (must match directory)
PROGRAM = myprogram

# Source files (object files to build)
OBJS = main.o

# Include common build rules
include ../common/Makefile.common
```

### Memory Configuration

Default memory sizes can be overridden in the top-level Makefile:

```makefile
# Per-program memory overrides (in 32-bit words)
myprogram_RV_IMEM_DEPTH := 8192
myprogram_RV_DMEM_DEPTH := 4096
```

### Linker Script

The common linker script (`sw/common/link.ld`) handles:

- `.text` and `.rodata` in code region
- `.data` and `.bss` in data region
- Stack at top of data memory, grows downward
- BSS section symbols (`__bss_start`, `__bss_end`) for zeroing

### Library Support

Programs automatically link against `libsvc` which provides:

- `svc_putc()`, `svc_puts()`, `svc_printf()` - UART output
- `svc_uart_getc()`, `svc_uart_rx_ready()` - UART input
- `svc_div()`, `svc_mod()` - Software division (RV32I)
- `svc_cycles()` - Cycle counter access

## Overview

When the SoC is configured with `DEBUG_ENABLED=1`, the CPU starts stalled and in
reset. A debug bridge (`svc_rv_dbg_bridge`) receives commands via UART to:

1. Control CPU reset and stall
2. Write directly to memory

This enables rapid iterative development - change your C code, rebuild, and
reload in seconds rather than waiting for FPGA synthesis (minutes) or Verilator
compilation.

## Architecture

```
Host (Python loader)
    |
    | UART (115200 baud)
    v
+------------------+
| svc_uart_rx/tx   |
+------------------+
    |
    v
+----------------------+
| svc_rv_dbg_bridge    |
+----------------------+
    |
    +---> dbg_rst_n   -> CPU reset control
    +---> dbg_stall   -> CPU stall control
    +---> dbg_mem_*   -> Memory write interface
```

## Debug Protocol

All multi-byte values are little-endian.

### Command Format

| Field   | Size   | Description             |
| ------- | ------ | ----------------------- |
| Magic   | 1 byte | `0xDB`                  |
| Opcode  | 1 byte | Operation (see below)   |
| Payload | varies | Operation-specific data |

### Response Format

| Field   | Size   | Description                 |
| ------- | ------ | --------------------------- |
| Magic   | 1 byte | `0xBD`                      |
| Status  | 1 byte | `0x00` = OK, `0x01` = error |
| Payload | varies | Operation-specific response |

### Operations

| Opcode | Name        | Request Payload                 | Response Payload |
| ------ | ----------- | ------------------------------- | ---------------- |
| `0x00` | Read Ctrl   | none                            | 1 byte (status)  |
| `0x01` | Write Ctrl  | 1 byte (ctrl)                   | none             |
| `0x02` | Write Mem   | addr(4) + data(4)               | none             |
| `0x03` | Write Burst | addr(4) + len(2) + data(4\*len) | none             |

### Control Register Bits

| Bit | Name  | Description                               |
| --- | ----- | ----------------------------------------- |
| 0   | STALL | CPU stalled when 1                        |
| 1   | RESET | CPU in reset when 1 (active-high in ctrl) |

## Simulation Targets

| Target            | Description                      |
| ----------------- | -------------------------------- |
| `rv_soc_sim`      | Debug-enabled SoC (BRAM, RV32I)  |
| `rv_soc_im_sim`   | Debug-enabled SoC (BRAM, RV32IM) |
| `rv_soc_sram_sim` | Debug-enabled SoC (SRAM, RV32I)  |
| `rv_loader_sim`   | Protocol test via SystemVerilog  |

## Troubleshooting

### No response from bridge

- Check baud rate matches (115200 default)
- Verify UART TX/RX connections
- Ensure SoC is configured with `DEBUG_ENABLED=1`

### Program crashes after load

- Verify program was compiled for correct architecture (RV32I vs RV32IM)
- Check memory sizes match hardware configuration
- Review disassembly for unexpected instructions

### Load is slow

- Increase burst size with `--burst 512` or higher
- Consider increasing baud rate if hardware supports it
