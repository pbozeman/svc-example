#
# Top-level Makefile for RISC-V software
#

# List of all programs
PROGRAMS = blinky bubble_sort hello lib_test dhrystone

# Default target: build all programs
.PHONY: all
all: $(PROGRAMS)

# Build individual programs
.PHONY: $(PROGRAMS)
$(PROGRAMS):
	@echo "Building $@..."
	$(MAKE) -C $@

# Clean all programs
.PHONY: clean
clean:
	@for prog in $(PROGRAMS); do \
		echo "Cleaning $$prog..."; \
		$(MAKE) -C $$prog clean; \
	done

# List all programs
.PHONY: list
list:
	@echo "Available programs:"
	@for prog in $(PROGRAMS); do \
		echo "  - $$prog"; \
	done
