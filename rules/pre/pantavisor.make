# -*-makefile-*-
#
# Copyright (C) 2026 by Fernando Luiz Cola <fernando.luiz@pantacor.com>
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

# What the Pantavisor image rules share. PTXdist only reads the rule files of
# enabled packages, and the generic BSP and storage images are only enabled
# for the QEMU board, so this cannot live in their rule files.

# ----------------------------------------------------------------------------
# BSP
# ----------------------------------------------------------------------------

# A platform may carry its own skel in configs/platform-*/pantavisor/skel.
IMAGE_PV_BSP_SKEL	:= $(firstword $(wildcard \
	$(PTXDIST_PLATFORMCONFIGDIR)/pantavisor/skel \
	$(PTXDIST_WORKSPACE)/configs/pantavisor/skel))

IMAGE_PV_BSP_FDT	:= $(call remove_quotes, $(PTXCONF_IMAGE_PV_BSP_FDT))

# pvr 054 segfaults during 'pvr init' when it inherits PTXdist's environment
# (the same binary works with 'env -i'), so the scripts get only what they
# need.
#
# PTXdist only orders the selected host packages before the final image
# targets, not before helper targets, so these list them themselves.
# The initramfs is named here rather than through IMAGE_ROOT_CPIO_IMAGE: the
# image-root-cpio rules are read after the board rules, whose prerequisite
# lists expand on reading, so the variable would still be empty there.
IMAGE_PV_BSP_DEPS := \
	$(STATEDIR)/host-pvr.install.post \
	$(STATEDIR)/host-pv-developer-ca.install.post \
	$(STATEDIR)/host-squashfs-tools.install.post \
	$(IMAGEDIR)/root.cpio$(call remove_quotes, $(PTXCONF_IMAGE_ROOT_CPIO_COMPRESSION_SUFFIX)) \
	$(IMAGEDIR)/linuximage

# Board image rules build their own BSP with only their device tree:
#   $(1): output .pvrexport.tgz
#   $(2): work directory (wiped)
#   $(3): device trees, with vendor directory (rockchip/foo.dtb)
#   $(4): firmware directories
define pv/mkbsp
	env -i \
	PATH=$(PTXDIST_SYSROOT_HOST)/usr/bin:$(PTXDIST_SYSROOT_HOST)/usr/sbin:/usr/bin:/bin \
	SOURCE_DATE_EPOCH="$$SOURCE_DATE_EPOCH" \
	PV_WORKDIR=$(strip $(2)) \
	PV_OUTPUT=$(strip $(1)) \
	PV_SKEL=$(IMAGE_PV_BSP_SKEL) \
	PV_KERNEL=$(IMAGEDIR)/linuximage \
	PV_INITRD=$(IMAGE_ROOT_CPIO_IMAGE) \
	PV_CA_KEYS=$(PTXDIST_SYSROOT_HOST)/usr/share/pantavisor/pvs.defaultkeys.tar.gz \
	PV_MODULES="$(wildcard $(KERNEL_PKGDIR)/lib/modules/*)" \
	PV_FIRMWARE="$(strip $(4))" \
	PV_DTBS="$(foreach d, $(3),$(IMAGEDIR)/$(notdir $(d)):$(d))" \
	PV_FDT="$(if $(IMAGE_PV_BSP_FDT),$(IMAGEDIR)/$(IMAGE_PV_BSP_FDT))" \
	PV_SQUASHFS_OPTS="$(call remove_quotes, $(PTXCONF_IMAGE_PV_BSP_SQUASHFS_OPTS))" \
		$(PTXDIST_WORKSPACE)/scripts/pv-mkbsp.sh
endef

# ----------------------------------------------------------------------------
# Storage
# ----------------------------------------------------------------------------

IMAGE_PV_STORAGE_PANTAHUB_CONFIG := $(firstword $(wildcard \
	$(PTXDIST_PLATFORMCONFIGDIR)/pantavisor/pantahub.config \
	$(PTXDIST_WORKSPACE)/configs/pantavisor/pantahub.config))

