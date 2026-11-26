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
# github.com/pantavisor/picohttpparser fork adds only a CMake build.
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

# Upstream has no build system for the library (its Makefile only builds the
# tests) and expects users to copy picohttpparser.{c,h}. Build the static
# library here instead of carrying a build system as a patch.
PICOHTTPPARSER_CONF_TOOL	:= NO

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

# PIC: Pantavisor links it into its executables and its pv_lxc.so plugin.
# -O2 -DNDEBUG as CMake's RelWithDebInfo; the wrapper adds -g.
$(STATEDIR)/picohttpparser.compile:
	@$(call targetinfo)
	@$(call world/execute, PICOHTTPPARSER, \
		$(CROSS_CC) -O2 -DNDEBUG -fPIC -c picohttpparser.c -o picohttpparser.o && \
		$(CROSS_AR) rcs libpicohttpparser.a picohttpparser.o)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/picohttpparser.install:
	@$(call targetinfo)
	@$(call world/execute, PICOHTTPPARSER, \
		install -D -m 0644 picohttpparser.h \
			$(PICOHTTPPARSER_PKGDIR)/usr/include/picohttpparser.h && \
		install -D -m 0644 libpicohttpparser.a \
			$(PICOHTTPPARSER_PKGDIR)/usr/lib/libpicohttpparser.a)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/picohttpparser.targetinstall:
	@$(call targetinfo)
	@$(call touch)

# vim: syntax=make
