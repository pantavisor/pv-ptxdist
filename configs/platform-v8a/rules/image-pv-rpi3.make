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
IMAGE_PACKAGES-$(PTXCONF_IMAGE_PV_RPI3) += image-pv-rpi3

#
# Paths and names
#
IMAGE_PV_RPI3		:= image-pv-rpi3
IMAGE_PV_RPI3_DIR	:= $(BUILDDIR)/$(IMAGE_PV_RPI3)
IMAGE_PV_RPI3_IMAGE	:= $(IMAGEDIR)/pv-rpi3.img
# Separate from IMAGE_PV_RPI3_DIR, which image/genimage uses and wipes.
IMAGE_PV_RPI3_WORKDIR	:= $(BUILDDIR)/image-pv-rpi3-boot
IMAGE_PV_RPI3_FILES	:= $(IMAGE_PV_RPI3_WORKDIR)/boot.tgz
IMAGE_PV_RPI3_CONFIG	:= pv-rpi3.config

# DistroKit's copy of the Raspberry Pi firmware; the Pi 3 uses the older
# generation (bootcode.bin, start.elf), not the Pi 4 files.
IMAGE_PV_RPI3_FIRMWARE_DIR	:= $(call ptx/in-path, PTXDIST_PATH, rpi-firmware)
IMAGE_PV_RPI3_FIRMWARE		:= \
	$(IMAGE_PV_RPI3_FIRMWARE_DIR)/bootcode.bin \
	$(IMAGE_PV_RPI3_FIRMWARE_DIR)/start.elf \
	$(IMAGE_PV_RPI3_FIRMWARE_DIR)/fixup.dat \
	$(IMAGE_PV_RPI3_FIRMWARE_DIR)/LICENCE.broadcom

# The board's own BSP: only its device tree, not those of the other v8a
# boards.
IMAGE_PV_RPI3_BSP	:= $(IMAGEDIR)/pantavisor-bsp-rpi3.pvrexport.tgz
IMAGE_PV_RPI3_DTBS	:= broadcom/bcm2837-rpi-3-b-plus.dtb

IMAGE_PV_RPI3_ENV := \
	BOOT_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_BOOT_SIZE)) \
	STORAGE_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_PV_RPI3_BSP): \
		$(IMAGE_PV_BSP_DEPS) \
		$(addprefix $(IMAGEDIR)/, $(notdir $(IMAGE_PV_RPI3_DTBS)))
	@$(call targetinfo)
	@$(call pv/mkbsp, $@, $(IMAGE_PV_RPI3_WORKDIR)/bsp, $(IMAGE_PV_RPI3_DTBS),)
	@$(call finish)

# boot/ for the vfat partition (firmware, config.txt, devicetree, U-Boot,
# boot.scr, oemEnv.txt), storage/ for the storage partition.
$(IMAGE_PV_RPI3_FILES): \
		$(IMAGE_PV_STORAGE_DEPS) \
		$(IMAGE_PV_RPI3_BSP) \
		$(IMAGE_PV_BOOT_TGZ) \
		$(STATEDIR)/u-boot-rpi3.targetinstall \
		$(IMAGEDIR)/bcm2837-rpi-3-b-plus.dtb \
		$(call ptx/in-platformconfigdir, rpi3/config.txt) \
		$(IMAGE_PV_RPI3_FIRMWARE)
	@$(call targetinfo)
	@$(call pv/mkstorage, $(IMAGE_PV_RPI3_WORKDIR)/storage.tgz, \
		$(IMAGE_PV_RPI3_WORKDIR)/storage, $(IMAGE_PV_RPI3_BSP))
	@rm -rf $(IMAGE_PV_RPI3_WORKDIR)/root
	@mkdir -p $(IMAGE_PV_RPI3_WORKDIR)/root/storage
	@tar -C $(IMAGE_PV_RPI3_WORKDIR)/root -xzf $(IMAGE_PV_BOOT_TGZ)
	@install -m 0644 \
		$(IMAGE_PV_RPI3_FIRMWARE) \
		$(IMAGEDIR)/u-boot-rpi3.bin \
		$(IMAGEDIR)/bcm2837-rpi-3-b-plus.dtb \
		$(call ptx/in-platformconfigdir, rpi3/config.txt) \
		$(IMAGE_PV_RPI3_WORKDIR)/root/boot/
	@tar -C $(IMAGE_PV_RPI3_WORKDIR)/root/storage \
		-xzf $(IMAGE_PV_RPI3_WORKDIR)/storage.tgz
	@tar -C $(IMAGE_PV_RPI3_WORKDIR)/root --owner=0 --group=0 --numeric-owner \
		-czf $@ .
	@$(call finish)

$(IMAGE_PV_RPI3_IMAGE):
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_RPI3)
	@$(call finish)

# vim: syntax=make