IMAGE_PV_STORAGE_USER_CONTAINERS := $(foreach c, \
	$(call remove_quotes, $(PTXCONF_PV_CONTAINERS_EXTRA)), \
	$(if $(filter /%,$(c)),$(c),$(PTXDIST_WORKSPACE)/$(c)))

# Containers from host packages are ordered by their install stamps; their
# sysroot files have no make rule, so they must not be prerequisites.
IMAGE_PV_STORAGE_CONTAINERS := \
	$(call ptx/ifdef, PTXCONF_PV_CONTAINER_ALPINE_CONNMAN, \
		$(PTXDIST_SYSROOT_HOST)/usr/share/pantavisor/containers/pv-alpine-connman.pvrexport.tgz) \
	$(call ptx/ifdef, PTXCONF_PV_CONTAINER_PVR_SDK, \
		$(PTXDIST_SYSROOT_HOST)/usr/share/pantavisor/containers/pv-pvr-sdk.pvrexport.tgz) \
	$(IMAGE_PV_STORAGE_USER_CONTAINERS)

IMAGE_PV_STORAGE_DEPS := \
	$(STATEDIR)/host-pvr.install.post \
	$(STATEDIR)/host-pv-developer-ca.install.post \
	$(call ptx/ifdef, PTXCONF_PV_CONTAINER_ALPINE_CONNMAN, \
		$(STATEDIR)/host-pv-alpine-connman.install.post) \
	$(call ptx/ifdef, PTXCONF_PV_CONTAINER_PVR_SDK, \
		$(STATEDIR)/host-pv-pvr-sdk.install.post) \
	$(IMAGE_PV_STORAGE_USER_CONTAINERS)

# Board image rules build their own storage from their own BSP:
#   $(1): output tgz of the storage partition contents
#   $(2): work directory (wiped)
#   $(3): BSP .pvrexport.tgz
define pv/mkstorage
	env -i \
	PATH=$(PTXDIST_SYSROOT_HOST)/usr/bin:$(PTXDIST_SYSROOT_HOST)/usr/sbin:/usr/bin:/bin \
	SOURCE_DATE_EPOCH="$$SOURCE_DATE_EPOCH" \
	PV_WORKDIR=$(strip $(2)) \
	PV_OUTPUT=$(strip $(1)) \
	PV_BSP=$(strip $(3)) \
	PV_CONTAINERS="$(IMAGE_PV_STORAGE_CONTAINERS)" \
	PV_CA_KEYS=$(PTXDIST_SYSROOT_HOST)/usr/share/pantavisor/pvs.defaultkeys.tar.gz \
	PV_PANTAHUB_CONFIG=$(IMAGE_PV_STORAGE_PANTAHUB_CONFIG) \
	PV_BOOTLOADER=$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_BOOTLOADER)) \
		$(PTXDIST_WORKSPACE)/scripts/pv-mkstorage.sh
endef

# ----------------------------------------------------------------------------
# Boot partition
# ----------------------------------------------------------------------------

# The boot partition contents every board image starts from: boot.scr and
# oemEnv.txt under boot/.
IMAGE_PV_BOOT_WORKDIR	:= $(BUILDDIR)/image-pv-boot
IMAGE_PV_BOOT_TGZ	:= $(IMAGE_PV_BOOT_WORKDIR)/boot.tgz

IMAGE_PV_BOOT_SRCDIR	:= $(firstword $(wildcard \
	$(PTXDIST_PLATFORMCONFIGDIR)/pantavisor/boot \
	$(PTXDIST_WORKSPACE)/configs/pantavisor/boot))

IMAGE_PV_BOOT_EXTRA_FILES	:= $(addprefix $(IMAGEDIR)/, \
	$(call remove_quotes, $(PTXCONF_IMAGE_PV_BOOT_EXTRA_FILES)))

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

# vim: syntax=make
