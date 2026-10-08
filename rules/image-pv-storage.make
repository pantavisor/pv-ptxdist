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

IMAGE_PV_STORAGE_PANTAHUB_CONFIG := $(firstword $(wildcard \
	$(PTXDIST_PLATFORMCONFIGDIR)/pantavisor/pantahub.config \
	$(PTXDIST_WORKSPACE)/configs/pantavisor/pantahub.config))

IMAGE_PV_STORAGE_USER_CONTAINERS := $(foreach c, \
	$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_CONTAINERS)), \
	$(if $(filter /%,$(c)),$(c),$(PTXDIST_WORKSPACE)/$(c)))

# Containers from host packages are ordered by their install stamps; their
# sysroot files have no make rule, so they must not be prerequisites.
IMAGE_PV_STORAGE_CONTAINERS := \
	$(call ptx/ifdef, PTXCONF_IMAGE_PV_STORAGE_ALPINE_CONNMAN, \
		$(PTXDIST_SYSROOT_HOST)/usr/share/pantavisor/containers/pv-alpine-connman.pvrexport.tgz) \
	$(IMAGE_PV_STORAGE_USER_CONTAINERS)

IMAGE_PV_STORAGE_ENV := \
	SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

# pvr 054 segfaults during 'pvr init' when it inherits PTXdist's environment
# (the same binary works with 'env -i'), so the script gets only what it needs.

# PTXdist makes IMAGE_PV_STORAGE_FILES a prerequisite of the image itself.
$(IMAGE_PV_STORAGE_FILES): \
		$(STATEDIR)/host-pvr.install.post \
		$(STATEDIR)/host-pv-developer-ca.install.post \
		$(IMAGE_PV_BSP_IMAGE) \
		$(call ptx/ifdef, PTXCONF_IMAGE_PV_STORAGE_ALPINE_CONNMAN, \
			$(STATEDIR)/host-pv-alpine-connman.install.post) \
		$(IMAGE_PV_STORAGE_USER_CONTAINERS)
	@$(call targetinfo)
	@env -i \
	PATH=$(PTXDIST_SYSROOT_HOST)/usr/bin:$(PTXDIST_SYSROOT_HOST)/usr/sbin:/usr/bin:/bin \
	SOURCE_DATE_EPOCH="$$SOURCE_DATE_EPOCH" \
	PV_WORKDIR=$(IMAGE_PV_STORAGE_WORKDIR)/work \
	PV_OUTPUT=$(IMAGE_PV_STORAGE_FILES) \
	PV_BSP=$(IMAGE_PV_BSP_IMAGE) \
	PV_CONTAINERS="$(IMAGE_PV_STORAGE_CONTAINERS)" \
	PV_CA_KEYS=$(PTXDIST_SYSROOT_HOST)/usr/share/pantavisor/pvs.defaultkeys.tar.gz \
	PV_PANTAHUB_CONFIG=$(IMAGE_PV_STORAGE_PANTAHUB_CONFIG) \
	PV_BOOTLOADER=$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_BOOTLOADER)) \
		$(PTXDIST_WORKSPACE)/scripts/pv-mkstorage.sh
	@$(call finish)

$(IMAGE_PV_STORAGE_IMAGE):
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_PV_STORAGE)
	@$(call finish)

# vim: syntax=make
