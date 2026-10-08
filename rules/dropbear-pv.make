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
PACKAGES-$(PTXCONF_DROPBEAR_PV) += dropbear-pv

#
# Paths and names
#
# Pinned to the revision used by meta-pantavisor (branch pv/master).
DROPBEAR_PV_COMMIT	:= a5052fd488a1071ae7b0ee0877f6b0e17bc2a216
DROPBEAR_PV_VERSION	:= 2020.81-pv-a5052fd4
DROPBEAR_PV_SHA256	:= edfe9591e57b26ad4ad5112bb5de20bb20d4f4cd839ef03ccdce124b4cf371a2
DROPBEAR_PV		:= dropbear-pv-$(DROPBEAR_PV_VERSION)
DROPBEAR_PV_SUFFIX	:= tar.gz
DROPBEAR_PV_URL		:= https://github.com/pantacor/dropbear-pv.git;tag=$(DROPBEAR_PV_COMMIT)
DROPBEAR_PV_SOURCE	:= $(SRCDIR)/$(DROPBEAR_PV).$(DROPBEAR_PV_SUFFIX)
DROPBEAR_PV_DIR		:= $(BUILDDIR)/$(DROPBEAR_PV)
DROPBEAR_PV_LICENSE	:= MIT AND BSD-3-Clause AND BSD-2-Clause AND public_domain
DROPBEAR_PV_LICENSE_FILES := \
	file://LICENSE;md5=25cf44512b7bc8966a48b6b1a9b7605f

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

DROPBEAR_PV_CONF_TOOL	:= autoconf
DROPBEAR_PV_CONF_OPT	:= \
	$(CROSS_AUTOCONF_USR) \
	--disable-harden \
	--enable-zlib

DROPBEAR_PV_MAKE_OPT	:= \
	MULTI=1 \
	SCPPROGRESS=1 \
	PROGRAMS=dropbear

# The upstream install target ignores MULTI=1; only dropbearmulti is needed.
$(STATEDIR)/dropbear-pv.install:
	@$(call targetinfo)
	@install -D -m 0755 $(DROPBEAR_PV_DIR)/dropbearmulti \
		$(DROPBEAR_PV_PKGDIR)/usr/sbin/dropbearmulti
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/dropbear-pv.targetinstall:
	@$(call targetinfo)

	@$(call install_init, dropbear-pv)
	@$(call install_fixup, dropbear-pv,PRIORITY,optional)
	@$(call install_fixup, dropbear-pv,SECTION,base)
	@$(call install_fixup, dropbear-pv,AUTHOR,"Fernando Luiz Cola <fernando.luiz@pantacor.com>")
	@$(call install_fixup, dropbear-pv,DESCRIPTION,"SSH server for Pantavisor")

	@$(call install_copy, dropbear-pv, 0, 0, 0755, -, /usr/sbin/dropbearmulti)
	@$(call install_link, dropbear-pv, dropbearmulti, /usr/sbin/dropbear)
	@$(call install_copy, dropbear-pv, 0, 0, 0755, /etc/dropbear)

	@$(call install_finish, dropbear-pv)

	@$(call touch)

# vim: syntax=make
