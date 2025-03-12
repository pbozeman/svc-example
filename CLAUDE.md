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
- List available tests: `make list_tb` or `make list_f`

## Important Workflow Notes

- ALWAYS run `make format` after making any code changes
- Run `make lint` to check for linting issues before committing
- Add \[🤖\] emoji to commit message tags when commits are Claude-generated

## Code Style Guidelines

- Naming: Module prefix `svc_`, test suffix `_tb`, formal suffix `_f`
- Signals: Lower snake_case without i\_/o\_ prefixes
- Types: Use `logic` instead of `wire`/`reg`
- Reset: Active-low `rst_n`
- Next-cycle signals: Use `_next` suffix (e.g., `grant_valid_next`)
- Structure: Parameters first, then ports in module declarations
