# -*-makefile-*-
#
# Copyright (C) 2026 by Fabian Pfitzner <f.pfitzner@pengutronix.de>
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_FIRMWARE_NXP_WIFI) += firmware-nxp-wifi

#
# Paths and names
#
FIRMWARE_NXP_WIFI_VERSION	:= lf-6.6.52-2.2.2
FIRMWARE_NXP_WIFI_MD5		:= c45d14303b23a2ae2870170a6289d0bb
FIRMWARE_NXP_WIFI		:= firmware-nxp-wifi-$(FIRMWARE_NXP_WIFI_VERSION)
FIRMWARE_NXP_WIFI_SUFFIX	:= tar.gz
FIRMWARE_NXP_WIFI_URL		:= https://github.com/nxp-imx/imx-firmware/archive/refs/tags/$(FIRMWARE_NXP_WIFI_VERSION).$(FIRMWARE_NXP_WIFI_SUFFIX)
FIRMWARE_NXP_WIFI_SOURCE	:= $(SRCDIR)/$(FIRMWARE_NXP_WIFI).$(FIRMWARE_NXP_WIFI_SUFFIX)
FIRMWARE_NXP_WIFI_DIR		:= $(BUILDDIR)/$(FIRMWARE_NXP_WIFI)
FIRMWARE_NXP_WIFI_LICENSE	:= NXP-Software-License-Agreement
FIRMWARE_NXP_WIFI_LICENSE_FILES	:= \
	file://LICENSE.txt;md5=ca53281cc0caa7e320d4945a896fb837

FIRMWARE_NXP_WIFI_MAKE_ENV	:= \
	INSTALLDIR=$(FIRMWARE_NXP_WIFI_PKGDIR)/lib/firmware/nxp

FIRMWARE_NXP_WIFI_CONF_TOOL	:= NO

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

$(STATEDIR)/firmware-nxp-wifi.compile:
	@$(call targetinfo)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/firmware-nxp-wifi.targetinstall:
	@$(call targetinfo)

	@$(call install_init, firmware-nxp-wifi)
	@$(call install_fixup, firmware-nxp-wifi,PRIORITY,optional)
	@$(call install_fixup, firmware-nxp-wifi,SECTION,base)
	@$(call install_fixup, firmware-nxp-wifi,AUTHOR,"Fabian Pfitzner <f.pfitzner@pengutronix.de>")
	@$(call install_fixup, firmware-nxp-wifi,DESCRIPTION,missing)

	@$(call install_copy, firmware-nxp-wifi, 0, 0, 0755, \
		$(FIRMWARE_NXP_WIFI_PKGDIR)/lib/firmware/nxp/sd_w61x_v1.bin.se, \
		/lib/firmware/nxp/sd_w61x.bin)

	@$(call install_finish, firmware-imx)

	@$(call install_finish, firmware-nxp-wifi)

	@$(call touch)

# vim: syntax=make
