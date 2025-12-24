# RV Debug Loader Implementation Plan

## Overview

Add debug/loader capability to RISC-V SoC via UART, enabling:

- CPU reset control
- CPU stall control
- Direct memory writes to IMEM and DMEM (while stalled)
- Future: host tool to load compiled programs

## Architecture

```
Host (Python/Terminal)
    |
    | UART (serial)
    v
+------------------+
| svc_uart_rx/tx   |  <- Physical UART
+------------------+
    |
    v
+----------------------+
| svc_debug_bridge     |  <- Protocol decode, command dispatch
+----------------------+
    |
    +---> debug_rst_n      -> CPU reset
    +---> debug_stall      -> CPU stall (directly drives dmem_stall)
    +---> debug_mem_*      -> Memory write interface
    |
    v
+----------------------+
| Memory Mux           |  <- Select CPU vs debug access
+----------------------+
    |
    v
+------------------+
| IMEM / DMEM      |
+------------------+
```

## Address Map

### Debug Control Registers (0xF000_0000 range)

| Address     | Name         | R/W | Description                     |
| ----------- | ------------ | --- | ------------------------------- |
| 0xF000_0000 | DEBUG_CTRL   | R/W | Bit 0: stall, Bit 1: reset      |
| 0xF000_0004 | DEBUG_STATUS | R   | Bit 0: stalled, Bit 1: in_reset |

### Memory Access (directly addressed)

When stalled, UART bridge can write directly to:

