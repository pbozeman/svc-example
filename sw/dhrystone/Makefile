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
# SiFive used -Os (but has bugs for us)
CFLAGS := $(filter-out -O2,$(CFLAGS)) -O3 -fno-inline

# Dhrystone inline
# CFLAGS := $(filter-out -O2,$(CFLAGS)) -O3 -finline-functions

# Dhrystone inline + lto
# CFLAGS := $(filter-out -O2,$(CFLAGS)) -O3 -finline-functions -flto -fwhole-program
