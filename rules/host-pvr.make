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
HOST_PACKAGES-$(PTXCONF_HOST_PVR) += host-pvr

#
# Paths and names
#
HOST_PVR_VERSION	:= 055
HOST_PVR_SHA256		:= 00b69c470761ed6196df1bc269da794efa4eeed7a69ca6eecd700995973c72b6
HOST_PVR		:= pvr.$(HOST_PVR_VERSION).linux.amd64
HOST_PVR_SUFFIX		:= tar.gz
HOST_PVR_URL		:= https://gitlab.com/api/v4/projects/pantacor%2Fpvr/packages/generic/pvr/$(HOST_PVR_VERSION)/$(HOST_PVR).$(HOST_PVR_SUFFIX)
HOST_PVR_SOURCE		:= $(SRCDIR)/$(HOST_PVR).$(HOST_PVR_SUFFIX)
HOST_PVR_DIR		:= $(HOST_BUILDDIR)/$(HOST_PVR)
# The release tarball contains just the binary, no top-level directory.
HOST_PVR_STRIP_LEVEL	:= 0
# pvr is Apache-2.0 (LICENSE at tag 055); meta-pantavisor's pvr_055.bb says
# MIT. The release tarball has only the binary, so no license file to
# point at.
HOST_PVR_LICENSE	:= Apache-2.0

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

HOST_PVR_CONF_TOOL	:= NO

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

$(STATEDIR)/host-pvr.compile:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/host-pvr.install:
	@$(call targetinfo)
	@install -D -m 0755 $(HOST_PVR_DIR)/pvr $(HOST_PVR_PKGDIR)/usr/bin/pvr
	@$(call touch)

# vim: syntax=make
