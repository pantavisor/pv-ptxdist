# -*-makefile-*-
#
# Copyright (C) 2026 by Fernando Luiz Cola <fernando.luiz@pantacor.com>
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_U_BOOT_QEMU_ARM64) += u-boot-qemu-arm64

#
# Paths and names
#
U_BOOT_QEMU_ARM64_VERSION	= $(call ptx/config-version, PTXCONF_U_BOOT_COMMON)
U_BOOT_QEMU_ARM64_MD5		= $(call ptx/config-md5, PTXCONF_U_BOOT_COMMON)
U_BOOT_QEMU_ARM64		= u-boot-qemu-arm64-$(U_BOOT_QEMU_ARM64_VERSION)
U_BOOT_QEMU_ARM64_SUFFIX	:= tar.bz2
U_BOOT_QEMU_ARM64_PATCHES	= u-boot-$(U_BOOT_QEMU_ARM64_VERSION)
U_BOOT_QEMU_ARM64_URL		= https://ftp.denx.de/pub/u-boot/$(U_BOOT_QEMU_ARM64_PATCHES).$(U_BOOT_QEMU_ARM64_SUFFIX)
U_BOOT_QEMU_ARM64_SOURCE	= $(SRCDIR)/$(U_BOOT_QEMU_ARM64_PATCHES).$(U_BOOT_QEMU_ARM64_SUFFIX)
U_BOOT_QEMU_ARM64_DIR		= $(BUILDDIR)/$(U_BOOT_QEMU_ARM64)
U_BOOT_QEMU_ARM64_BUILD_DIR	= $(U_BOOT_QEMU_ARM64_DIR)-build
U_BOOT_QEMU_ARM64_BUILD_OOT	:= KEEP
U_BOOT_QEMU_ARM64_DEVPKG	:= NO
U_BOOT_QEMU_ARM64_CONFIG	:= $(call ptx/in-platformconfigdir, u-boot-qemu-arm64.config)
U_BOOT_QEMU_ARM64_LICENSE	:= GPL-2.0-or-later

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# use host pkg-config for host tools
U_BOOT_QEMU_ARM64_PATH		:= PATH=$(HOST_PATH)

U_BOOT_QEMU_ARM64_WRAPPER_BLACKLIST := \
	$(PTXDIST_LOWLEVEL_WRAPPER_BLACKLIST)

U_BOOT_QEMU_ARM64_CONF_TOOL	:= kconfig
U_BOOT_QEMU_ARM64_CONF_OPT	= \
	-C $(U_BOOT_QEMU_ARM64_DIR) \
	O=$(U_BOOT_QEMU_ARM64_BUILD_DIR) \
	V=$(PTXDIST_VERBOSE)

U_BOOT_QEMU_ARM64_MAKE_ENV	= \
	CROSS_COMPILE=$(BOOTLOADER_CROSS_COMPILE) \
	HOSTCC=$(HOSTCC)
U_BOOT_QEMU_ARM64_CONF_ENV	= $(U_BOOT_QEMU_ARM64_MAKE_ENV)
U_BOOT_QEMU_ARM64_MAKE_OPT	= $(U_BOOT_QEMU_ARM64_CONF_OPT)

ifdef PTXCONF_U_BOOT_QEMU_ARM64
$(U_BOOT_QEMU_ARM64_CONFIG):
	@echo
	@echo "****************************************************************************"
	@echo " Please generate a config with 'ptxdist menuconfig u-boot-qemu-arm64'"
	@echo "****************************************************************************"
	@echo
	@echo
	@exit 1
endif

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-qemu-arm64.install:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-qemu-arm64.targetinstall:
	@$(call targetinfo)
	@$(call ptx/image-install, U_BOOT_QEMU_ARM64, \
		$(U_BOOT_QEMU_ARM64_BUILD_DIR)/u-boot.bin, \
		u-boot.bin)
	@$(call touch)

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-qemu-arm64.clean:
	@$(call targetinfo)
	@$(call clean_pkg, U_BOOT_QEMU_ARM64)

# ----------------------------------------------------------------------------
# oldconfig / menuconfig
# ----------------------------------------------------------------------------

$(call ptx/kconfig-targets, u-boot-qemu-arm64): $(STATEDIR)/u-boot-qemu-arm64.extract
	@$(call world/kconfig, U_BOOT_QEMU_ARM64, $(subst u-boot-qemu-arm64_,,$@))

# vim: syntax=make
