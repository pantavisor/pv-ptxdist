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
PACKAGES-$(PTXCONF_PICOHTTPPARSER) += picohttpparser

#
# Paths and names
#
# Upstream has no releases. The revision meta-pantavisor builds; its
# github.com/pantavisor/picohttpparser fork adds only the CMake build
# (patches/).
PICOHTTPPARSER_VERSION	:= 2021-02-24-g066d2b1e9ab8
PICOHTTPPARSER_SHA256	:= 63144ca669204315e62a7abc23a1f487375dc3fe4d9ebbd694a6706a09d9e535
PICOHTTPPARSER		:= picohttpparser-$(PICOHTTPPARSER_VERSION)
PICOHTTPPARSER_SUFFIX	:= tar.gz
PICOHTTPPARSER_URL	:= git+https://github.com/h2o/picohttpparser.git;tag=$(PICOHTTPPARSER_VERSION)
PICOHTTPPARSER_SOURCE	:= $(SRCDIR)/$(PICOHTTPPARSER).$(PICOHTTPPARSER_SUFFIX)
PICOHTTPPARSER_DIR	:= $(BUILDDIR)/$(PICOHTTPPARSER)
PICOHTTPPARSER_LICENSE	:= MIT OR Artistic-1.0-Perl
PICOHTTPPARSER_LICENSE_FILES := \
	file://README.md;startline=15;endline=15;md5=2de1ac72f36ce42f3efb6ff77f421343

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# Static library linked into Pantavisor's executables and its pv_lxc.so
# plugin, hence PIC.
PICOHTTPPARSER_CONF_TOOL	:= cmake
PICOHTTPPARSER_CONF_OPT		:= \
	$(CROSS_CMAKE_USR) \
	-DCMAKE_POSITION_INDEPENDENT_CODE=ON

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/picohttpparser.targetinstall:
	@$(call targetinfo)
	@$(call touch)

# vim: syntax=make
