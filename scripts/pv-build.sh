#!/bin/bash
#
# Build the Pantavisor image of one device.
#
# usage: scripts/pv-build.sh [--no-docker] <device> [ptxdist options...]
#        scripts/pv-build.sh --list
#
#   scripts/pv-build.sh orangepi5b
#   scripts/pv-build.sh rpi4 -q
#   scripts/pv-build.sh --no-docker qemu-x86_64
#
# Selects the device's platform and toolchain in the workspace and its board
# in the platform's Pantavisor boards choice, then builds that device's image
# with 'ptxdist image', which builds everything the image needs (BSP,
# storage, bootloader). Runs in the build container through
# scripts/pv-docker.sh unless --no-docker is given.
#
# Selecting another board changes configs/platform-<name>/platformconfig and
# its .diff: commit it to make that board the platform's default, or revert.
#
# A workspace holds one selected platform at a time, but each platform keeps
# its own build tree (platform-<name>/), so switching devices only rebuilds
# what changed.

set -e

bsp="$(cd "$(dirname "$0")/.." && pwd)"

# device       platform  board option (Pantavisor boards)  image                 shipped next to it
devices="
orangepi5      v8a       IMAGE_PV_ORANGEPI5   pv-orangepi5.img      pantavisor-bsp-orangepi5.pvrexport.tgz
orangepi5b     v8a       IMAGE_PV_ORANGEPI5B  pv-orangepi5b.img     pantavisor-bsp-orangepi5b.pvrexport.tgz
rpi3           v8a       IMAGE_PV_RPI3        pv-rpi3.img           pantavisor-bsp-rpi3.pvrexport.tgz
rpi4           v8a       IMAGE_PV_RPI4        pv-rpi4.img           pantavisor-bsp-rpi4.pvrexport.tgz
qemu-arm64     v8a       IMAGE_PV_HD          pv-hd.img             u-boot.bin pantavisor-bsp.pvrexport.tgz
qemu-x86_64    x86_64    IMAGE_PV_HD          pv-hd.img             u-boot.rom pantavisor-bsp.pvrexport.tgz
"

usage() {
	echo "usage: $0 [--no-docker] <device> [ptxdist options...]" >&2
	echo "devices:" >&2
	echo "${devices}" | awk 'NF { printf "  %-14s (%s) %s\n", $1, $2, $4 }' >&2
	exit 1
}

docker=1
case "$1" in
--list)
	echo "${devices}" | awk 'NF { print $1 }'
	exit 0
	;;
--no-docker)
	docker=
	shift
	;;
esac

device="$1"
[ -n "${device}" ] || usage
shift

entry="$(echo "${devices}" | awk -v d="${device}" '$1 == d')"
[ -n "${entry}" ] || { echo "unknown device '${device}'" >&2; usage; }
set -- ${entry#* } "$@"
platform="$1"
option="$2"
image="$3"
shift 3
extras=()
while [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; do
	extras+=("$1")
	shift
done

# Select the board in the choice through the platform's .diff, which
# 'ptxdist oldconfig platform' turns into the full platformconfig.
config="${bsp}/configs/platform-${platform}/platformconfig"
select_board=
if ! grep -qx "PTXCONF_${option}=y" "${config}"; then
	for o in $(echo "${devices}" | awk -v p="${platform}" '$2 == p { print $3 }' | sort -u); do
		sed -i -e "/^PTXCONF_${o}=y\$/d" -e "/^# PTXCONF_${o} is not set\$/d" "${config}.diff"
	done
	echo "PTXCONF_${option}=y" >> "${config}.diff"
	select_board='yes "" | ptxdist oldconfig platform >/dev/null &&'
	echo "selecting board ${device} in configs/platform-${platform}/platformconfig"
fi

# 'ptxdist toolchain' without a path picks the toolchain the platformconfig
# names, from /opt.
cmd="
ptxdist select configs/ptxconfig >/dev/null &&
ptxdist platform configs/platform-${platform}/platformconfig >/dev/null &&
ptxdist toolchain >/dev/null &&
${select_board}
ptxdist -j\$(nproc) $* image ${image}
"

if [ -n "${docker}" ]; then
	"${bsp}/scripts/pv-docker.sh" sh -c "cd '${bsp}' && ${cmd}"
else
	(cd "${bsp}" && sh -c "${cmd}")
fi

echo
echo "${device}:"
for f in "${image}" "${extras[@]}"; do
	echo "  platform-${platform}/images/${f}"
done
