#
# Top-level Makefile for RISC-V software
#

# List of all programs
PROGRAMS = blinky bubble_sort hello lib_test dhrystone coremark

# Programs that require hardware multiply (RV32IM only)
# coremark is multiply-heavy and impractical without hardware multiply
PROGRAMS_IM_ONLY = coremark

# Supported architectures
ARCHES = rv32i rv32im

# Picolibc build directory
PICOLIBC_BUILD = ../.build/picolibc

# Default target: build all programs for all architectures
.PHONY: all
all: $(ARCHES)

# Build picolibc for a specific architecture (only if not already built)
.PHONY: picolibc-rv32i picolibc-rv32im
picolibc-rv32i:
	@if [ ! -f $(PICOLIBC_BUILD)/rv32i/libc.a ]; then \
		echo "Building picolibc for rv32i..."; \
		$(MAKE) -C picolibc-build rv32i; \
	fi

picolibc-rv32im:
	@if [ ! -f $(PICOLIBC_BUILD)/rv32im/libc.a ]; then \
		echo "Building picolibc for rv32im..."; \
		$(MAKE) -C picolibc-build rv32im; \
	fi

# Build individual programs (uses default RV_ARCH=rv32i)
.PHONY: $(PROGRAMS)
$(PROGRAMS): picolibc-rv32i
	@echo "Building $@..."
	$(MAKE) -C $@

# Build all programs for a specific architecture
.PHONY: $(ARCHES)
rv32i: picolibc-rv32i
	@echo "Building all programs for rv32i..."
	@for prog in $(filter-out $(PROGRAMS_IM_ONLY),$(PROGRAMS)); do \
		echo "  Building $$prog for rv32i..."; \
		$(MAKE) -C $$prog RV_ARCH=rv32i; \
	done

rv32im: picolibc-rv32im
	@echo "Building all programs for rv32im..."
	@for prog in $(PROGRAMS); do \
		echo "  Building $$prog for rv32im..."; \
		$(MAKE) -C $$prog RV_ARCH=rv32im; \
	done

# Clean all programs for all architectures
.PHONY: clean
clean:
	@echo "Cleaning all architectures..."
	@rm -rf ../.build/sw/rv32i ../.build/sw/rv32im

# List all programs
.PHONY: list
list:
	@echo "Available programs:"
	@for prog in $(PROGRAMS); do \
		echo "  - $$prog"; \
	done
	@echo ""
	@echo "Supported architectures:"
	@for arch in $(ARCHES); do \
		echo "  - $$arch"; \
	done
