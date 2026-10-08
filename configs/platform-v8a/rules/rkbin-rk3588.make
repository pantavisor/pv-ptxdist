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
PACKAGES-$(PTXCONF_RKBIN_RK3588) += rkbin-rk3588

#
# Paths and names
#
# Only the blob is fetched: the rkbin archive is several hundred MB.
RKBIN_RK3588_COMMIT	:= 3e288fe814e059dd06833495f845cab04ac20a5c
RKBIN_RK3588_DDR	:= rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.24.bin
RKBIN_RK3588_VERSION	:= v1.24-3e288fe814e0
RKBIN_RK3588_SHA256	:= 2853a0da7ab895af43d50615af73eccf0694115dd0202483ee1c93c9071a42c3
RKBIN_RK3588		:= rkbin-rk3588-ddr-$(RKBIN_RK3588_VERSION)
RKBIN_RK3588_SUFFIX	:= bin
RKBIN_RK3588_URL	:= https://raw.githubusercontent.com/rockchip-linux/rkbin/$(RKBIN_RK3588_COMMIT)/bin/rk35/$(RKBIN_RK3588_DDR)
RKBIN_RK3588_SOURCE	:= $(SRCDIR)/$(RKBIN_RK3588).$(RKBIN_RK3588_SUFFIX)
RKBIN_RK3588_DIR	:= $(BUILDDIR)/$(RKBIN_RK3588)
RKBIN_RK3588_LICENSE	:= proprietary

$(STATEDIR)/rkbin-rk3588.extract:
	@$(call targetinfo)
	@mkdir -p $(RKBIN_RK3588_DIR)
	@$(call touch)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

RKBIN_RK3588_CONF_TOOL	:= NO

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

$(STATEDIR)/rkbin-rk3588.compile:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/rkbin-rk3588.install:
	@$(call targetinfo)
	@install -v -D -m 0644 $(RKBIN_RK3588_SOURCE) \
		$(RKBIN_RK3588_PKGDIR)/usr/lib/firmware/$(RKBIN_RK3588_DDR)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/rkbin-rk3588.targetinstall:
	@$(call targetinfo)
	@$(call touch)

# vim: syntax=make
