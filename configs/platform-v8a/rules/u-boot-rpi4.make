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
PACKAGES-$(PTXCONF_U_BOOT_RPI4) += u-boot-rpi4

#
# Paths and names
#
U_BOOT_RPI4_VERSION	= $(call ptx/config-version, PTXCONF_U_BOOT)
U_BOOT_RPI4_MD5		= $(call ptx/config-md5, PTXCONF_U_BOOT)
U_BOOT_RPI4		= u-boot-rpi4-$(U_BOOT_RPI4_VERSION)
U_BOOT_RPI4_SUFFIX	:= tar.bz2
U_BOOT_RPI4_PATCHES	= u-boot-$(U_BOOT_RPI4_VERSION)
U_BOOT_RPI4_URL		= https://ftp.denx.de/pub/u-boot/$(U_BOOT_RPI4_PATCHES).$(U_BOOT_RPI4_SUFFIX)
U_BOOT_RPI4_SOURCE	= $(SRCDIR)/$(U_BOOT_RPI4_PATCHES).$(U_BOOT_RPI4_SUFFIX)
U_BOOT_RPI4_DIR		= $(BUILDDIR)/$(U_BOOT_RPI4)
U_BOOT_RPI4_BUILD_DIR	= $(U_BOOT_RPI4_DIR)-build
U_BOOT_RPI4_BUILD_OOT	:= KEEP
U_BOOT_RPI4_DEVPKG	:= NO
U_BOOT_RPI4_CONFIG	:= $(call ptx/in-platformconfigdir, u-boot-rpi4.config)
U_BOOT_RPI4_LICENSE	:= GPL-2.0-or-later

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# use host pkg-config for host tools
U_BOOT_RPI4_PATH		:= PATH=$(HOST_PATH)

U_BOOT_RPI4_WRAPPER_BLACKLIST := \
	$(PTXDIST_LOWLEVEL_WRAPPER_BLACKLIST)

U_BOOT_RPI4_CONF_TOOL	:= kconfig
U_BOOT_RPI4_CONF_OPT	= \
	-C $(U_BOOT_RPI4_DIR) \
	O=$(U_BOOT_RPI4_BUILD_DIR) \
	V=$(PTXDIST_VERBOSE)

U_BOOT_RPI4_MAKE_ENV	= \
	CROSS_COMPILE=$(BOOTLOADER_CROSS_COMPILE) \
	HOSTCC=$(HOSTCC)
U_BOOT_RPI4_CONF_ENV	= $(U_BOOT_RPI4_MAKE_ENV)
U_BOOT_RPI4_MAKE_OPT	= $(U_BOOT_RPI4_CONF_OPT)

ifdef PTXCONF_U_BOOT_RPI4
$(U_BOOT_RPI4_CONFIG):
	@echo
	@echo "****************************************************************************"
	@echo " Please generate a config with 'ptxdist menuconfig u-boot-rpi4'"
	@echo "****************************************************************************"
	@echo
	@echo
	@exit 1
endif

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-rpi4.install:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-rpi4.targetinstall:
	@$(call targetinfo)
	@$(call ptx/image-install, U_BOOT_RPI4, \
		$(U_BOOT_RPI4_BUILD_DIR)/u-boot.bin, \
		u-boot-rpi4.bin)
	@$(call touch)

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-rpi4.clean:
	@$(call targetinfo)
	@$(call clean_pkg, U_BOOT_RPI4)

# ----------------------------------------------------------------------------
# oldconfig / menuconfig
# ----------------------------------------------------------------------------

$(call ptx/kconfig-targets, u-boot-rpi4): $(STATEDIR)/u-boot-rpi4.extract
	@$(call world/kconfig, U_BOOT_RPI4, $(subst u-boot-rpi4_,,$@))

# vim: syntax=make
