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
PACKAGES-$(PTXCONF_LIBTHTTP) += libthttp

#
# Paths and names
#
# Pinned to the revision used by meta-pantavisor (011+git, branch master).
LIBTHTTP_VERSION	:= ce916c562c5b11bcb0b5165043ded543dfea322a
LIBTHTTP_SHA256		:= 5b2bf2981576c0582b9edd8339491d9af370b84f6fba67b97507257918bd29c1
LIBTHTTP		:= libthttp-$(LIBTHTTP_VERSION)
LIBTHTTP_SUFFIX		:= tar.gz
LIBTHTTP_URL		:= https://github.com/pantavisor/libthttp.git;tag=$(LIBTHTTP_VERSION)
LIBTHTTP_SOURCE		:= $(SRCDIR)/$(LIBTHTTP).$(LIBTHTTP_SUFFIX)
LIBTHTTP_DIR		:= $(BUILDDIR)/$(LIBTHTTP)
LIBTHTTP_LICENSE	:= MIT
LIBTHTTP_LICENSE_FILES	:= \
	file://LICENSE;md5=bd0a4fad56a916f12a1c3cedb3976612

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

LIBTHTTP_CONF_TOOL	:= cmake
LIBTHTTP_CONF_OPT	:= \
	$(CROSS_CMAKE_USR) \
	-DCMAKE_POSITION_INDEPENDENT_CODE=ON

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/libthttp.targetinstall:
	@$(call targetinfo)

	@$(call install_init, libthttp)
	@$(call install_fixup, libthttp,PRIORITY,optional)
	@$(call install_fixup, libthttp,SECTION,base)
	@$(call install_fixup, libthttp,AUTHOR,"Fernando Luiz Cola <fernando.luiz@pantacor.com>")
	@$(call install_fixup, libthttp,DESCRIPTION,"libthttp TLS root certificates")

	@$(call install_tree, libthttp, 0, 0, -, /etc/thttp/certs)

	@$(call install_finish, libthttp)

	@$(call touch)

# vim: syntax=make
