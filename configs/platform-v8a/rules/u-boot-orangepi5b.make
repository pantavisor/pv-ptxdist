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
PACKAGES-$(PTXCONF_U_BOOT_ORANGEPI5B) += u-boot-orangepi5b

#
# Paths and names
#
U_BOOT_ORANGEPI5B_VERSION	= $(call ptx/config-version, PTXCONF_U_BOOT)
U_BOOT_ORANGEPI5B_MD5		= $(call ptx/config-md5, PTXCONF_U_BOOT)
U_BOOT_ORANGEPI5B		= u-boot-orangepi5b-$(U_BOOT_ORANGEPI5B_VERSION)
U_BOOT_ORANGEPI5B_SUFFIX	:= tar.bz2
U_BOOT_ORANGEPI5B_PATCHES	= u-boot-$(U_BOOT_ORANGEPI5B_VERSION)
U_BOOT_ORANGEPI5B_URL		= https://ftp.denx.de/pub/u-boot/$(U_BOOT_ORANGEPI5B_PATCHES).$(U_BOOT_ORANGEPI5B_SUFFIX)
U_BOOT_ORANGEPI5B_SOURCE	= $(SRCDIR)/$(U_BOOT_ORANGEPI5B_PATCHES).$(U_BOOT_ORANGEPI5B_SUFFIX)
U_BOOT_ORANGEPI5B_DIR		= $(BUILDDIR)/$(U_BOOT_ORANGEPI5B)
U_BOOT_ORANGEPI5B_BUILD_DIR	= $(U_BOOT_ORANGEPI5B_DIR)-build
U_BOOT_ORANGEPI5B_BUILD_OOT	:= KEEP
U_BOOT_ORANGEPI5B_DEVPKG	:= NO
U_BOOT_ORANGEPI5B_CONFIG	:= $(call ptx/in-platformconfigdir, u-boot-orangepi5b.config)
U_BOOT_ORANGEPI5B_LICENSE	:= GPL-2.0-or-later

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# use host pkg-config for host tools
U_BOOT_ORANGEPI5B_PATH		:= PATH=$(HOST_PATH)

U_BOOT_ORANGEPI5B_WRAPPER_BLACKLIST := \
	$(PTXDIST_LOWLEVEL_WRAPPER_BLACKLIST)

U_BOOT_ORANGEPI5B_CONF_TOOL	:= kconfig
U_BOOT_ORANGEPI5B_CONF_OPT	= \
	-C $(U_BOOT_ORANGEPI5B_DIR) \
	O=$(U_BOOT_ORANGEPI5B_BUILD_DIR) \
	V=$(PTXDIST_VERBOSE)

# binman packs BL31 and the DDR blob into u-boot-rockchip.bin.
U_BOOT_ORANGEPI5B_MAKE_ENV	= \
	CROSS_COMPILE=$(BOOTLOADER_CROSS_COMPILE) \
	HOSTCC=$(HOSTCC) \
	BL31=$(PTXDIST_SYSROOT_TARGET)/usr/lib/firmware/rk3588-bl31.elf \
	ROCKCHIP_TPL=$(PTXDIST_SYSROOT_TARGET)/usr/lib/firmware/$(RKBIN_RK3588_DDR)
U_BOOT_ORANGEPI5B_CONF_ENV	= $(U_BOOT_ORANGEPI5B_MAKE_ENV)
U_BOOT_ORANGEPI5B_MAKE_OPT	= $(U_BOOT_ORANGEPI5B_CONF_OPT)

ifdef PTXCONF_U_BOOT_ORANGEPI5B
$(U_BOOT_ORANGEPI5B_CONFIG):
	@echo
	@echo "****************************************************************************"
	@echo " Please generate a config with 'ptxdist menuconfig u-boot-orangepi5b'"
	@echo "****************************************************************************"
	@echo
	@echo
	@exit 1
endif

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-orangepi5b.install:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-orangepi5b.targetinstall:
	@$(call targetinfo)
	@$(call ptx/image-install, U_BOOT_ORANGEPI5B, \
		$(U_BOOT_ORANGEPI5B_BUILD_DIR)/u-boot-rockchip.bin, \
		u-boot-rockchip-orangepi5b.bin)
	@$(call touch)

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-orangepi5b.clean:
	@$(call targetinfo)
	@$(call clean_pkg, U_BOOT_ORANGEPI5B)

# ----------------------------------------------------------------------------
# oldconfig / menuconfig
# ----------------------------------------------------------------------------

$(call ptx/kconfig-targets, u-boot-orangepi5b): $(STATEDIR)/u-boot-orangepi5b.extract
	@$(call world/kconfig, U_BOOT_ORANGEPI5B, $(subst u-boot-orangepi5b_,,$@))

# vim: syntax=make
