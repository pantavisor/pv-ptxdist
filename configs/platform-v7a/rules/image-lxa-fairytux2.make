# -*-makefile-*-
#
# Copyright (C) 2020 by Ahmad Fatoum <a.fatoum@pengutronix.de>
# Copyright (C) 2024 by Leonard Göhrs <l.goehrs@pengutronix.de>
# Copyright (C) 2026 Roland Hieber, Pengutronix <rhi@pengutronix.de>
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
IMAGE_PACKAGES-$(PTXCONF_IMAGE_LXA_FAIRYTUX2) += image-lxa-fairytux2

# Note: though the -gen2 DTB is packaged into the FIP image, it is not really
# used because barebox-stm32mp153c-lxa-fairytux2.img also contains both DTBs and
# chooses the correct one in lowlevel code based on version strapping pins on
# the board.
IMAGE_LXA_FAIRYTUX2_ENV := \
	STM32MP_BOARD=stm32mp153c-lxa-fairytux2 \
	BAREBOX_DTB=stm32mp153c-lxa-fairytux2-gen2 \
	BAREBOX_IMAGE=barebox-stm32mp153c-lxa-fairytux2.img \
	SCMI=

#
# Paths and names
#
IMAGE_LXA_FAIRYTUX2		:= image-lxa-fairytux2
IMAGE_LXA_FAIRYTUX2_DIR		:= $(BUILDDIR)/$(IMAGE_LXA_FAIRYTUX2)
IMAGE_LXA_FAIRYTUX2_IMAGE	:= $(IMAGEDIR)/lxa-fairytux2.hdimg
IMAGE_LXA_FAIRYTUX2_FILES	:= $(IMAGEDIR)/root.tgz
IMAGE_LXA_FAIRYTUX2_CONFIG	:= stm32mp.config

# ----------------------------------------------------------------------------
# Image
# ----------------------------------------------------------------------------

$(IMAGE_LXA_FAIRYTUX2_IMAGE):
	@$(call targetinfo)
	@$(call image/genimage, IMAGE_LXA_FAIRYTUX2)
	@$(call finish)

# vim: syntax=make
