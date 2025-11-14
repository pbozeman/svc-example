# SVC-Example Commands and Guidelines

## Build Commands

- `make quick`: Default target, runs tests and formal verification with success
  silencing
- `make full`: Full verification with linting, testbenches and formal
  verification
- `make tb`: Run all testbenches
- `make formal`: Run all formal verification
- `make lint`: Lint all code with Verilator
- `make format`: Format all code to match style guidelines
- `make bits`: Synthesizes all bitstreams

## Running Single Tests

- Single testbench: `make <module_name>_tb` (e.g., `make blinky_tb`)
- Single formal check: `make <module_name>_f`
- Single standalone simulation: `make <module_name>_sim` (e.g.,
  `make uart_demo_sim`)
- List available tests: `make list_tb` or `make list_f` or `make list_sim`

### RISC-V Memory Type and Pipeline Variants

RISC-V simulations support multiple memory types and CPU pipeline
configurations:

**BRAM variants (default, pipelined CPU required):**

- `make rv_<module>_sim` - BRAM + pipelined + RV32I
- `make rv_<module>_im_sim` - BRAM + pipelined + RV32IM
- `make rv_<module>_i_zmmul_sim` - BRAM + pipelined + RV32I_Zmmul

**SRAM pipelined variants:**

- `make rv_<module>_sram_sim` - SRAM + pipelined + RV32I
- `make rv_<module>_sram_im_sim` - SRAM + pipelined + RV32IM
- `make rv_<module>_sram_i_zmmul_sim` - SRAM + pipelined + RV32I_Zmmul

**SRAM single-cycle variants:**

- `make rv_<module>_sram_sc_sim` - SRAM + single-cycle + RV32I
- `make rv_<module>_sram_sc_im_sim` - SRAM + single-cycle + RV32IM
- `make rv_<module>_sram_sc_i_zmmul_sim` - SRAM + single-cycle + RV32I_Zmmul

Examples:

- `make rv_hello_sim` - BRAM, pipelined, RV32I (default, backward compatible)
- `make rv_blinky_sram_im_sim` - SRAM, pipelined, RV32IM
- `make rv_hello_sram_sc_im_sim` - SRAM, single-cycle, RV32IM (CPI ~1.0)

See `docs/mem_type_sim.md` for detailed documentation on memory types and
performance characteristics.

## Important Workflow Notes

- ALWAYS run `make format` after making any code changes
- Run `make lint` to check for linting issues before committing
- Add [🤖] emoji to commit message tags when commits are Claude-generated

## Code Style Guidelines

- Naming: Module prefix `svc_`, test suffix `_tb`, formal suffix `_f`,
  standalone simulation suffix `_sim`
- Signals: Lower snake_case without i\_/o\_ prefixes
- Types: Use `logic` instead of `wire`/`reg`
- Reset: Active-low `rst_n`
- Next-cycle signals: Use `_next` suffix (e.g., `grant_valid_next`)
- Structure: Parameters first, then ports in module declarations

## Standalone Simulations

Standalone simulations (suffix `_sim`) are interactive simulations without the
test framework. They are useful for:

- Interactive development and debugging
- Demonstrating module behavior
- SOC-level integration testing with peripheral models

Key differences from testbenches:

- No test framework macros (`TEST_SUITE_BEGIN`, assertions, etc.)
- Run for extended periods or indefinitely
- Can print output to console in real-time
- Located in `rtl/<module>/` alongside `_top.sv` files

Common simulation infrastructure:

- `svc_soc_sim`: Clock and reset generation
- `svc_soc_sim_uart`: UART terminal model with interactive I/O

Example: `rtl/uart_demo/uart_demo_sim.sv`
