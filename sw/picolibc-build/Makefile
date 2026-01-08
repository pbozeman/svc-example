#
# Picolibc build Makefile
#
# Builds picolibc for RV32I, RV32IM, and RV32I_Zmmul architectures
#

PICOLIBC_SRC = ../picolibc
BUILD_BASE = ../../.build/picolibc

# Architecture variants to build
ARCHS = rv32i rv32im rv32i_zmmul

# Meson options for embedded use
MESON_OPTS = \
	-Dio-long-long=true \
	-Dformat-default=integer \
	-Datomic-ungetc=false \
	-Dthread-local-storage=false \
	-Dnewlib-global-errno=true \
	-Dposix-console=true \
	-Dpicolib=false \
	-Dpicocrt=false \
	-Dsemihost=false \
	-Dspecsdir=none \
	-Dtests=false \
	-Dmultilib=false

.PHONY: all clean $(ARCHS)

all: $(ARCHS)

rv32i: $(BUILD_BASE)/rv32i/libc.a

rv32im: $(BUILD_BASE)/rv32im/libc.a

rv32i_zmmul: $(BUILD_BASE)/rv32i_zmmul/libc.a

$(BUILD_BASE)/%/libc.a: cross-%.txt
	@mkdir -p $(BUILD_BASE)/$*
	cd $(BUILD_BASE)/$* && meson setup \
		--cross-file $(CURDIR)/cross-$*.txt \
		$(MESON_OPTS) \
		$(CURDIR)/$(PICOLIBC_SRC)
	cd $(BUILD_BASE)/$* && ninja

clean:
	rm -rf $(BUILD_BASE)
