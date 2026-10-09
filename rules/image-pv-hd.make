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
IMAGE_PACKAGES-$(PTXCONF_IMAGE_PV_HD) += image-pv-hd

#
# Paths and names
#
IMAGE_PV_HD		:= image-pv-hd
IMAGE_PV_HD_DIR		:= $(BUILDDIR)/$(IMAGE_PV_HD)
IMAGE_PV_HD_IMAGE	:= $(IMAGEDIR)/pv-hd.img
IMAGE_PV_HD_CONFIG	:= pv-hd.config

IMAGE_PV_HD_FILES	:= $(IMAGE_PV_BOOT_TGZ)

IMAGE_PV_HD_ENV := \
	BOOT_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_BOOT_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_PV_HD_IMAGE): $(IMAGE_PV_STORAGE_IMAGE)
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_HD)
	@$(call finish)

# vim: syntax=make
