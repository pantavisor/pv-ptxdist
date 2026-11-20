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
# (the list behind pantavisor.io/downloads).
HOST_PV_ALPINE_CONNMAN_VERSION	:= 031
ifdef PTXCONF_ARCH_ARM64
HOST_PV_ALPINE_CONNMAN_MACHINE	:= armv8
HOST_PV_ALPINE_CONNMAN_SHA256	:= a2ab0598cad7f9332d7ea7d1c6ff40a90e4bf1ac82740a9384f1ce7aefe30cc7
endif
ifdef PTXCONF_ARCH_ARM
HOST_PV_ALPINE_CONNMAN_MACHINE	:= armv6
HOST_PV_ALPINE_CONNMAN_SHA256	:= 3e320a3a110cc069ab4ef0783d3e6f66c079ce2d9c353d320111133845a10cb8
endif
ifdef PTXCONF_ARCH_X86_64
HOST_PV_ALPINE_CONNMAN_MACHINE	:= x86_64
HOST_PV_ALPINE_CONNMAN_SHA256	:= 285da5477bc3c3bcb3ebb4d926c90532f44cd6bd768d4edbefcb94c84a7a9d05
endif
HOST_PV_ALPINE_CONNMAN		:= pv-alpine-connman-$(HOST_PV_ALPINE_CONNMAN_MACHINE)-$(HOST_PV_ALPINE_CONNMAN_VERSION)
HOST_PV_ALPINE_CONNMAN_SUFFIX	:= pvrexport.tgz
HOST_PV_ALPINE_CONNMAN_URL	:= https://pantavisor-ci.s3.amazonaws.com/meta-pantavisor/containers/$(HOST_PV_ALPINE_CONNMAN_VERSION)/pv-alpine-connman-docker-$(HOST_PV_ALPINE_CONNMAN_MACHINE)-scarthgap/pv-alpine-connman-$(HOST_PV_ALPINE_CONNMAN_MACHINE).$(HOST_PV_ALPINE_CONNMAN_SUFFIX)
HOST_PV_ALPINE_CONNMAN_SOURCE	:= $(SRCDIR)/$(HOST_PV_ALPINE_CONNMAN).$(HOST_PV_ALPINE_CONNMAN_SUFFIX)
HOST_PV_ALPINE_CONNMAN_DIR	:= $(HOST_BUILDDIR)/$(HOST_PV_ALPINE_CONNMAN)
# A built Alpine container: many packages, no license list shipped with it,
# and none in its source repo (meta-pantavisor declares it CLOSED). It ends
# up on the device, so keep it in the license report rather than ignore it.
HOST_PV_ALPINE_CONNMAN_LICENSE	:= unknown

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
