SVC_DIR = svc
PRJ_DIR = .

.PHONY: default
default: quick

TOP_MODULES := \
	rtl/blinky/blinky_top.sv \
	rtl/gfx_pattern_demo/gfx_pattern_demo_top.sv \
	rtl/gfx_pattern_demo_striped/gfx_pattern_demo_striped_top.sv \
	rtl/mem_test_arbiter_ice40_sram/mem_test_arbiter_ice40_sram_top.sv \
	rtl/mem_test_ice40_sram/mem_test_ice40_sram_top.sv \
	rtl/mem_test_striped_arbiter_ice40_sram/mem_test_striped_arbiter_ice40_sram_top.sv \
	rtl/mem_test_striped_ice40_sram/mem_test_striped_ice40_sram_top.sv \
	rtl/uart_demo/uart_demo_top.sv \
	rtl/vga_pattern/vga_pattern_top.sv

  # Temporarily disable previously working designs during the cut over
	# to the new V2 pin out.
	#
	# rtl/gfx_pattern_demo_striped/gfx_pattern_demo_striped_top.sv \
	# rtl/uart_demo/uart_demo_top.sv \
	# rtl/debug_bridge_demo/debug_bridge_demo_top.sv

	# These are now either too big, or need tuning to meet timing under
	# yosys/nextpnr. This is especially true for the perf tests with
	# the stats counters. R v.s. W would probably need to be selectively
	# turned on/off, same with top level v.s. leaf.
	#
	# rtl/axi_perf_ice40_sram/axi_perf_ice40_sram_top.sv
	# rtl/axi_perf_mem/axi_perf_mem_top.sv
	# rtl/axi_perf_ice40_sram/axi_perf_ice40_sram_top.sv
	# rtl/axi_perf_striped_ice40_sram/axi_perf_striped_ice40_sram_top.sv
	# rtl/gfx_shapes_demo/gfx_shapes_demo_top.sv

CONSTRAINTS_DIR := constraints
ICE40_DEV_BOARD := vanilla-ice40
ICE40_DEVICE    := hx8k
ICE40_PACKAGE   := ct256
ICE40_CLK_FREQ  := 100

include svc/mk/sv.mk
include svc/mk/icestorm.mk
