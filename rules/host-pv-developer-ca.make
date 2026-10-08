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
HOST_PACKAGES-$(PTXCONF_HOST_PV_DEVELOPER_CA) += host-pv-developer-ca

#
# Paths and names
#
# Same revision and archive meta-pantavisor uses (classes/pvr-ca.bbclass).
HOST_PV_DEVELOPER_CA_VERSION	:= 2340d747c4acd0a1a702b3d7d5acc014b51daaa7
HOST_PV_DEVELOPER_CA_SHA256	:= f7c8470b3ccd8be23974a5cf2469b59a2e39702d40a2fe4ae5bfa01399817816
HOST_PV_DEVELOPER_CA		:= pv-developer-ca-$(HOST_PV_DEVELOPER_CA_VERSION)
HOST_PV_DEVELOPER_CA_SUFFIX	:= tar.gz
HOST_PV_DEVELOPER_CA_URL	:= https://gitlab.com/api/v4/projects/pantacor%2Fpv-developer-ca/repository/archive.tar.gz?sha=$(HOST_PV_DEVELOPER_CA_VERSION)
HOST_PV_DEVELOPER_CA_SOURCE	:= $(SRCDIR)/$(HOST_PV_DEVELOPER_CA).$(HOST_PV_DEVELOPER_CA_SUFFIX)
HOST_PV_DEVELOPER_CA_DIR	:= $(HOST_BUILDDIR)/$(HOST_PV_DEVELOPER_CA)
HOST_PV_DEVELOPER_CA_LICENSE	:= ignore

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

HOST_PV_DEVELOPER_CA_CONF_TOOL	:= NO

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

$(STATEDIR)/host-pv-developer-ca.compile:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/host-pv-developer-ca.install:
	@$(call targetinfo)
	@install -D -m 0644 $(HOST_PV_DEVELOPER_CA_DIR)/pvs/pvs.defaultkeys.tar.gz \
		$(HOST_PV_DEVELOPER_CA_PKGDIR)/usr/share/pantavisor/pvs.defaultkeys.tar.gz
	@$(call touch)

# vim: syntax=make
