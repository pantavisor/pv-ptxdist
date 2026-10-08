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

IMAGE_PV_RPI4_ENV := \
	BOOT_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_HD_BOOT_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_PV_RPI4_FILES): \
		$(IMAGE_PV_HD_FILES) \
		$(STATEDIR)/u-boot-rpi4.targetinstall \
		$(IMAGEDIR)/bcm2711-rpi-4-b.dtb \
		$(call ptx/in-platformconfigdir, rpi4/config.txt) \
		$(IMAGE_PV_RPI4_FIRMWARE)
	@$(call targetinfo)
	@rm -rf $(IMAGE_PV_RPI4_WORKDIR)
	@mkdir -p $(IMAGE_PV_RPI4_WORKDIR)/root
	@tar -C $(IMAGE_PV_RPI4_WORKDIR)/root -xzf $(IMAGE_PV_HD_FILES)
	@install -m 0644 \
		$(IMAGE_PV_RPI4_FIRMWARE) \
		$(IMAGEDIR)/u-boot-rpi4.bin \
		$(IMAGEDIR)/bcm2711-rpi-4-b.dtb \
		$(call ptx/in-platformconfigdir, rpi4/config.txt) \
		$(IMAGE_PV_RPI4_WORKDIR)/root/boot/
	@tar -C $(IMAGE_PV_RPI4_WORKDIR)/root --owner=0 --group=0 --numeric-owner \
		-czf $@ .
	@$(call finish)

$(IMAGE_PV_RPI4_IMAGE): $(IMAGE_PV_STORAGE_IMAGE)
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_RPI4)
	@$(call finish)

# vim: syntax=make
