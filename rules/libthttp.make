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
LIBTHTTP_LICENSE	:= MIT AND MPL-2.0
LIBTHTTP_LICENSE_FILES	:= \
	file://LICENSE;md5=bd0a4fad56a916f12a1c3cedb3976612

# The root CAs come from the Mozilla list that PTXdist's ca-certificates
# package uses, at the same NSS version, but the whole bundle is not
# installed: the initramfs only gets the roots in LIBTHTTP_CA_CERTS. The part
# has no _DIR, so PTXdist downloads and checks it without extracting it.
# The certificates on the target are MPL-2.0, hence the package license.
LIBTHTTP_CERTDATA_VERSION	:= NSS_3_123_RTM
LIBTHTTP_CERTDATA_SHA256	:= 77130ef91213772844561fbd3aa31d413b25c2ac7f576fea3bc3bbff7ef93489
LIBTHTTP_CERTDATA_URL		:= https://hg.mozilla.org/projects/nss/raw-file/$(LIBTHTTP_CERTDATA_VERSION)/lib/ckfw/builtins/certdata.txt
LIBTHTTP_CERTDATA_SOURCE	:= $(SRCDIR)/certdata-$(LIBTHTTP_CERTDATA_VERSION).txt
LIBTHTTP_PARTS			+= LIBTHTTP_CERTDATA

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

LIBTHTTP_CONF_TOOL	:= cmake
LIBTHTTP_CONF_OPT	:= \
	$(CROSS_CMAKE_USR) \
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
		python3 $(call ptx/in-path, PTXDIST_PATH_SCRIPTS, certdata2pem.py) > /dev/null
	@found=0; \
	for name in $(LIBTHTTP_CA_CERTS); do \
		if [ -f "$(LIBTHTTP_CERTS_DIR)/$${name}.crt" ]; then \
			install -m 0644 "$(LIBTHTTP_CERTS_DIR)/$${name}.crt" \
				$(LIBTHTTP_PKGDIR)/etc/thttp/certs/; \
			found=$$((found + 1)); \
		else \
			echo "warning: LIBTHTTP_CA_CERTS: $${name} is not in NSS $(LIBTHTTP_CERTDATA_VERSION), skipping" >&2; \
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
