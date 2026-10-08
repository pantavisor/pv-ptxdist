# -*-makefile-*-
#
# Copyright (C) 2026 by Fernando Luiz Cola <fernando.luiz@pantacor.com>
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

# Kernel modules and firmware are shipped in the Pantavisor BSP as squashfs
# images (image-pv-bsp), so keep those packages out of the root filesystem
# images that become the initramfs. rules/post is read after the upstream
# image rules, so this assignment wins.
ifdef PTXCONF_IMAGE_PV_BSP
IMAGE_ROOT_TGZ_PKGS = $(filter-out kernel $(IMAGE_PV_BSP_FW_PKGS),$(PTX_PACKAGES_INSTALL))
endif

# vim: syntax=make
