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
IMAGE_PACKAGES-$(PTXCONF_IMAGE_PV_BSP) += image-pv-bsp

#
# Paths and names
#
IMAGE_PV_BSP		:= image-pv-bsp
IMAGE_PV_BSP_DIR	:= $(BUILDDIR)/$(IMAGE_PV_BSP)
IMAGE_PV_BSP_IMAGE	:= $(IMAGEDIR)/pantavisor-bsp.pvrexport.tgz

# The kernel rule installs device trees into the images directory without
# their vendor directory.
IMAGE_PV_BSP_DTBS	:= $(call remove_quotes, $(PTXCONF_IMAGE_PV_BSP_DTBS))
IMAGE_PV_BSP_DTB_FILES	:= $(addprefix $(IMAGEDIR)/, $(notdir $(IMAGE_PV_BSP_DTBS)))

IMAGE_PV_BSP_FW_PKGS	:= $(call remove_quotes, $(PTXCONF_IMAGE_PV_BSP_FIRMWARE_PKGS))
# Recursive: the firmware rules are read after this file.
IMAGE_PV_BSP_FW_DIRS	= $(foreach pkg, $(IMAGE_PV_BSP_FW_PKGS), \
	$($(PTX_MAP_TO_PACKAGE_$(pkg))_PKGDIR)/usr/lib/firmware \
	$($(PTX_MAP_TO_PACKAGE_$(pkg))_PKGDIR)/lib/firmware)

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_PV_BSP_IMAGE): $(IMAGE_PV_BSP_DEPS) $(IMAGE_PV_BSP_DTB_FILES)
	@$(call targetinfo)
	@$(call pv/mkbsp, $@, $(IMAGE_PV_BSP_DIR), $(IMAGE_PV_BSP_DTBS), $(IMAGE_PV_BSP_FW_DIRS))
	@$(call finish)

# vim: syntax=make
