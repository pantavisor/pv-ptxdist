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
IMAGE_PACKAGES-$(PTXCONF_IMAGE_PV_RPI4) += image-pv-rpi4

#
# Paths and names
#
IMAGE_PV_RPI4		:= image-pv-rpi4
IMAGE_PV_RPI4_DIR	:= $(BUILDDIR)/$(IMAGE_PV_RPI4)
IMAGE_PV_RPI4_IMAGE	:= $(IMAGEDIR)/pv-rpi4.img
# Separate from IMAGE_PV_RPI4_DIR, which image/genimage uses and wipes.
IMAGE_PV_RPI4_WORKDIR	:= $(BUILDDIR)/image-pv-rpi4-boot
IMAGE_PV_RPI4_FILES	:= $(IMAGE_PV_RPI4_WORKDIR)/boot.tgz
IMAGE_PV_RPI4_CONFIG	:= pv-rpi4.config

# DistroKit's copy of the Raspberry Pi firmware; only the Pi 4 files.
IMAGE_PV_RPI4_FIRMWARE_DIR	:= $(call ptx/in-path, PTXDIST_PATH, rpi-firmware)
IMAGE_PV_RPI4_FIRMWARE		:= \
	$(wildcard $(IMAGE_PV_RPI4_FIRMWARE_DIR)/start4*.elf) \
	$(wildcard $(IMAGE_PV_RPI4_FIRMWARE_DIR)/fixup4*.dat) \
	$(IMAGE_PV_RPI4_FIRMWARE_DIR)/LICENCE.broadcom

# The board's own BSP: only its device tree, not those of the other v8a
# boards.
IMAGE_PV_RPI4_BSP	:= $(IMAGEDIR)/pantavisor-bsp-rpi4.pvrexport.tgz
IMAGE_PV_RPI4_DTBS	:= broadcom/bcm2711-rpi-4-b.dtb

IMAGE_PV_RPI4_ENV := \
	BOOT_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_BOOT_SIZE)) \
	STORAGE_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_PV_RPI4_BSP): \
		$(IMAGE_PV_BSP_DEPS) \
		$(addprefix $(IMAGEDIR)/, $(notdir $(IMAGE_PV_RPI4_DTBS)))
	@$(call targetinfo)
	@$(call pv/mkbsp, $@, $(IMAGE_PV_RPI4_WORKDIR)/bsp, $(IMAGE_PV_RPI4_DTBS),)
	@$(call finish)

# boot/ for the vfat partition (firmware, config.txt, devicetree, U-Boot,
# boot.scr, oemEnv.txt), storage/ for the storage partition.
$(IMAGE_PV_RPI4_FILES): \
		$(IMAGE_PV_STORAGE_DEPS) \
		$(IMAGE_PV_RPI4_BSP) \
		$(IMAGE_PV_BOOT_TGZ) \
		$(STATEDIR)/u-boot-rpi4.targetinstall \
		$(IMAGEDIR)/bcm2711-rpi-4-b.dtb \
		$(call ptx/in-platformconfigdir, rpi4/config.txt) \
		$(IMAGE_PV_RPI4_FIRMWARE)
	@$(call targetinfo)
	@$(call pv/mkstorage, $(IMAGE_PV_RPI4_WORKDIR)/storage.tgz, \
		$(IMAGE_PV_RPI4_WORKDIR)/storage, $(IMAGE_PV_RPI4_BSP))
	@rm -rf $(IMAGE_PV_RPI4_WORKDIR)/root
	@mkdir -p $(IMAGE_PV_RPI4_WORKDIR)/root/storage
	@tar -C $(IMAGE_PV_RPI4_WORKDIR)/root -xzf $(IMAGE_PV_BOOT_TGZ)
	@install -m 0644 \
		$(IMAGE_PV_RPI4_FIRMWARE) \
		$(IMAGEDIR)/u-boot-rpi4.bin \
		$(IMAGEDIR)/bcm2711-rpi-4-b.dtb \
		$(call ptx/in-platformconfigdir, rpi4/config.txt) \
		$(IMAGE_PV_RPI4_WORKDIR)/root/boot/
	@tar -C $(IMAGE_PV_RPI4_WORKDIR)/root/storage \
		-xzf $(IMAGE_PV_RPI4_WORKDIR)/storage.tgz
	@tar -C $(IMAGE_PV_RPI4_WORKDIR)/root --owner=0 --group=0 --numeric-owner \
		-czf $@ .
	@$(call finish)

$(IMAGE_PV_RPI4_IMAGE):
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_RPI4)
	@$(call finish)

# vim: syntax=make
