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
# Separate from IMAGE_PV_HD_DIR, which image/genimage uses and wipes.
IMAGE_PV_HD_WORKDIR	:= $(BUILDDIR)/image-pv-hd-boot
IMAGE_PV_HD_FILES	:= $(IMAGE_PV_HD_WORKDIR)/boot.tgz
IMAGE_PV_HD_CONFIG	:= pv-hd.config

IMAGE_PV_HD_BOOTDIR	:= $(firstword $(wildcard \
	$(PTXDIST_PLATFORMCONFIGDIR)/pantavisor/boot \
	$(PTXDIST_WORKSPACE)/configs/pantavisor/boot))

IMAGE_PV_HD_BOOT_FILES	:= $(addprefix $(IMAGEDIR)/, \
	$(call remove_quotes, $(PTXCONF_IMAGE_PV_HD_BOOT_FILES)))

IMAGE_PV_HD_ENV := \
	BOOT_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_HD_BOOT_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_PV_HD_FILES): \
		$(STATEDIR)/host-u-boot-tools.install.post \
		$(IMAGE_PV_HD_BOOTDIR)/boot.cmd.pvgeneric \
		$(IMAGE_PV_HD_BOOTDIR)/oemEnv.txt \
		$(IMAGE_PV_HD_BOOT_FILES)
	@$(call targetinfo)
	@rm -rf $(IMAGE_PV_HD_WORKDIR)
	@mkdir -p $(IMAGE_PV_HD_WORKDIR)/root/boot
	@$(PTXDIST_SYSROOT_HOST)/usr/bin/mkimage -A $(GENERIC_KERNEL_ARCH) \
		-T script -C none -n "Pantavisor boot script" \
		-d $(IMAGE_PV_HD_BOOTDIR)/boot.cmd.pvgeneric \
		$(IMAGE_PV_HD_WORKDIR)/root/boot/boot.scr
	@sed -e 's|@@PV_BOOT_OEMARGS@@|$(call remove_quotes, $(PTXCONF_IMAGE_PV_HD_OEMARGS))|' \
		$(IMAGE_PV_HD_BOOTDIR)/oemEnv.txt \
		> $(IMAGE_PV_HD_WORKDIR)/root/boot/oemEnv.txt
	@$(foreach f, $(IMAGE_PV_HD_BOOT_FILES), \
		cp $(f) $(IMAGE_PV_HD_WORKDIR)/root/boot/;)
	@tar -C $(IMAGE_PV_HD_WORKDIR)/root --owner=0 --group=0 --numeric-owner \
		-czf $@ .
	@$(call finish)

$(IMAGE_PV_HD_IMAGE): $(IMAGE_PV_STORAGE_IMAGE)
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_HD)
	@$(call finish)

# vim: syntax=make
