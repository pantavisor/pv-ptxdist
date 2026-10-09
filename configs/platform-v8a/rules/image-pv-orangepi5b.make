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
# Separate from IMAGE_PV_ORANGEPI5B_DIR, which image/genimage uses and wipes.
IMAGE_PV_ORANGEPI5B_WORKDIR	:= $(BUILDDIR)/image-pv-orangepi5b-work
IMAGE_PV_ORANGEPI5B_FILES	:= $(IMAGE_PV_ORANGEPI5B_WORKDIR)/root.tgz

# The board's own BSP: only its device tree, not those of the other v8a
# boards.
IMAGE_PV_ORANGEPI5B_BSP		:= $(IMAGEDIR)/pantavisor-bsp-orangepi5b.pvrexport.tgz
IMAGE_PV_ORANGEPI5B_DTBS	:= rockchip/rk3588s-orangepi-5b.dtb

IMAGE_PV_ORANGEPI5B_ENV := \
	BOOT_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_BOOT_SIZE)) \
	STORAGE_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_PV_ORANGEPI5B_BSP): \
		$(IMAGE_PV_BSP_DEPS) \
		$(addprefix $(IMAGEDIR)/, $(notdir $(IMAGE_PV_ORANGEPI5B_DTBS)))
	@$(call targetinfo)
	@$(call pv/mkbsp, $@, $(IMAGE_PV_ORANGEPI5B_WORKDIR)/bsp, \
		$(IMAGE_PV_ORANGEPI5B_DTBS),)
	@$(call finish)

# boot/ for the vfat partition (boot.scr, oemEnv.txt), storage/ for the
# storage partition.
$(IMAGE_PV_ORANGEPI5B_FILES): \
		$(IMAGE_PV_STORAGE_DEPS) \
		$(IMAGE_PV_ORANGEPI5B_BSP) \
		$(IMAGE_PV_BOOT_TGZ)
	@$(call targetinfo)
	@$(call pv/mkstorage, $(IMAGE_PV_ORANGEPI5B_WORKDIR)/storage.tgz, \
		$(IMAGE_PV_ORANGEPI5B_WORKDIR)/storage, $(IMAGE_PV_ORANGEPI5B_BSP))
	@rm -rf $(IMAGE_PV_ORANGEPI5B_WORKDIR)/root
	@mkdir -p $(IMAGE_PV_ORANGEPI5B_WORKDIR)/root/storage
	@tar -C $(IMAGE_PV_ORANGEPI5B_WORKDIR)/root -xzf $(IMAGE_PV_BOOT_TGZ)
	@tar -C $(IMAGE_PV_ORANGEPI5B_WORKDIR)/root/storage \
		-xzf $(IMAGE_PV_ORANGEPI5B_WORKDIR)/storage.tgz
	@tar -C $(IMAGE_PV_ORANGEPI5B_WORKDIR)/root --owner=0 --group=0 --numeric-owner \
		-czf $@ .
	@$(call finish)

$(IMAGE_PV_ORANGEPI5B_IMAGE): $(STATEDIR)/u-boot-orangepi5b.targetinstall
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_ORANGEPI5B)
	@$(call finish)

# vim: syntax=make
