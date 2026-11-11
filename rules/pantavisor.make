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
PACKAGES-$(PTXCONF_PANTAVISOR) += pantavisor

#
# Paths and names
#
PANTAVISOR_VERSION	:= 031-rc8
PANTAVISOR_SHA256	:= 7cc499dbba8d2e76ac9067a813731afe2f4cd7eb924d24a6cfeee202ef3cf292
PANTAVISOR		:= pantavisor-$(PANTAVISOR_VERSION)
PANTAVISOR_SUFFIX	:= tar.gz
PANTAVISOR_URL		:= https://github.com/pantavisor/pantavisor.git;tag=$(PANTAVISOR_VERSION)
PANTAVISOR_SOURCE	:= $(SRCDIR)/$(PANTAVISOR).$(PANTAVISOR_SUFFIX)
PANTAVISOR_DIR		:= $(BUILDDIR)/$(PANTAVISOR)
PANTAVISOR_LICENSE	:= MIT
PANTAVISOR_LICENSE_FILES := \
	file://LICENSE;md5=9537d669f1ccfd74f3940b3bc1d3297d

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

PANTAVISOR_CONF_TOOL	:= cmake
PANTAVISOR_CONF_OPT	:= \
	$(CROSS_CMAKE_USR) \
	-DPANTAVISOR_RUNTIME=ON \
	-DPANTAVISOR_APPENGINE=OFF \
	-DPANTAVISOR_PVTEST=OFF \
	-DPANTAVISOR_PVTX_STATIC=OFF \
	-DPANTAVISOR_CLANG_FORMAT_CHECK=OFF \
	-DPANTAVISOR_DCP_BLOB_CREATE=OFF \
	-DPANTAVISOR_DEBUG=$(call ptx/onoff, PTXCONF_PANTAVISOR_DEBUG) \
	-DPANTAVISOR_DEBUG_HOOKS=$(call ptx/onoff, PTXCONF_PANTAVISOR_DEBUG_HOOKS) \
	-DPANTAVISOR_DM_CRYPT=$(call ptx/onoff, PTXCONF_PANTAVISOR_DM_CRYPT) \
	-DPANTAVISOR_DM_VERITY=$(call ptx/onoff, PTXCONF_PANTAVISOR_DM_VERITY) \
	-DPANTAVISOR_E2FSGROW_ENABLE=$(call ptx/onoff, PTXCONF_PANTAVISOR_E2FSGROW) \
	-DPANTAVISOR_PVCONTROL=$(call ptx/onoff, PTXCONF_PANTAVISOR_PVCONTROL) \
	-DPANTAVISOR_PVTX=$(call ptx/onoff, PTXCONF_PANTAVISOR_PVTX) \
	-DPANTAVISOR_XCONNECT=$(call ptx/onoff, PTXCONF_PANTAVISOR_XCONNECT) \
	-DPANTAVISOR_DISTRO_NAME=ptxdist \
	-DPANTAVISOR_DISTRO_VERSION=$(PTXDIST_VERSION_FULL)

# Consumed by gen_version.sh (see patches/pantavisor-031-rc8).
PANTAVISOR_MAKE_ENV	:= \
	PV_GIT_DESCRIBE=$(PANTAVISOR_VERSION)

# GCC 15 defaults to C23, where old-style 'void f();' prototypes mean "no
# arguments" (e.g. pv_storage_set_active() in 030); pvtx already pins C17.
# The rest are the relaxations meta-pantavisor needs (OECMAKE_C_FLAGS), as the
# project builds with -Werror.
PANTAVISOR_CFLAGS	:= \
	-std=gnu17 \
	-Wno-unused-result \
	-Wno-error=implicit-function-declaration

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

# Since 031, the shipped config turns the secure boot handlers on, and with
# them dm-verity checks of dm: volumes. Follow PANTAVISOR_DM_VERITY instead,
# like meta-pantavisor does.
$(STATEDIR)/pantavisor.install:
	@$(call targetinfo)
	@$(call world/install, PANTAVISOR)
	@sed -i 's/^PV_SECUREBOOT_HANDLERS=.*/PV_SECUREBOOT_HANDLERS=$(call ptx/ifdef, PTXCONF_PANTAVISOR_DM_VERITY,1,0)/' \
		$(PANTAVISOR_PKGDIR)/etc/pantavisor.config
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/pantavisor.targetinstall:
	@$(call targetinfo)

	@$(call install_init, pantavisor)
	@$(call install_fixup, pantavisor,PRIORITY,optional)
	@$(call install_fixup, pantavisor,SECTION,base)
	@$(call install_fixup, pantavisor,AUTHOR,"Fernando Luiz Cola <fernando.luiz@pantacor.com>")
	@$(call install_fixup, pantavisor,DESCRIPTION,"Pantavisor container init and update agent")

	@$(call install_copy, pantavisor, 0, 0, 0755, -, /usr/bin/pantavisor)
	@$(call install_link, pantavisor, usr/bin/pantavisor, /init)

	@$(call install_copy, pantavisor, 0, 0, 0644, -, /usr/lib/pantavisor/pv_lxc.so)
	@$(call install_tree, pantavisor, 0, 0, -, /usr/lib/pantavisor/pv)

	@$(call install_copy, pantavisor, 0, 0, 0755, -, /usr/bin/pventer)
	@$(call install_copy, pantavisor, 0, 0, 0755, -, /usr/bin/fallbear-cmd)
ifdef PTXCONF_PANTAVISOR_PVCONTROL
	@$(call install_copy, pantavisor, 0, 0, 0755, -, /usr/bin/pvcontrol)
	@$(call install_copy, pantavisor, 0, 0, 0755, -, /usr/bin/pvcurl)
endif
ifdef PTXCONF_PANTAVISOR_PVTX
	@$(call install_copy, pantavisor, 0, 0, 0755, -, /usr/bin/pvtx)
	@$(call install_lib, pantavisor, 0, 0, 0644, libpvtx)
endif
ifdef PTXCONF_PANTAVISOR_XCONNECT
	@$(call install_copy, pantavisor, 0, 0, 0755, -, /usr/bin/pv-xconnect)
endif

	@$(call install_tree, pantavisor, 0, 0, -, /etc/pantavisor)
	@$(call install_alternative, pantavisor, 0, 0, 0644, /etc/pantavisor.config)

	@$(call install_finish, pantavisor)

	@$(call touch)

# vim: syntax=make
