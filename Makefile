SVC_DIR = svc
PRJ_DIR = .

.PHONY: default
default: quick

TOP_MODULES := rtl/blinky/blinky_top.sv rtl/mem_test/mem_test_top.sv

CONSTRAINTS_DIR := constraints
ICE40_DEV_BOARD := vanilla-ice40
ICE40_DEVICE    := hx8k
ICE40_PACKAGE   := ct256
ICE40_CLK_FREQ  := 100

include svc/mk/sv.mk
include svc/mk/icestorm.mk
