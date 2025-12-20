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

# Default target: build all programs for all architectures
.PHONY: all
all: $(ARCHES)

# Build individual programs (uses default RV_ARCH=rv32i)
.PHONY: $(PROGRAMS)
$(PROGRAMS):
	@echo "Building $@..."
	$(MAKE) -C $@

# Build all programs for a specific architecture
.PHONY: $(ARCHES)
rv32i:
	@echo "Building all programs for rv32i..."
	@for prog in $(filter-out $(PROGRAMS_IM_ONLY),$(PROGRAMS)); do \
		echo "  Building $$prog for rv32i..."; \
		$(MAKE) -C $$prog RV_ARCH=rv32i; \
	done

rv32im:
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
