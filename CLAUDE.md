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
