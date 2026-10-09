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
IMAGE_PACKAGES-$(PTXCONF_IMAGE_PV_BSP) += image-pv-bsp

#
# Paths and names
#
IMAGE_PV_BSP		:= image-pv-bsp
IMAGE_PV_BSP_DIR	:= $(BUILDDIR)/$(IMAGE_PV_BSP)
IMAGE_PV_BSP_IMAGE	:= $(IMAGEDIR)/pantavisor-bsp.pvrexport.tgz

# A platform may carry its own skel in configs/platform-*/pantavisor/skel.
IMAGE_PV_BSP_SKEL	:= $(firstword $(wildcard \
	$(PTXDIST_PLATFORMCONFIGDIR)/pantavisor/skel \
	$(PTXDIST_WORKSPACE)/configs/pantavisor/skel))

IMAGE_PV_BSP_FDT	:= $(call remove_quotes, $(PTXCONF_IMAGE_PV_BSP_FDT))
# The kernel rule installs device trees into the images directory without
# their vendor directory.
IMAGE_PV_BSP_DTBS	:= $(call remove_quotes, $(PTXCONF_IMAGE_PV_BSP_DTBS))
IMAGE_PV_BSP_DTB_FILES	:= $(addprefix $(IMAGEDIR)/, $(notdir $(IMAGE_PV_BSP_DTBS)))

IMAGE_PV_BSP_FW_PKGS	:= $(call remove_quotes, $(PTXCONF_IMAGE_PV_BSP_FIRMWARE_PKGS))
# Recursive: the firmware rules are read after this file.
IMAGE_PV_BSP_FW_DIRS	= $(foreach pkg, $(IMAGE_PV_BSP_FW_PKGS), \
	$($(PTX_MAP_TO_PACKAGE_$(pkg))_PKGDIR)/usr/lib/firmware \
	$($(PTX_MAP_TO_PACKAGE_$(pkg))_PKGDIR)/lib/firmware)

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

# pvr 054 segfaults during 'pvr init' when it inherits PTXdist's environment
# (the same binary works with 'env -i'), so the script gets only what it needs.
#
# PTXdist only orders the selected host packages before the final image
# targets, not before helper targets like this one, so it lists them itself.
IMAGE_PV_BSP_DEPS := \
	$(STATEDIR)/host-pvr.install.post \
	$(STATEDIR)/host-pv-developer-ca.install.post \
	$(STATEDIR)/host-squashfs-tools.install.post \
	$(IMAGE_ROOT_CPIO_IMAGE) \
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

$(IMAGE_PV_BSP_IMAGE): $(IMAGE_PV_BSP_DEPS) $(IMAGE_PV_BSP_DTB_FILES)
	@$(call targetinfo)
	@$(call pv/mkbsp, $@, $(IMAGE_PV_BSP_DIR), $(IMAGE_PV_BSP_DTBS), $(IMAGE_PV_BSP_FW_DIRS))
	@$(call finish)

# vim: syntax=make
