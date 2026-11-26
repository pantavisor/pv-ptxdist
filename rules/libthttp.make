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
# The revision meta-pantavisor builds: 76 commits after the last tag (011).
LIBTHTTP_VERSION	:= 011-76-gff79603fc178
LIBTHTTP_SHA256		:= 98452b92c86a211bbb4fe8790c04f344f3cf0274b816da58bd2d51e6fb745f4f
LIBTHTTP		:= libthttp-$(LIBTHTTP_VERSION)
LIBTHTTP_SUFFIX		:= tar.gz
LIBTHTTP_URL		:= git+https://github.com/pantavisor/libthttp.git;tag=$(LIBTHTTP_VERSION)
LIBTHTTP_SOURCE		:= $(SRCDIR)/$(LIBTHTTP).$(LIBTHTTP_SUFFIX)
LIBTHTTP_DIR		:= $(BUILDDIR)/$(LIBTHTTP)
LIBTHTTP_LICENSE	:= MIT AND MPL-2.0
LIBTHTTP_LICENSE_FILES	:= \
	file://LICENSE;md5=bd0a4fad56a916f12a1c3cedb3976612

# The root CAs come from ca-certificates' certdata.txt, but the whole bundle
# is not installed: the initramfs only gets the roots in LIBTHTTP_CA_CERTS.
# The part has no _DIR, so PTXdist downloads and checks it without
# extracting it. The certificates on the target are MPL-2.0, hence the
# package license.
LIBTHTTP_CERTDATA_SHA256	 = $(CA_CERTIFICATES_SHA256)
LIBTHTTP_CERTDATA_URL		 = $(CA_CERTIFICATES_URL)
LIBTHTTP_CERTDATA_SOURCE	 = $(CA_CERTIFICATES_SOURCE)
LIBTHTTP_PARTS			+= LIBTHTTP_CERTDATA

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# mbedtls36's private prefix (MBEDTLS36_PREFIX), spelled out because rule
# files are not included in a fixed order. The include path goes into
# CPPFLAGS as well: CMakeLists.txt finds MBEDTLS_INCLUDE_DIRS but passes
# MBEDTLS_INCLUDE_DIR to include_directories().
LIBTHTTP_MBEDTLS_PREFIX	:= /usr/lib/mbedtls-3.6
LIBTHTTP_CPPFLAGS	:= -I$(PTXDIST_SYSROOT_TARGET)$(LIBTHTTP_MBEDTLS_PREFIX)/include

# Static library linked into Pantavisor's executables and its pv_lxc.so
# plugin, hence PIC.
LIBTHTTP_CONF_TOOL	:= cmake
LIBTHTTP_CONF_OPT	:= \
	$(CROSS_CMAKE_USR) \
	-DCMAKE_PREFIX_PATH=$(LIBTHTTP_MBEDTLS_PREFIX) \
	-DCMAKE_POSITION_INDEPENDENT_CODE=ON

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

LIBTHTTP_CERTS_DIR	:= $(LIBTHTTP_DIR)-certdata
LIBTHTTP_CA_CERTS	:= $(call remove_quotes, $(PTXCONF_LIBTHTTP_CA_CERTS))

$(STATEDIR)/libthttp.install:
	@$(call targetinfo)
	@$(call world/install, LIBTHTTP)
	@rm -rf $(LIBTHTTP_CERTS_DIR) $(LIBTHTTP_PKGDIR)/etc/thttp/certs
	@mkdir -p $(LIBTHTTP_CERTS_DIR) $(LIBTHTTP_PKGDIR)/etc/thttp/certs
	@cp $(LIBTHTTP_CERTDATA_SOURCE) $(LIBTHTTP_CERTS_DIR)/certdata.txt
	@cd $(LIBTHTTP_CERTS_DIR) && \
		python3 $(CA_CERTIFICATES_CERTDATA2PEM) > /dev/null
	@found=0; \
	for name in $(LIBTHTTP_CA_CERTS); do \
		if [ -f "$(LIBTHTTP_CERTS_DIR)/$${name}.crt" ]; then \
			install -m 0644 "$(LIBTHTTP_CERTS_DIR)/$${name}.crt" \
				$(LIBTHTTP_PKGDIR)/etc/thttp/certs/; \
			found=$$((found + 1)); \
		else \
			echo "warning: LIBTHTTP_CA_CERTS: $${name} is not in $(CA_CERTIFICATES_VERSION), skipping" >&2; \
		fi; \
	done; \
	if [ $${found} -eq 0 ]; then \
		echo "error: LIBTHTTP_CA_CERTS: no root certificate installed" >&2; \
		exit 1; \
	fi
	@$(call touch)

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
