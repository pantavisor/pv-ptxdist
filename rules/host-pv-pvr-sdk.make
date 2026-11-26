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
# (the list behind pantavisor.io/downloads).
HOST_PV_PVR_SDK_VERSION	:= 031
ifdef PTXCONF_ARCH_ARM64
HOST_PV_PVR_SDK_MACHINE	:= armv8
HOST_PV_PVR_SDK_SHA256	:= 5958a9a69e4d92f0f81b707855b82e8c87a1cb46b037fc6ee4deb5ae7082c556
endif
ifdef PTXCONF_ARCH_ARM
HOST_PV_PVR_SDK_MACHINE	:= armv6
HOST_PV_PVR_SDK_SHA256	:= 90710ddac1f4366cdccc2b00605d80bd48bcaaacdfe73e1887361e005299a6d4
endif
ifdef PTXCONF_ARCH_X86_64
HOST_PV_PVR_SDK_MACHINE	:= x86_64
HOST_PV_PVR_SDK_SHA256	:= 02d26d63a0d5c2cdf4603ab8fcd13feadc83658b3ca5e29c71429d1730efb55c
endif
HOST_PV_PVR_SDK		:= pv-pvr-sdk-$(HOST_PV_PVR_SDK_MACHINE)-$(HOST_PV_PVR_SDK_VERSION)
HOST_PV_PVR_SDK_SUFFIX	:= pvrexport.tgz
HOST_PV_PVR_SDK_URL	:= https://pantavisor-ci.s3.amazonaws.com/meta-pantavisor/containers/$(HOST_PV_PVR_SDK_VERSION)/pv-pvr-sdk-docker-$(HOST_PV_PVR_SDK_MACHINE)-scarthgap/pv-pvr-sdk-$(HOST_PV_PVR_SDK_MACHINE).$(HOST_PV_PVR_SDK_SUFFIX)
HOST_PV_PVR_SDK_SOURCE	:= $(SRCDIR)/$(HOST_PV_PVR_SDK).$(HOST_PV_PVR_SDK_SUFFIX)
HOST_PV_PVR_SDK_DIR	:= $(HOST_BUILDDIR)/$(HOST_PV_PVR_SDK)
# The pvr-sdk repo is MIT, but the container also carries Alpine packages
# with no license list (meta-pantavisor declares it CLOSED). It ends up on
# the device, so keep it in the license report rather than ignore it.
HOST_PV_PVR_SDK_LICENSE	:= MIT AND unknown

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
