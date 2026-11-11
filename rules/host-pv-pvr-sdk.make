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
HOST_PV_PVR_SDK_VERSION	:= 031-rc8
ifdef PTXCONF_ARCH_ARM64
HOST_PV_PVR_SDK_MACHINE	:= armv8
HOST_PV_PVR_SDK_SHA256	:= 25acded91785d439a5e3b0aea107718035375e7833ba3ea402549ec87d37bb36
endif
ifdef PTXCONF_ARCH_ARM
HOST_PV_PVR_SDK_MACHINE	:= armv6
HOST_PV_PVR_SDK_SHA256	:= c0e03618c2f54d6723cb91d99ce1f5a51c40cc327b19f8c44211ddd0cda998a2
endif
ifdef PTXCONF_ARCH_X86_64
HOST_PV_PVR_SDK_MACHINE	:= x86_64
HOST_PV_PVR_SDK_SHA256	:= d405daa53e95c52e6318e1be87a2f8fce258420a23c73b5b9c689d706baa50dc
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
