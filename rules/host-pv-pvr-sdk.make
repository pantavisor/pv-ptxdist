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
HOST_PACKAGES-$(PTXCONF_HOST_PV_PVR_SDK) += host-pv-pvr-sdk

#
# Paths and names
#
# From https://pantavisor-ci.s3.amazonaws.com/meta-pantavisor/containers-releases.json
# (the list behind pantavisor.io/downloads). Only release candidates are
# published there so far.
HOST_PV_PVR_SDK_VERSION	:= 031-rc2
ifdef PTXCONF_ARCH_ARM64
HOST_PV_PVR_SDK_MACHINE	:= armv8
HOST_PV_PVR_SDK_SHA256	:= 46617f4f47d1660874903198f85e2b3e396767dc08b0513ab50bd1137be54e01
endif
ifdef PTXCONF_ARCH_ARM
HOST_PV_PVR_SDK_MACHINE	:= armv6
HOST_PV_PVR_SDK_SHA256	:= 238ca53481c6c23b68bb48e6c8b117a65b18fe5294783c0fc4b7320c7e4bb38c
endif
ifdef PTXCONF_ARCH_X86_64
HOST_PV_PVR_SDK_MACHINE	:= x86_64
HOST_PV_PVR_SDK_SHA256	:= b584aabae30e53f1b0caf16007fcd6b52d5064628141833b6ca3088475038bc0
endif
HOST_PV_PVR_SDK		:= pv-pvr-sdk-$(HOST_PV_PVR_SDK_MACHINE)-$(HOST_PV_PVR_SDK_VERSION)
HOST_PV_PVR_SDK_SUFFIX	:= pvrexport.tgz
HOST_PV_PVR_SDK_URL	:= https://pantavisor-ci.s3.amazonaws.com/meta-pantavisor/containers/$(HOST_PV_PVR_SDK_VERSION)/pv-pvr-sdk-docker-$(HOST_PV_PVR_SDK_MACHINE)-scarthgap/pv-pvr-sdk-$(HOST_PV_PVR_SDK_MACHINE).$(HOST_PV_PVR_SDK_SUFFIX)
HOST_PV_PVR_SDK_SOURCE	:= $(SRCDIR)/$(HOST_PV_PVR_SDK).$(HOST_PV_PVR_SDK_SUFFIX)
HOST_PV_PVR_SDK_DIR	:= $(HOST_BUILDDIR)/$(HOST_PV_PVR_SDK)
HOST_PV_PVR_SDK_LICENSE	:= ignore

# The pvrexport is deployed as is, not unpacked.
$(STATEDIR)/host-pv-pvr-sdk.extract:
	@$(call targetinfo)
	@mkdir -p $(HOST_PV_PVR_SDK_DIR)
	@$(call touch)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

HOST_PV_PVR_SDK_CONF_TOOL	:= NO

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

$(STATEDIR)/host-pv-pvr-sdk.compile:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/host-pv-pvr-sdk.install:
	@$(call targetinfo)
	@install -D -m 0644 $(HOST_PV_PVR_SDK_SOURCE) \
		$(HOST_PV_PVR_SDK_PKGDIR)/usr/share/pantavisor/containers/pv-pvr-sdk.pvrexport.tgz
	@$(call touch)

# vim: syntax=make
