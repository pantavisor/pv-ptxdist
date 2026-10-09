# -*-makefile-*-
#
# Copyright (C) 2026 by Fernando Luiz Cola <fernando.luiz@pantacor.com>
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

# QEMU x86 loads U-Boot with -bios u-boot.rom, which the PTXdist u-boot rule
# has no install option for. pv-hd.img is the image it boots, so the ROM is
# built along with it.
ifdef PTXCONF_U_BOOT
$(IMAGEDIR)/u-boot.rom: $(STATEDIR)/u-boot.targetinstall
	@install -m 0644 $(U_BOOT_BUILD_DIR)/u-boot.rom $@

$(IMAGEDIR)/pv-hd.img: $(IMAGEDIR)/u-boot.rom

# See PV_U_BOOT_X86_DEPS: without this, a parallel build can reach U-Boot's
# pylibfdt before setuptools is installed.
$(STATEDIR)/u-boot.compile: $(STATEDIR)/host-system-python3-setuptools.install.post
endif

# vim: syntax=make
