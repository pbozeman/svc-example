#
# Top-level Makefile for RISC-V software
#

# List of all programs
PROGRAMS = blinky bubble_sort hello lib_test dhrystone

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
$(ARCHES):
	@echo "Building all programs for $@..."
	@for prog in $(PROGRAMS); do \
		echo "  Building $$prog for $@..."; \
		$(MAKE) -C $$prog RV_ARCH=$@; \
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
