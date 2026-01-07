SVC_DIR = svc
PRJ_DIR = .
SW_DIR  = sw

.PHONY: default
default: quick

TOP_MODULES := \
	rtl/blinky/blinky_top.sv \
	rtl/debug_bridge_demo/debug_bridge_demo_top.sv \
	rtl/gfx_pattern_demo/gfx_pattern_demo_top.sv \
	rtl/mem_test_ice40_sram/mem_test_ice40_sram_top.sv \
	rtl/mem_test_striped_ice40_sram/mem_test_striped_ice40_sram_top.sv \
	rtl/svc_rv_soc_bram_demo/svc_rv_soc_bram_demo_top.sv \
	rtl/svc_rv_soc_bram_fwd_demo/svc_rv_soc_bram_fwd_demo_top.sv \
	rtl/svc_rv_soc_sram_demo/svc_rv_soc_sram_demo_top.sv \
	rtl/svc_rv_soc_sram_fwd_demo/svc_rv_soc_sram_fwd_demo_top.sv \
	rtl/svc_rv_soc_sram_ss_demo/svc_rv_soc_sram_ss_demo_top.sv \
	rtl/svc_rv_soc_bram_cache_fwd_demo/svc_rv_soc_bram_cache_fwd_demo_top.sv \
	rtl/uart_demo/uart_demo_top.sv \
	rtl/vga_pattern/vga_pattern_top.sv

	# rtl/gfx_pattern_demo_striped/gfx_pattern_demo_striped_top.sv \
	# rtl/gfx_shapes_demo_striped/gfx_shapes_demo_striped_top.sv \
	# rtl/gfx_shapes_demo/gfx_shapes_demo_top.sv \

	# These are now either too big, or need tuning to meet timing under
	# yosys/nextpnr. This is especially true for the perf tests with
	# the stats counters. R v.s. W would probably need to be selectively
	# turned on/off, same with top level v.s. leaf.
	#
	# rtl/axi_perf_ice40_sram/axi_perf_ice40_sram_top.sv
	# rtl/axi_perf_mem/axi_perf_mem_top.sv
	# rtl/axi_perf_ice40_sram/axi_perf_ice40_sram_top.sv
	# rtl/axi_perf_striped_ice40_sram/axi_perf_striped_ice40_sram_top.sv
	#
	# These used to make timing on older yosys versions.
	# rtl/mem_test_arbiter_ice40_sram/mem_test_arbiter_ice40_sram_top.sv
	# rtl/mem_test_striped_arbiter_ice40_sram/mem_test_striped_arbiter_ice40_sram_top.sv

CONSTRAINTS_DIR := constraints
ICE40_DEV_BOARD := vanilla-ice40
ICE40_DEVICE    := hx8k
ICE40_PACKAGE   := ct256
ICE40_CLK_FREQ  := 100

ICE40_FIND_SEED_MODULES = gfx_shapes_demo_top gfx_pattern_demo_striped_top mem_test_ice40_sram_top

# These are commented out above, but these are the overrides they need.
# The would need a top level PLL to support this.
# gfx_pattern_demo_striped_top_ICE40_CLK_FREQ = 90
# gfx_shapes_demo_striped_top_ICE40_CLK_FREQ = 90
# gfx_shapes_demo_top_ICE40_CLK_FREQ = 90


# FIXME: this isn't actually using a pll to run at this speed, so it will
# currently break. Only testing fmax and device utilization for now. This maybe
# can go higher with findseed

svc_rv_soc_bram_demo_top_ICE40_CLK_FREQ = 45
svc_rv_soc_sram_demo_top_ICE40_CLK_FREQ = 45

svc_rv_soc_bram_fwd_demo_top_ICE40_CLK_FREQ = 33
svc_rv_soc_sram_fwd_demo_top_ICE40_CLK_FREQ = 33

svc_rv_soc_sram_ss_demo_top_ICE40_CLK_FREQ = 25

svc_rv_soc_bram_cache_fwd_demo_top_ICE40_CLK_FREQ = 33

##############################################################################
#
# RISC-V Memory Configuration
#
# Define per-program memory sizes (in 32-bit words).
# These flow to both linker scripts and simulation builds.
#
##############################################################################

# Default sizes (in words)
RV_IMEM_DEPTH := 1024
RV_DMEM_DEPTH := 1024

# Per-program overrides (match simulation requirements)
#
# TODO: shrink dmem when not loading code and rodata into it.
# (Or this becomes moot with proper caches)
hello_RV_IMEM_DEPTH := 2048
hello_RV_DMEM_DEPTH := 2048

blinky_RV_IMEM_DEPTH := 2048
blinky_RV_DMEM_DEPTH := 2048

bubble_sort_RV_IMEM_DEPTH := 1024
bubble_sort_RV_DMEM_DEPTH := 1024

lib_test_RV_IMEM_DEPTH := 2560
lib_test_RV_DMEM_DEPTH := 6144

dhrystone_RV_IMEM_DEPTH := 2560
dhrystone_RV_DMEM_DEPTH := 6144

coremark_RV_IMEM_DEPTH := 8704
coremark_RV_DMEM_DEPTH := 20480

echo_RV_IMEM_DEPTH := 2048
echo_RV_DMEM_DEPTH := 2048
echo_SIM_FLAGS := +UART_STDIN

loader_RV_IMEM_DEPTH := 16384
loader_RV_DMEM_DEPTH := 32768
loader_SIM_FLAGS := +UART_PTY

export RV_IMEM_DEPTH RV_DMEM_DEPTH
export hello_RV_IMEM_DEPTH hello_RV_DMEM_DEPTH
export blinky_RV_IMEM_DEPTH blinky_RV_DMEM_DEPTH
export bubble_sort_RV_IMEM_DEPTH bubble_sort_RV_DMEM_DEPTH
export lib_test_RV_IMEM_DEPTH lib_test_RV_DMEM_DEPTH
export dhrystone_RV_IMEM_DEPTH dhrystone_RV_DMEM_DEPTH
export coremark_RV_IMEM_DEPTH coremark_RV_DMEM_DEPTH
export echo_RV_IMEM_DEPTH echo_RV_DMEM_DEPTH
export echo_SIM_FLAGS
export loader_RV_IMEM_DEPTH loader_RV_DMEM_DEPTH
export loader_SIM_FLAGS

include svc/mk/sv.mk
include svc/mk/icestorm.mk


##############################################################################
# 
# Risc-V apps and hex file generation. 
#
# This section is kinda wonky, and is both auto-magical and manual at the same
# time. It could use some rethinking, but works for now.
#
# (Note: by works, it works for _sim. This has not been hooked up to _top.)
#
##############################################################################

#
# RISC-V software targets
#
.PHONY: sw
sw:
	$(MAKE) -C $(SW_DIR)

.PHONY: sw_clean
sw_clean:
	$(MAKE) -C $(SW_DIR) clean

.PHONY: sw_list
sw_list:
	$(MAKE) -C $(SW_DIR) list

#
# Simulation software dependencies
#
# NOTE: Architecture-specific RISC-V simulation rules are now auto-generated
# in svc/mk/sim.mk. All rv_*_sim modules are automatically detected and
# compiled for rv32i, rv32im, and rv32i_zmmul architectures.
#
# Available targets: rv_<module>_{i,im,i_zmmul}_sim
# Example: make rv_hello_i_sim, make rv_hello_im_sim, make rv_hello_i_zmmul_sim
