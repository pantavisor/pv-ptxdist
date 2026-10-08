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
# Pinned to the revision used by meta-pantavisor (branch pv/master).
PICOHTTPPARSER_VERSION	:= facd3dafae02558cddb751d9f64df03bb259d4d3
PICOHTTPPARSER_SHA256	:= bc5298ff927c5c705f3fb0838f285746062fc8edfbfaa6ac772b47c7a40b207b
PICOHTTPPARSER		:= picohttpparser-$(PICOHTTPPARSER_VERSION)
PICOHTTPPARSER_SUFFIX	:= tar.gz
PICOHTTPPARSER_URL	:= https://github.com/pantavisor/picohttpparser.git;tag=$(PICOHTTPPARSER_VERSION)
PICOHTTPPARSER_SOURCE	:= $(SRCDIR)/$(PICOHTTPPARSER).$(PICOHTTPPARSER_SUFFIX)
PICOHTTPPARSER_DIR	:= $(BUILDDIR)/$(PICOHTTPPARSER)
PICOHTTPPARSER_LICENSE	:= MIT OR Artistic-1.0-Perl
PICOHTTPPARSER_LICENSE_FILES := \
	file://README.md;startline=15;endline=15;md5=2de1ac72f36ce42f3efb6ff77f421343

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

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
