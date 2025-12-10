#
# CoreMark benchmark Makefile
#

# Program name
PROGRAM = coremark

# CoreMark submodule directory
COREMARK_DIR = coremark

# Source files (objects built from submodule and port)
OBJS = core_list_join.o core_main.o core_matrix.o core_state.o core_util.o \
       core_portme.o

# Include common build rules
include ../common/Makefile.common

# CoreMark specific flags
# ITERATIONS controls benchmark duration (higher = longer run)
# PERFORMANCE_RUN selects seeds for official benchmarking
COREMARK_ITERATIONS ?= 100

# Override CFLAGS for CoreMark (aggressive optimization, no inlining per rules)
# -fno-inline is required by CoreMark rules
# Additional optimizations: loop unrolling, LTO, frame pointer elimination
COREMARK_CFLAGS := $(filter-out -O2,$(CFLAGS)) -O3 -fno-inline \
                   -funroll-loops \
                   -fomit-frame-pointer \
                   -flto

# Now build the full CFLAGS with FLAGS_STR showing actual flags used
CFLAGS := $(COREMARK_CFLAGS) \
          -DITERATIONS=$(COREMARK_ITERATIONS) \
          -DPERFORMANCE_RUN=1 \
          -DFLAGS_STR=\""$(COREMARK_CFLAGS)"\" \
          -I$(COREMARK_DIR) \
          -I.

# Build rules for CoreMark sources from submodule
$(BUILD_DIR)/core_list_join.o: $(COREMARK_DIR)/core_list_join.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/core_main.o: $(COREMARK_DIR)/core_main.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/core_matrix.o: $(COREMARK_DIR)/core_matrix.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/core_state.o: $(COREMARK_DIR)/core_state.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/core_util.o: $(COREMARK_DIR)/core_util.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<
