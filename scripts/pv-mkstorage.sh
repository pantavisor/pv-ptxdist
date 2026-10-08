#!/bin/bash
#
# Assemble the Pantavisor storage partition contents (factory revision 0).
#
# Port of meta-pantavisor's pantavisor-pvroot.bb and pvroot-image.bbclass.
# Called from rules/image-pv-storage.make; inputs come from the environment.
#
# Required:
#   PV_WORKDIR        scratch directory (wiped)
#   PV_OUTPUT         resulting tarball of the partition contents
#   PV_BSP            BSP pvrexport (always deployed last)
#   PV_CA_KEYS        pvs.defaultkeys.tar.gz from host-pv-developer-ca
#   PV_PANTAHUB_CONFIG  pantahub.config to install as config/pantahub.config
#   PV_BOOTLOADER     uboot | uboot-ab | grub | rpiab
# Optional:
#   PV_CONTAINERS     space separated container pvrexports deployed into rev 0
#   PVR_SIG_KEY / PVR_X5C_PATH  production signing key and certificate chain

set -e

: "${PV_WORKDIR:?}" "${PV_OUTPUT:?}" "${PV_BSP:?}" "${PV_CA_KEYS:?}"
: "${PV_PANTAHUB_CONFIG:?}" "${PV_BOOTLOADER:?}"

rm -rf "${PV_WORKDIR}"
mkdir -p "${PV_WORKDIR}"/{home/.pvr,tmp,exports} "$(dirname "${PV_OUTPUT}")"
root="${PV_WORKDIR}/root"
mkdir -p "${root}"/{boot,config,logs,objects,trails/0}

export HOME="${PV_WORKDIR}/home"
export TMPDIR="${PV_WORKDIR}/tmp"
export PVR_DISABLE_SELF_UPGRADE=true
tar -C "${HOME}/.pvr" --no-same-owner -xf "${PV_CA_KEYS}"

case "${PV_BOOTLOADER}" in
uboot|uboot-ab)
	# Byte-identical to meta-pantavisor's pantavisor-pvroot/uboot.txt.
	printf 'pv_rev=0\0\0' > "${root}/boot/uboot.txt"
	;;
grub|rpiab)
	;;
*)
	echo "unknown bootloader '${PV_BOOTLOADER}'" >&2
	exit 1
	;;
esac

install -m 0644 "${PV_PANTAHUB_CONFIG}" "${root}/config/pantahub.config"

cd "${root}/trails/0"
pvr init --objects=../../objects
pvr add
pvr commit
pvr checkout -c
pvr sig add --raw _pvskel \
	--include device-envelope.json \
	--include '#spec' \
	--exclude __pvrsigbug__
pvr add
pvr commit

n=0
for export in ${PV_CONTAINERS} "${PV_BSP}"; do
	dir="${PV_WORKDIR}/exports/${n}"
	mkdir -p "${dir}"
	tar -C "${dir}" --no-same-owner -xf "${export}"
	(cd "${PV_WORKDIR}/exports" && pvr deploy "${root}/trails/0" "${dir}")
	n=$((n + 1))
done

tar -C "${root}" --owner=0 --group=0 --numeric-owner -czf "${PV_OUTPUT}" .
