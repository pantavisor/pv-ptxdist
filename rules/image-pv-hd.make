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

# The boot partition contents every board image starts from: boot.scr and
# oemEnv.txt under boot/. Its work directory is separate from
# IMAGE_PV_HD_DIR, which image/genimage uses and wipes.
IMAGE_PV_BOOT_WORKDIR	:= $(BUILDDIR)/image-pv-boot
IMAGE_PV_BOOT_TGZ	:= $(IMAGE_PV_BOOT_WORKDIR)/boot.tgz
IMAGE_PV_HD_FILES	:= $(IMAGE_PV_BOOT_TGZ)

IMAGE_PV_BOOT_SRCDIR	:= $(firstword $(wildcard \
	$(PTXDIST_PLATFORMCONFIGDIR)/pantavisor/boot \
	$(PTXDIST_WORKSPACE)/configs/pantavisor/boot))

IMAGE_PV_BOOT_EXTRA_FILES	:= $(addprefix $(IMAGEDIR)/, \
	$(call remove_quotes, $(PTXCONF_IMAGE_PV_BOOT_EXTRA_FILES)))

IMAGE_PV_HD_ENV := \
	BOOT_SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_BOOT_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_PV_BOOT_TGZ): \
		$(STATEDIR)/host-u-boot-tools.install.post \
		$(IMAGE_PV_BOOT_SRCDIR)/boot.cmd.pvgeneric \
		$(IMAGE_PV_BOOT_SRCDIR)/oemEnv.txt \
		$(IMAGE_PV_BOOT_EXTRA_FILES)
	@$(call targetinfo)
	@rm -rf $(IMAGE_PV_BOOT_WORKDIR)
	@mkdir -p $(IMAGE_PV_BOOT_WORKDIR)/root/boot
	@$(PTXDIST_SYSROOT_HOST)/usr/bin/mkimage -A $(GENERIC_KERNEL_ARCH) \
		-T script -C none -n "Pantavisor boot script" \
		-d $(IMAGE_PV_BOOT_SRCDIR)/boot.cmd.pvgeneric \
		$(IMAGE_PV_BOOT_WORKDIR)/root/boot/boot.scr
	@sed -e 's|@@PV_BOOT_OEMARGS@@|$(call remove_quotes, $(PTXCONF_IMAGE_PV_BOOT_OEMARGS))|' \
		$(IMAGE_PV_BOOT_SRCDIR)/oemEnv.txt \
		> $(IMAGE_PV_BOOT_WORKDIR)/root/boot/oemEnv.txt
	@$(foreach f, $(IMAGE_PV_BOOT_EXTRA_FILES), \
		cp $(f) $(IMAGE_PV_BOOT_WORKDIR)/root/boot/;)
	@tar -C $(IMAGE_PV_BOOT_WORKDIR)/root --owner=0 --group=0 --numeric-owner \
		-czf $@ .
	@$(call finish)

$(IMAGE_PV_HD_IMAGE): $(IMAGE_PV_STORAGE_IMAGE)
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_HD)
	@$(call finish)

# vim: syntax=make
