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
IMAGE_PACKAGES-$(PTXCONF_IMAGE_PV_STORAGE) += image-pv-storage

#
# Paths and names
#
IMAGE_PV_STORAGE	:= image-pv-storage
IMAGE_PV_STORAGE_DIR	:= $(BUILDDIR)/$(IMAGE_PV_STORAGE)
IMAGE_PV_STORAGE_IMAGE	:= $(IMAGEDIR)/pv-storage.ext4
# Separate from IMAGE_PV_STORAGE_DIR, which image/genimage uses and wipes.
IMAGE_PV_STORAGE_WORKDIR := $(BUILDDIR)/image-pv-storage-root
IMAGE_PV_STORAGE_FILES	:= $(IMAGE_PV_STORAGE_WORKDIR)/storage.tgz
IMAGE_PV_STORAGE_CONFIG	:= pv-storage.config

IMAGE_PV_STORAGE_ENV := \
	SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

# PTXdist makes IMAGE_PV_STORAGE_FILES a prerequisite of the image itself.
$(IMAGE_PV_STORAGE_FILES): $(IMAGE_PV_STORAGE_DEPS) $(IMAGE_PV_BSP_IMAGE)
	@$(call targetinfo)
	@$(call pv/mkstorage, $@, $(IMAGE_PV_STORAGE_WORKDIR)/work, $(IMAGE_PV_BSP_IMAGE))
	@$(call finish)

$(IMAGE_PV_STORAGE_IMAGE):
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_STORAGE)
	@$(call finish)

# vim: syntax=make
