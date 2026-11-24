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
PACKAGES-$(PTXCONF_LIBEVENT_PV) += libevent-pv

#
# Paths and names
#
# 2.2.1-alpha is the first release with the bufferevent mbed TLS backend.
LIBEVENT_PV_VERSION	:= 2.2.1
LIBEVENT_PV_API		:= 2.2
LIBEVENT_PV_SHA256	:= 36d0726e570fc2ee61a0a27cfb6bf2799e14a28d030a7473a7a2411f7533d359
LIBEVENT_PV		:= libevent-pv-$(LIBEVENT_PV_VERSION)-alpha-dev
LIBEVENT_PV_SUFFIX	:= tar.gz
LIBEVENT_PV_URL		:= https://github.com/libevent/libevent/releases/download/release-$(LIBEVENT_PV_VERSION)-alpha/libevent-$(LIBEVENT_PV_VERSION)-alpha-dev.$(LIBEVENT_PV_SUFFIX)
LIBEVENT_PV_SOURCE	:= $(SRCDIR)/libevent-$(LIBEVENT_PV_VERSION)-alpha-dev.$(LIBEVENT_PV_SUFFIX)
LIBEVENT_PV_DIR		:= $(BUILDDIR)/$(LIBEVENT_PV)
LIBEVENT_PV_LICENSE	:= BSD-3-Clause AND MIT
LIBEVENT_PV_LICENSE_FILES	:= \
	file://LICENSE;md5=eaea438df011ea096feec284927c59e0

# Private sysroot prefix: libevent 2.1 installs the same headers,
# libevent.so and libevent.pc to /usr. Only Pantavisor looks here.
LIBEVENT_PV_PREFIX	:= /usr/lib/libevent-$(LIBEVENT_PV_API)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

#
# autoconf
#
LIBEVENT_PV_CONF_TOOL	:= autoconf
LIBEVENT_PV_CONF_OPT	:= \
	$(CROSS_AUTOCONF_USR) \
	--bindir=$(LIBEVENT_PV_PREFIX)/bin \
	--includedir=$(LIBEVENT_PV_PREFIX)/include \
	--libdir=$(LIBEVENT_PV_PREFIX)/lib \
	--disable-shared \
	--enable-static \
	--with-pic \
	--disable-gcc-warnings \
	--enable-gcc-hardening \
	--enable-thread-support \
	--disable-malloc-replacement \
	--disable-openssl \
	--enable-mbedtls \
	--$(call ptx/endis, PTXCONF_LIBEVENT_PV_DEBUG_MODE)-debug-mode \
	--enable-libevent-install \
	--disable-libevent-regress \
	--disable-samples \
	--enable-function-sections \
	--disable-verbose-debug \
	--enable-clock-gettime \
	$(GLOBAL_LARGE_FILE_OPTION) \
	--disable-doxygen-doc

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

# Static only: Pantavisor carries what it uses, nothing goes on the target.
$(STATEDIR)/libevent-pv.targetinstall:
	@$(call targetinfo)
	@$(call touch)

# vim: syntax=make
