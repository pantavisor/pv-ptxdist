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
HOST_PACKAGES-$(PTXCONF_HOST_PV_ALPINE_CONNMAN) += host-pv-alpine-connman

#
# Paths and names
#
# From https://pantavisor-ci.s3.amazonaws.com/meta-pantavisor/containers-releases.json
# (the list behind pantavisor.io/downloads). Only release candidates are
# published there so far.
HOST_PV_ALPINE_CONNMAN_VERSION	:= 031-rc2
ifdef PTXCONF_ARCH_ARM64
HOST_PV_ALPINE_CONNMAN_MACHINE	:= armv8
HOST_PV_ALPINE_CONNMAN_SHA256	:= e39b5dbd93c1d035880b4c74e5d452cba68208862acfa01571869fbd964a5a5a
endif
ifdef PTXCONF_ARCH_ARM
HOST_PV_ALPINE_CONNMAN_MACHINE	:= armv6
HOST_PV_ALPINE_CONNMAN_SHA256	:= 1e07401d780b8b24409a2e67ad86b81b689a0bf92e0b63baf4257c9002ed3bbb
endif
ifdef PTXCONF_ARCH_X86_64
HOST_PV_ALPINE_CONNMAN_MACHINE	:= x86_64
HOST_PV_ALPINE_CONNMAN_SHA256	:= dac09293d223750becff8cd6e52e28390b3821ca7ee82815a4a0271047f2f610
endif
HOST_PV_ALPINE_CONNMAN		:= pv-alpine-connman-$(HOST_PV_ALPINE_CONNMAN_MACHINE)-$(HOST_PV_ALPINE_CONNMAN_VERSION)
HOST_PV_ALPINE_CONNMAN_SUFFIX	:= pvrexport.tgz
HOST_PV_ALPINE_CONNMAN_URL	:= https://pantavisor-ci.s3.amazonaws.com/meta-pantavisor/containers/$(HOST_PV_ALPINE_CONNMAN_VERSION)/pv-alpine-connman-docker-$(HOST_PV_ALPINE_CONNMAN_MACHINE)-scarthgap/pv-alpine-connman-$(HOST_PV_ALPINE_CONNMAN_MACHINE).$(HOST_PV_ALPINE_CONNMAN_SUFFIX)
HOST_PV_ALPINE_CONNMAN_SOURCE	:= $(SRCDIR)/$(HOST_PV_ALPINE_CONNMAN).$(HOST_PV_ALPINE_CONNMAN_SUFFIX)
HOST_PV_ALPINE_CONNMAN_DIR	:= $(HOST_BUILDDIR)/$(HOST_PV_ALPINE_CONNMAN)
HOST_PV_ALPINE_CONNMAN_LICENSE	:= ignore

# The pvrexport is deployed as is, not unpacked.
$(STATEDIR)/host-pv-alpine-connman.extract:
	@$(call targetinfo)
	@mkdir -p $(HOST_PV_ALPINE_CONNMAN_DIR)
	@$(call touch)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

HOST_PV_ALPINE_CONNMAN_CONF_TOOL	:= NO

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

$(STATEDIR)/host-pv-alpine-connman.compile:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/host-pv-alpine-connman.install:
	@$(call targetinfo)
	@install -D -m 0644 $(HOST_PV_ALPINE_CONNMAN_SOURCE) \
		$(HOST_PV_ALPINE_CONNMAN_PKGDIR)/usr/share/pantavisor/containers/pv-alpine-connman.pvrexport.tgz
	@$(call touch)

# vim: syntax=make
