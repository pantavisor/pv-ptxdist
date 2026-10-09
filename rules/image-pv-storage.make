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

IMAGE_PV_STORAGE_ENV := \
	SIZE=$(call remove_quotes, $(PTXCONF_IMAGE_PV_STORAGE_SIZE))

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

# pvr 054 segfaults during 'pvr init' when it inherits PTXdist's environment
# (the same binary works with 'env -i'), so the script gets only what it needs.
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
