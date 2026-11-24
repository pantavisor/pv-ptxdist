# -*-makefile-*-
#
# Copyright (C) 2026 by Fernando Luiz Cola <fernando.luiz@pantacor.com>
# Based on rules/libevent.make by Michael Olbrich and Marc Kleine-Budde.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_LIBEVENT22) += libevent22

#
# Paths and names
#
# 2.2 has only alpha releases so far; drop this package for a libevent bump
# once 2.2 is stable.
LIBEVENT22_VERSION	:= 2.2.2-alpha
LIBEVENT22_API		:= 2.2
LIBEVENT22_SHA256	:= 4ab1b369bcb5af0c5971b8ade4e95a2c1326f6d0dc1ba75d620bf0331c3184a8
LIBEVENT22		:= libevent22-$(LIBEVENT22_VERSION)
LIBEVENT22_SUFFIX	:= tar.gz
LIBEVENT22_URL		:= https://github.com/libevent/libevent/releases/download/release-$(LIBEVENT22_VERSION)/libevent-$(LIBEVENT22_VERSION).$(LIBEVENT22_SUFFIX)
LIBEVENT22_SOURCE	:= $(SRCDIR)/libevent-$(LIBEVENT22_VERSION).$(LIBEVENT22_SUFFIX)
LIBEVENT22_DIR		:= $(BUILDDIR)/$(LIBEVENT22)
LIBEVENT22_LICENSE	:= BSD-3-Clause AND 0BSD AND MIT
LIBEVENT22_LICENSE_FILES	:= \
	file://LICENSE;md5=eaea438df011ea096feec284927c59e0

# Private sysroot prefix: libevent 2.1 installs the same headers,
# libevent.so and libevent.pc to /usr.
LIBEVENT22_PREFIX	:= /usr/lib/libevent-$(LIBEVENT22_API)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# The directory options follow CROSS_AUTOCONF_USR, whose --libdir they
# override.
LIBEVENT22_CONF_TOOL	:= autoconf
LIBEVENT22_CONF_OPT	:= \
	$(CROSS_AUTOCONF_USR) \
	--bindir=$(LIBEVENT22_PREFIX)/bin \
	--includedir=$(LIBEVENT22_PREFIX)/include \
	--libdir=$(LIBEVENT22_PREFIX)/lib \
	--disable-gcc-warnings \
	--enable-gcc-hardening \
	--enable-thread-support \
	--disable-malloc-replacement \
	--disable-openssl \
	--enable-mbedtls \
	--$(call ptx/endis, PTXCONF_LIBEVENT22_DEBUG_MODE)-debug-mode \
	--enable-libevent-install \
	--disable-libevent-regress \
	--disable-samples \
	--enable-function-sections \
	--disable-verbose-debug \
	--enable-clock-gettime \
	--disable-shared \
	--enable-static \
	--enable-pic \
	$(GLOBAL_LARGE_FILE_OPTION) \
	--disable-doxygen-doc \
	--disable-doxygen-dot \
	--disable-doxygen-man \
	--disable-doxygen-rtf \
	--disable-doxygen-xml \
	--disable-doxygen-chm \
	--disable-doxygen-chi \
	--disable-doxygen-html \
	--disable-doxygen-ps \
	--disable-doxygen-pdf \
	--$(call ptx/endis, PTXDIST_Y2038)-year2038

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

# Static only: users link what they need, nothing goes on the target.
$(STATEDIR)/libevent22.targetinstall:
	@$(call targetinfo)
	@$(call touch)

# vim: syntax=make
