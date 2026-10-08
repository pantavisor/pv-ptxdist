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
PACKAGES-$(PTXCONF_LXC_PV) += lxc-pv

#
# Paths and names
#
# Pinned to the revision used by meta-pantavisor
# (branch stable-3.0-BASE-2c5c780762981a5cfe699670c91397e29f6f6516).
LXC_PV_COMMIT	:= c6bc8bc4af46a9250d250bad7b2e430d9fad1019
LXC_PV_VERSION	:= 3.0.4-pv-c6bc8bc4
LXC_PV_SHA256	:= 8ab93444189c14941842156f262ee79c136a38ada67c9878b79e37742b8c4d4a
LXC_PV		:= lxc-pv-$(LXC_PV_VERSION)
LXC_PV_SUFFIX	:= tar.gz
LXC_PV_URL	:= https://github.com/pantavisor/lxc.git;tag=$(LXC_PV_COMMIT)
LXC_PV_SOURCE	:= $(SRCDIR)/$(LXC_PV).$(LXC_PV_SUFFIX)
LXC_PV_DIR	:= $(BUILDDIR)/$(LXC_PV)
LXC_PV_LICENSE	:= LGPL-2.1-or-later AND GPL-2.0-only
LXC_PV_LICENSE_FILES := \
	file://LICENSE.LGPL2.1;md5=4fbd65380cdd255951079008b364516c \
	file://LICENSE.GPL2;md5=751419260aa954499f7abaabaa882bbe

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

LXC_PV_CONF_TOOL	:= autoconf
LXC_PV_CONF_OPT		:= \
	$(CROSS_AUTOCONF_USR) \
	--localstatedir=/usr/var \
	--enable-shared \
	--disable-static \
	--disable-werror \
	--disable-rpath \
	--disable-doc \
	--disable-api-docs \
	--disable-apparmor \
	--disable-openssl \
	--disable-selinux \
	--disable-seccomp \
	--enable-capabilities \
	--disable-examples \
	--disable-mutex-debugging \
	--disable-bash \
	--enable-tools \
	--enable-commands \
	--disable-tests \
	--disable-pam \
	--with-distro=debian \
	--with-init-script=sysvinit

# GCC 15 turns these into errors on the 3.0 code base (same set as
# meta-pantavisor's EXTRA_OECONF).
LXC_PV_CFLAGS		:= \
	-Wno-error=strict-prototypes \
	-Wno-error=old-style-definition \
	-Wno-error=stringop-overflow \
	-Wno-error=stringop-overread

LXC_PV_TOOLS_LIST := \
	console \
	info \
	ls \
	top

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/lxc-pv.targetinstall:
	@$(call targetinfo)

	@$(call install_init, lxc-pv)
	@$(call install_fixup, lxc-pv,PRIORITY,optional)
	@$(call install_fixup, lxc-pv,SECTION,base)
	@$(call install_fixup, lxc-pv,AUTHOR,"Fernando Luiz Cola <fernando.luiz@pantacor.com>")
	@$(call install_fixup, lxc-pv,DESCRIPTION,"Linux Containers (Pantacor fork)")

	@$(call install_lib, lxc-pv, 0, 0, 0644, liblxc)
	@$(call install_copy, lxc-pv, 0, 0, 0755, /usr/lib/lxc/rootfs)
	@$(call install_copy, lxc-pv, 0, 0, 0755, /usr/var/lib/lxc)
	@$(call install_tree, lxc-pv, 0, 0, -, /usr/libexec/lxc)

ifdef PTXCONF_LXC_PV_TOOLS
	@$(foreach app, $(LXC_PV_TOOLS_LIST), \
		$(call install_copy, lxc-pv, 0, 0, 0755, -, \
			/usr/bin/lxc-$(app))$(ptx/nl))
endif

	@$(call install_finish, lxc-pv)

	@$(call touch)

# vim: syntax=make
