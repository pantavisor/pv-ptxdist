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
PACKAGES-$(PTXCONF_U_BOOT_RPI3) += u-boot-rpi3

#
# Paths and names
#
U_BOOT_RPI3_VERSION	= $(call ptx/config-version, PTXCONF_U_BOOT)
U_BOOT_RPI3_MD5		= $(call ptx/config-md5, PTXCONF_U_BOOT)
U_BOOT_RPI3		= u-boot-rpi3-$(U_BOOT_RPI3_VERSION)
U_BOOT_RPI3_SUFFIX	:= tar.bz2
U_BOOT_RPI3_PATCHES	= u-boot-$(U_BOOT_RPI3_VERSION)
U_BOOT_RPI3_URL		= https://ftp.denx.de/pub/u-boot/$(U_BOOT_RPI3_PATCHES).$(U_BOOT_RPI3_SUFFIX)
U_BOOT_RPI3_SOURCE	= $(SRCDIR)/$(U_BOOT_RPI3_PATCHES).$(U_BOOT_RPI3_SUFFIX)
U_BOOT_RPI3_DIR		= $(BUILDDIR)/$(U_BOOT_RPI3)
U_BOOT_RPI3_BUILD_DIR	= $(U_BOOT_RPI3_DIR)-build
U_BOOT_RPI3_BUILD_OOT	:= KEEP
U_BOOT_RPI3_DEVPKG	:= NO
U_BOOT_RPI3_CONFIG	:= $(call ptx/in-platformconfigdir, u-boot-rpi3.config)
U_BOOT_RPI3_LICENSE	:= GPL-2.0-or-later

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# use host pkg-config for host tools
U_BOOT_RPI3_PATH		:= PATH=$(HOST_PATH)

U_BOOT_RPI3_WRAPPER_BLACKLIST := \
	$(PTXDIST_LOWLEVEL_WRAPPER_BLACKLIST)

U_BOOT_RPI3_CONF_TOOL	:= kconfig
U_BOOT_RPI3_CONF_OPT	= \
	-C $(U_BOOT_RPI3_DIR) \
	O=$(U_BOOT_RPI3_BUILD_DIR) \
	V=$(PTXDIST_VERBOSE)

U_BOOT_RPI3_MAKE_ENV	= \
	CROSS_COMPILE=$(BOOTLOADER_CROSS_COMPILE) \
	HOSTCC=$(HOSTCC)
U_BOOT_RPI3_CONF_ENV	= $(U_BOOT_RPI3_MAKE_ENV)
U_BOOT_RPI3_MAKE_OPT	= $(U_BOOT_RPI3_CONF_OPT)

ifdef PTXCONF_U_BOOT_RPI3
$(U_BOOT_RPI3_CONFIG):
	@echo
	@echo "****************************************************************************"
	@echo " Please generate a config with 'ptxdist menuconfig u-boot-rpi3'"
	@echo "****************************************************************************"
	@echo
	@echo
	@exit 1
endif

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-rpi3.install:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-rpi3.targetinstall:
	@$(call targetinfo)
	@$(call ptx/image-install, U_BOOT_RPI3, \
		$(U_BOOT_RPI3_BUILD_DIR)/u-boot.bin, \
		u-boot-rpi3.bin)
	@$(call touch)

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

$(STATEDIR)/u-boot-rpi3.clean:
	@$(call targetinfo)
	@$(call clean_pkg, U_BOOT_RPI3)

# ----------------------------------------------------------------------------
# oldconfig / menuconfig
# ----------------------------------------------------------------------------

$(call ptx/kconfig-targets, u-boot-rpi3): $(STATEDIR)/u-boot-rpi3.extract
	@$(call world/kconfig, U_BOOT_RPI3, $(subst u-boot-rpi3_,,$@))

# vim: syntax=make
