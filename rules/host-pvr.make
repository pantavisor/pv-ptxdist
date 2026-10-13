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
HOST_PVR_VERSION	:= 054
HOST_PVR_SHA256		:= 40fe1f0344d0e75161ce5d68373f99d3e1b52c62ff8759c732dae8b692ef6a4c
HOST_PVR		:= pvr.$(HOST_PVR_VERSION).linux.amd64
HOST_PVR_SUFFIX		:= tar.gz
HOST_PVR_URL		:= https://gitlab.com/api/v4/projects/pantacor%2Fpvr/packages/generic/pvr/$(HOST_PVR_VERSION)/$(HOST_PVR).$(HOST_PVR_SUFFIX)
HOST_PVR_SOURCE		:= $(SRCDIR)/$(HOST_PVR).$(HOST_PVR_SUFFIX)
HOST_PVR_DIR		:= $(HOST_BUILDDIR)/$(HOST_PVR)
# The release tarball contains just the binary, no top-level directory.
HOST_PVR_STRIP_LEVEL	:= 0
# pvr is Apache-2.0 (LICENSE at tag 054); meta-pantavisor's pvr_054.bb says
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
