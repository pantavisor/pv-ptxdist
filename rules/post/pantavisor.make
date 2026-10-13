# -*-makefile-*-
#
# Copyright (C) 2026 by Fernando Luiz Cola <fernando.luiz@pantacor.com>
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

# The kernel, its modules and firmware are shipped in the Pantavisor BSP
# (modules and firmware as squashfs images), so keep those packages out of
# the root filesystem images that become the initramfs. rules/post is read
# after the upstream image rules, so this assignment wins.
#
# IMAGE_PV_BOOT, not IMAGE_PV_BSP: every board selects it, while
# IMAGE_PV_BSP is only the QEMU board's generic BSP. Board firmware is not
# split out yet, so IMAGE_PV_BSP_FW_PKGS is empty for them.
ifdef PTXCONF_IMAGE_PV_BOOT
IMAGE_ROOT_TGZ_PKGS = $(filter-out kernel $(IMAGE_PV_BSP_FW_PKGS),$(PTX_PACKAGES_INSTALL))
endif

# vim: syntax=make
