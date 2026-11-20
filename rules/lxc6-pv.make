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
PACKAGES-$(PTXCONF_LXC6_PV) += lxc6-pv

#
# Paths and names
#
# Pinned to the revision used by meta-pantavisor's lxc6-pv
# (branch stable-6.0-BASE-f9ff9ea2a, upstream v6.0.5 + 31).
LXC6_PV_COMMIT	:= bfa6810a38463bb995d8c7aa7ed7788b53cb25af
LXC6_PV_VERSION	:= 6.0.5-pv-bfa6810a
LXC6_PV_SHA256	:= 91fcec675b476d5a55fbac287ece09aa7b8e8448a772a3edd7666361fb45d46c
LXC6_PV		:= lxc6-pv-$(LXC6_PV_VERSION)
LXC6_PV_SUFFIX	:= tar.gz
LXC6_PV_URL	:= https://github.com/pantavisor/lxc.git;tag=$(LXC6_PV_COMMIT)
LXC6_PV_SOURCE	:= $(SRCDIR)/$(LXC6_PV).$(LXC6_PV_SUFFIX)
LXC6_PV_DIR	:= $(BUILDDIR)/$(LXC6_PV)
LXC6_PV_LICENSE	:= LGPL-2.1-or-later AND GPL-2.0-only
LXC6_PV_LICENSE_FILES := \
	file://COPYING;md5=4b6551da9cb7d5b3017d1c0a3e31469b \
	file://LICENSE.LGPL2.1;md5=4fbd65380cdd255951079008b364516c \
	file://LICENSE.GPL2;md5=751419260aa954499f7abaabaa882bbe

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# localstatedir is /usr/var so that lxc-ls finds the containers Pantavisor
# creates in /usr/var/lib/lxc (PV_SYSTEM_USRDIR=/usr), as with lxc-pv.
LXC6_PV_CONF_TOOL	:= meson
LXC6_PV_CONF_OPT	:= \
	$(CROSS_MESON_USR) \
	-Dlocalstatedir=/usr/var \
	-Dapparmor=false \
	-Dapparmor-cache-path=cache/lxc/apparmor \
	-Dcapabilities=true \
	-Dcgroup-pattern= \
	-Dcommands=true \
	-Dcoverity-build=false \
	-Ddata-path=lib/lxc \
	-Ddbus=false \
	-Ddistrosysconfdir= \
	-Ddoc-path=doc/lxc \
	-Dexamples=false \
	-Dglobal-config-path=lxc \
	-Dinit-script=[] \
	-Dinstall-init-files=false \
	-Dinstall-state-dirs=false \
	-Dio-uring-event-loop=false \
	-Dlog-path=log/lxc \
	-Dman=false \
	-Dmemfd-rexec=true \
	-Dopenssl=false \
	-Doss-fuzz=false \
	-Dpam-cgroup=false \
	-Drootfs-mount-path=lxc/rootfs \
	-Druntime-path=/run \
	-Dseccomp=false \
	-Dselinux=false \
	-Dspecfile=false \
	-Dsystemd-unitdir= \
	-Dtests=false \
	-Dthread-safety=true \
	-Dtools=true \
	-Dtools-multicall=false \
	-Dusernet-config-path=lxc/lxc-usernet \
	-Dusernet-db-path=lxc/nics

LXC6_PV_TOOLS_LIST := \
	console \
	info \
	ls \
	top

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/lxc6-pv.targetinstall:
	@$(call targetinfo)

	@$(call install_init, lxc6-pv)
	@$(call install_fixup, lxc6-pv,PRIORITY,optional)
	@$(call install_fixup, lxc6-pv,SECTION,base)
	@$(call install_fixup, lxc6-pv,AUTHOR,"Fernando Luiz Cola <fernando.luiz@pantacor.com>")
	@$(call install_fixup, lxc6-pv,DESCRIPTION,"Linux Containers 6 (Pantacor fork)")

	@$(call install_lib, lxc6-pv, 0, 0, 0644, liblxc)
	@$(call install_copy, lxc6-pv, 0, 0, 0755, -, /usr/sbin/init.lxc)
	@$(call install_copy, lxc6-pv, 0, 0, 0755, /usr/lib/lxc/rootfs)
	@$(call install_copy, lxc6-pv, 0, 0, 0755, /usr/var/lib/lxc)
	@$(call install_tree, lxc6-pv, 0, 0, -, /usr/libexec/lxc)

ifdef PTXCONF_LXC6_PV_TOOLS
	@$(foreach app, $(LXC6_PV_TOOLS_LIST), \
		$(call install_copy, lxc6-pv, 0, 0, 0755, -, \
			/usr/bin/lxc-$(app))$(ptx/nl))
endif

	@$(call install_finish, lxc6-pv)

	@$(call touch)

# vim: syntax=make
