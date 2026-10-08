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
PACKAGES-$(PTXCONF_PANTAVISOR_ROOTFS) += pantavisor-rootfs

PANTAVISOR_ROOTFS_VERSION	:= 1
PANTAVISOR_ROOTFS_LICENSE	:= ignore

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/pantavisor-rootfs.targetinstall:
	@$(call targetinfo)

	@$(call install_init, pantavisor-rootfs)
	@$(call install_fixup, pantavisor-rootfs,PRIORITY,optional)
	@$(call install_fixup, pantavisor-rootfs,SECTION,base)
	@$(call install_fixup, pantavisor-rootfs,AUTHOR,"Fernando Luiz Cola <fernando.luiz@pantacor.com>")
	@$(call install_fixup, pantavisor-rootfs,DESCRIPTION,"Pantavisor initramfs layout")

	@$(call install_copy, pantavisor-rootfs, 0, 0, 0755, /storage)
	@$(call install_copy, pantavisor-rootfs, 0, 0, 0755, /volumes)
	@$(call install_copy, pantavisor-rootfs, 0, 0, 0755, /exports)
	@$(call install_copy, pantavisor-rootfs, 0, 0, 0755, /writable)
	@$(call install_link, pantavisor-rootfs, run/pantavisor/pv, /pv)
	@$(call install_link, pantavisor-rootfs, run/pantavisor/media, /media)
	@$(call install_link, pantavisor-rootfs, run/pantavisor/configs, /configs)

	@$(call install_finish, pantavisor-rootfs)

	@$(call touch)

# vim: syntax=make
