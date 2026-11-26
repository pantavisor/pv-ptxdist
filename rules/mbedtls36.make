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
PACKAGES-$(PTXCONF_MBEDTLS36) += mbedtls36

#
# Paths and names
#
MBEDTLS36_VERSION	:= 3.6.8
MBEDTLS36_SHA256	:= bc54b818e87f49c0b3281dd85d24adaede0e63b4e822e3fbd49c005a38b9595b
MBEDTLS36		:= mbedtls36-$(MBEDTLS36_VERSION)
MBEDTLS36_SUFFIX	:= tar.bz2
MBEDTLS36_URL		:= https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$(MBEDTLS36_VERSION)/mbedtls-$(MBEDTLS36_VERSION).$(MBEDTLS36_SUFFIX)
MBEDTLS36_SOURCE	:= $(SRCDIR)/mbedtls-$(MBEDTLS36_VERSION).$(MBEDTLS36_SUFFIX)
MBEDTLS36_DIR		:= $(BUILDDIR)/$(MBEDTLS36)
MBEDTLS36_LICENSE	:= Apache-2.0 OR GPL-2.0-or-later
MBEDTLS36_LICENSE_FILES	:= file://LICENSE;md5=379d5819937a6c2f1ef1630d341e026d

# Relative to /usr, so the pkg-config and CMake files point here as well.
MBEDTLS36_PREFIX	:= /usr/lib/mbedtls-3.6

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# Static, and PIC for the libraries and plugins that link it.
MBEDTLS36_CONF_TOOL	:= cmake
MBEDTLS36_CONF_OPT	:= \
	$(CROSS_CMAKE_USR) \
	-DCMAKE_INSTALL_INCLUDEDIR=lib/mbedtls-3.6/include \
	-DCMAKE_INSTALL_LIBDIR=lib/mbedtls-3.6/lib \
	-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
	-DDISABLE_PACKAGE_CONFIG_AND_INSTALL=OFF \
	-DENABLE_PROGRAMS=OFF \
	-DENABLE_TESTING=OFF \
	-DGEN_FILES=OFF \
	-DINSTALL_MBEDTLS_HEADERS=ON \
	-DLINK_WITH_PTHREAD=ON \
	-DLINK_WITH_TRUSTED_STORAGE=OFF \
	-DMBEDTLS_CONFIG_BASE_FILE= \
	-DMBEDTLS_CONFIG_FILE= \
	-DMBEDTLS_CONFIG_NAME= \
	-DMBEDTLS_CONFIG_SET= \
	-DMBEDTLS_CONFIG_UNSET= \
	-DMBEDTLS_FATAL_WARNINGS=OFF \
	-DMBEDTLS_USER_CONFIG_FILE= \
	-DUNSAFE_BUILD=OFF \
	-DUSE_SHARED_MBEDTLS_LIBRARY=OFF \
	-DUSE_STATIC_MBEDTLS_LIBRARY=ON

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/mbedtls36.targetinstall:
	@$(call targetinfo)
	@$(call touch)

# vim: syntax=make
