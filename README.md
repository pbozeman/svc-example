# svc-example

Demo repo using the [SVC](https://github.com/pbozeman/svc) library and build
system.

Contains a basic blinky example plus an AXI read/write test for the
[Vanilla-ICE40 dev board](https://github.com/pbozeman/vanilla-ice40) and SRAM
expansion.

SVC is a submodule, `git submodule init` and `git submodule update` after
cloning.

## make target overview

- `make` runs tests
- `make bits` synthesizes all bitstreams
- `make uart_demo_sim` runs standalone interactive simulation
- `make blink_top_prog` programs the blinky bitstream
- `make mem_test_top_prog` programs the mem test bitsream

plus others: clean, lint, formal, list_tb, list_sim, etc.