- IMEM: 0x0000_0000 - 0x0000_FFFF (instruction memory)
- DMEM: 0x0001_0000 - 0x0001_FFFF (data memory, or wherever it's mapped)

Address decode based on bit patterns, not requiring I/O bit 31.

## Phased Implementation

### Phase 0: UART RX Infrastructure

**Goal:** Bidirectional UART working with echo test

#### 0.1 Add UART RX to svc_soc_io_reg

- Instantiate `svc_uart_rx` alongside existing `svc_uart_tx`
- Add registers:
  - 0x80000014: UART RX data (read-only, bits 7:0)
  - 0x80000018: UART RX status (read-only, bit 0 = data available)
- Handle ready/valid handshake properly

#### 0.2 Connect UART RX in svc_soc_sim

- Wire `svc_soc_sim_uart.urx_pin` to SoC's `uart_rx` input
- Add `uart_rx` port to `svc_soc_io_reg`

#### 0.3 Add SW UART RX functions

In `sw/common/libsvc/uart.{c,h}`:

```c
int svc_uart_rx_ready(void);   // Check if data available
char svc_uart_getc(void);      // Blocking read
int svc_uart_getc_nb(void);    // Non-blocking (-1 if no data)
```

#### 0.4 Create rv_echo test

New module `rtl/rv_echo/`:

- `rv_echo_sim.sv` - Simulation wrapper
- `sw/rv_echo/main.c` - Echo received characters back

Test: Run sim, use `uart_terminal.send_string("hello")`, verify echo.

---

### Phase 1: Debug Bridge Module

**Goal:** UART-to-debug bridge with stall/reset control

#### 1.1 Create svc_debug_bridge

New module `svc/rtl/rv/svc_debug_bridge.sv`:

Protocol (similar to `svc_axil_bridge_uart`):

```
Command format:
  Magic: 0xDB (1 byte)
  Op:    1 byte
         0x00 = read reg
         0x01 = write reg
         0x02 = write mem (burst)
  Addr:  4 bytes (little-endian)
  Len:   2 bytes (for burst, number of 32-bit words)
  Data:  4 bytes per word

Response:
  Magic: 0xBD (1 byte)
  Status: 1 byte (0=OK, 1=error)
  Data:  4 bytes (for reads)
```

Outputs:

- `debug_stall` - Drive CPU stall
- `debug_rst_n` - Drive CPU reset (active low)
- `debug_mem_wen` - Memory write enable
- `debug_mem_addr` - Memory address (32-bit)
- `debug_mem_wdata` - Write data (32-bit)
- `debug_mem_wstrb` - Write strobe (4-bit)
- `debug_mem_sel` - 0=IMEM, 1=DMEM

#### 1.2 Integrate into SoC

Create `svc_rv_soc_debug.sv` (or extend existing):

- Instantiate `svc_debug_bridge`
- Mux memory write ports:

```systemverilog
// IMEM write mux
assign imem_wen   = debug_stall ? (debug_mem_wen & ~debug_mem_sel) : 1'b0;
assign imem_waddr = debug_stall ? debug_mem_addr : '0;
assign imem_wdata = debug_stall ? debug_mem_wdata : '0;

// DMEM write mux
assign dmem_wen   = debug_stall ? (debug_mem_wen & debug_mem_sel) : cpu_dmem_wen;
assign dmem_waddr = debug_stall ? debug_mem_addr : cpu_dmem_waddr;
assign dmem_wdata = debug_stall ? debug_mem_wdata : cpu_dmem_wdata;
```

---

### Phase 2: rv_soc Integration

**Goal:** New simulation target with debug loader

#### 2.1 Create rv_soc module structure

```
rtl/rv_soc/
  rv_soc_sim.sv      - Simulation with debug bridge
  rv_soc_top.sv      - Synthesis target (ICE40/Vivado later)
```

#### 2.2 Build system integration

Add to Makefile:

- `make rv_soc_sim` - Basic BRAM variant
- `make rv_soc_im_sim` - With M extension
- `make rv_soc_sram_sim` - SRAM variant
- etc. (follow existing rv\_\* pattern)

#### 2.3 Basic test

- Start sim with empty/minimal program
- Send stall command via UART
- Write simple program to IMEM
- Release stall
- Verify program runs

---

### Phase 3: Host Loader Tool (Future)

**Goal:** Python tool to load ELF/binary to running simulation

#### 3.1 Python loader script

`scripts/rv_loader.py`:

- Parse ELF or raw binary
- Connect to simulation UART (via PTY or file)
- Send stall command
- Burst write IMEM/DMEM sections
- Release stall and reset

#### 3.2 Makefile integration

- `make rv_soc_load PROG=path/to/elf`

---

## File Changes Summary

### Phase 0 (UART RX)

| File                          | Change                      |
| ----------------------------- | --------------------------- |
| `rtl/svc_soc_io_reg.sv`       | Add UART RX instance + regs |
| `rtl/svc_soc_sim.sv`          | Wire uart_rx pin            |
| `sw/common/libsvc/uart.{c,h}` | Add RX functions            |
| `rtl/rv_echo/rv_echo_sim.sv`  | New: echo simulation        |
| `sw/rv_echo/main.c`           | New: echo program           |

### Phase 1 (Debug Bridge)

| File                             | Change                      |
| -------------------------------- | --------------------------- |
| `svc/rtl/rv/svc_debug_bridge.sv` | New: UART debug bridge      |
| `svc/rtl/rv/svc_rv_soc_debug.sv` | New: SoC with debug support |

### Phase 2 (rv_soc)

| File                       | Change                  |
| -------------------------- | ----------------------- |
| `rtl/rv_soc/rv_soc_sim.sv` | New: simulation wrapper |
| `rtl/rv_soc/rv_soc_top.sv` | New: synthesis target   |
| `Makefile`                 | Add rv*soc*\* targets   |

---

## Open Questions

1. **Reset behavior** - Should debug reset also reset the debug bridge itself?
   Probably not - bridge should stay alive to receive un-reset command.

2. **Memory size discovery** - Should debug bridge report IMEM/DMEM sizes? Could
   add read-only status registers.

3. **Verification** - Add `svc_debug_bridge_tb` with formal properties?

4. **UART baudrate** - Keep 115200 or go faster for loading? Consider 1Mbaud for
   faster loads on real hardware.

5. **Cache coherency** - For BRAM_CACHE variant, debug writes go to BRAM (IMEM)
   directly. DMEM might need cache flush/invalidate. Defer for now.
