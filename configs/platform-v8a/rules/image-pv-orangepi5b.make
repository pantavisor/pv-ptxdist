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
IMAGE_PACKAGES-$(PTXCONF_IMAGE_PV_ORANGEPI5B) += image-pv-orangepi5b

#
# Paths and names
#
IMAGE_PV_ORANGEPI5B		:= image-pv-orangepi5b
IMAGE_PV_ORANGEPI5B_DIR		:= $(BUILDDIR)/$(IMAGE_PV_ORANGEPI5B)
IMAGE_PV_ORANGEPI5B_IMAGE	:= $(IMAGEDIR)/pv-orangepi5b.img
IMAGE_PV_ORANGEPI5B_CONFIG	:= pv-orangepi5b.config

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

# pv-boot.vfat comes from image-pv-hd.
$(IMAGE_PV_ORANGEPI5B_IMAGE): \
		$(IMAGE_PV_HD_IMAGE) \
		$(STATEDIR)/u-boot-orangepi5b.targetinstall
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_ORANGEPI5B)
	@$(call finish)

# vim: syntax=make
