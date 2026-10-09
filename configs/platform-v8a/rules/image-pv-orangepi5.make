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
IMAGE_PACKAGES-$(PTXCONF_IMAGE_PV_ORANGEPI5) += image-pv-orangepi5

#
# Paths and names
#
IMAGE_PV_ORANGEPI5		:= image-pv-orangepi5
IMAGE_PV_ORANGEPI5_DIR		:= $(BUILDDIR)/$(IMAGE_PV_ORANGEPI5)
IMAGE_PV_ORANGEPI5_IMAGE	:= $(IMAGEDIR)/pv-orangepi5.img
IMAGE_PV_ORANGEPI5_CONFIG	:= pv-orangepi5.config
# Separate from IMAGE_PV_ORANGEPI5_DIR, which image/genimage uses and wipes.
IMAGE_PV_ORANGEPI5_WORKDIR	:= $(BUILDDIR)/image-pv-orangepi5-work
IMAGE_PV_ORANGEPI5_FILES	:= $(IMAGE_PV_ORANGEPI5_WORKDIR)/root.tgz

# The board's own BSP: only its device tree, not those of the other v8a
# boards.
IMAGE_PV_ORANGEPI5_BSP		:= $(IMAGEDIR)/pantavisor-bsp-orangepi5.pvrexport.tgz
IMAGE_PV_ORANGEPI5_DTBS	:= rockchip/rk3588s-orangepi-5.dtb

IMAGE_PV_ORANGEPI5_ENV := \
	BOOT_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_BOOT_SIZE)) \
	STORAGE_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_PV_ORANGEPI5_BSP): \
		$(IMAGE_PV_BSP_DEPS) \
		$(addprefix $(IMAGEDIR)/, $(notdir $(IMAGE_PV_ORANGEPI5_DTBS)))
	@$(call targetinfo)
	@$(call pv/mkbsp, $@, $(IMAGE_PV_ORANGEPI5_WORKDIR)/bsp, \
		$(IMAGE_PV_ORANGEPI5_DTBS),)
	@$(call finish)

# boot/ for the vfat partition (boot.scr, oemEnv.txt), storage/ for the
# storage partition.
$(IMAGE_PV_ORANGEPI5_FILES): \
		$(IMAGE_PV_STORAGE_DEPS) \
		$(IMAGE_PV_ORANGEPI5_BSP) \
		$(IMAGE_PV_BOOT_TGZ)
	@$(call targetinfo)
	@$(call pv/mkstorage, $(IMAGE_PV_ORANGEPI5_WORKDIR)/storage.tgz, \
		$(IMAGE_PV_ORANGEPI5_WORKDIR)/storage, $(IMAGE_PV_ORANGEPI5_BSP))
	@rm -rf $(IMAGE_PV_ORANGEPI5_WORKDIR)/root
	@mkdir -p $(IMAGE_PV_ORANGEPI5_WORKDIR)/root/storage
	@tar -C $(IMAGE_PV_ORANGEPI5_WORKDIR)/root -xzf $(IMAGE_PV_BOOT_TGZ)
	@tar -C $(IMAGE_PV_ORANGEPI5_WORKDIR)/root/storage \
		-xzf $(IMAGE_PV_ORANGEPI5_WORKDIR)/storage.tgz
	@tar -C $(IMAGE_PV_ORANGEPI5_WORKDIR)/root --owner=0 --group=0 --numeric-owner \
		-czf $@ .
	@$(call finish)

$(IMAGE_PV_ORANGEPI5_IMAGE): $(STATEDIR)/u-boot-orangepi5.targetinstall
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_ORANGEPI5)
	@$(call finish)

# vim: syntax=make
