#
# Dhrystone benchmark Makefile
#

# Program name
PROGRAM = dhrystone

# Source files
OBJS = dhry_1.o dhry_2.o

# Include common build rules
include ../common/Makefile.common

# Override optimization flags for Dhrystone performance testing
# -O3: Maximum optimization
# -funroll-loops: Unroll loops for better performance
# -finline-functions: Inline functions aggressively
# -ffast-math: Fast floating point (though we don't use FP)
CFLAGS := $(filter-out -O2,$(CFLAGS)) -O3 -funroll-loops -finline-functions
