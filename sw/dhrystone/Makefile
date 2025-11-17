#
# Dhrystone benchmark Makefile
#

# Program name
PROGRAM = dhrystone

# Source files
OBJS = dhry_1.o dhry_2.o

# Include common build rules
include ../common/Makefile.common

# Dhrystone ground rules: no procedure merging (inlining)
CFLAGS := $(filter-out -O2,$(CFLAGS)) -O3 -fno-inline

# Dhrystone optimized
# CFLAGS := $(filter-out -O2,$(CFLAGS)) -O3 -finline-functions

# Even smaller, but hangs
# CFLAGS := $(filter-out -O2,$(CFLAGS)) -O3 -finline-functions -flto
