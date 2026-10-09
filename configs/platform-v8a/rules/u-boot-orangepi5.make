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
PACKAGES-$(PTXCONF_U_BOOT_ORANGEPI5) += u-boot-orangepi5

#
# Paths and names
#
U_BOOT_ORANGEPI5_VERSION	= $(call ptx/config-version, PTXCONF_U_BOOT)
U_BOOT_ORANGEPI5_MD5		= $(call ptx/config-md5, PTXCONF_U_BOOT)
U_BOOT_ORANGEPI5		= u-boot-orangepi5-$(U_BOOT_ORANGEPI5_VERSION)
U_BOOT_ORANGEPI5_SUFFIX	:= tar.bz2
U_BOOT_ORANGEPI5_PATCHES	= u-boot-$(U_BOOT_ORANGEPI5_VERSION)
U_BOOT_ORANGEPI5_URL		= https://ftp.denx.de/pub/u-boot/$(U_BOOT_ORANGEPI5_PATCHES).$(U_BOOT_ORANGEPI5_SUFFIX)
U_BOOT_ORANGEPI5_SOURCE	= $(SRCDIR)/$(U_BOOT_ORANGEPI5_PATCHES).$(U_BOOT_ORANGEPI5_SUFFIX)
U_BOOT_ORANGEPI5_DIR		= $(BUILDDIR)/$(U_BOOT_ORANGEPI5)
U_BOOT_ORANGEPI5_BUILD_DIR	= $(U_BOOT_ORANGEPI5_DIR)-build
U_BOOT_ORANGEPI5_BUILD_OOT	:= KEEP
U_BOOT_ORANGEPI5_DEVPKG	:= NO
U_BOOT_ORANGEPI5_CONFIG	:= $(call ptx/in-platformconfigdir, u-boot-orangepi5.config)
U_BOOT_ORANGEPI5_LICENSE	:= GPL-2.0-or-later

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# use host pkg-config for host tools
U_BOOT_ORANGEPI5_PATH		:= PATH=$(HOST_PATH)

U_BOOT_ORANGEPI5_WRAPPER_BLACKLIST := \
	$(PTXDIST_LOWLEVEL_WRAPPER_BLACKLIST)

U_BOOT_ORANGEPI5_CONF_TOOL	:= kconfig
U_BOOT_ORANGEPI5_CONF_OPT	= \
	-C $(U_BOOT_ORANGEPI5_DIR) \
	O=$(U_BOOT_ORANGEPI5_BUILD_DIR) \
	V=$(PTXDIST_VERBOSE)

# binman packs BL31 and the DDR blob into u-boot-rockchip.bin.
U_BOOT_ORANGEPI5_MAKE_ENV	= \
	CROSS_COMPILE=$(BOOTLOADER_CROSS_COMPILE) \
	HOSTCC=$(HOSTCC) \
	BL31=$(PTXDIST_SYSROOT_TARGET)/usr/lib/firmware/rk3588-bl31.elf \
	ROCKCHIP_TPL=$(PTXDIST_SYSROOT_TARGET)/usr/lib/firmware/$(RKBIN_RK3588_DDR)
U_BOOT_ORANGEPI5_CONF_ENV	= $(U_BOOT_ORANGEPI5_MAKE_ENV)
U_BOOT_ORANGEPI5_MAKE_OPT	= $(U_BOOT_ORANGEPI5_CONF_OPT)

ifdef PTXCONF_U_BOOT_ORANGEPI5
$(U_BOOT_ORANGEPI5_CONFIG):
	@echo
	@echo "****************************************************************************"
	@echo " Please generate a config with 'ptxdist menuconfig u-boot-orangepi5'"
	@echo "****************************************************************************"
	@echo
	@echo
	@exit 1
endif

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-orangepi5.install:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-orangepi5.targetinstall:
	@$(call targetinfo)
	@$(call ptx/image-install, U_BOOT_ORANGEPI5, \
		$(U_BOOT_ORANGEPI5_BUILD_DIR)/u-boot-rockchip.bin, \
		u-boot-rockchip-orangepi5.bin)
	@$(call touch)

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-orangepi5.clean:
	@$(call targetinfo)
	@$(call clean_pkg, U_BOOT_ORANGEPI5)

# ----------------------------------------------------------------------------
# oldconfig / menuconfig
# ----------------------------------------------------------------------------

$(call ptx/kconfig-targets, u-boot-orangepi5): $(STATEDIR)/u-boot-orangepi5.extract
	@$(call world/kconfig, U_BOOT_ORANGEPI5, $(subst u-boot-orangepi5_,,$@))

# vim: syntax=make
