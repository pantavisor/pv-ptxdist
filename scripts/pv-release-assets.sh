#!/bin/bash
#
# Turn the build workflow's artifacts into GitHub release assets and notes.
#
# usage: scripts/pv-release-assets.sh <tag> <artifacts dir> <output dir>
#
# <artifacts dir> holds one pv-ptxdist-<device>/ directory per device, as
# 'gh run download' or actions/download-artifact leave them. <output dir>
# gets the assets (images xz-compressed, every file named after its device)
# plus SHA256SUMS and notes.md, which starts with the body of the tag's
# annotation; its subject is the release title.
#
#   gh run download <run id> -D artifacts
#   scripts/pv-release-assets.sh v0.1.2 artifacts release
#   gh release create v0.1.2 --notes-file release/notes.md \
#       --title "$(git tag -l --format='%(contents:subject)' v0.1.2)" \
#       $(ls release/* | grep -v notes.md)

set -e

tag="$1"
artifacts="$2"
out="$3"
[ -n "${tag}" ] && [ -d "${artifacts}" ] && [ -n "${out}" ] || {
	echo "usage: $0 <tag> <artifacts dir> <output dir>" >&2
	exit 1
}

repo="${GITHUB_REPOSITORY:-pantavisor/pv-ptxdist}"
base_url="https://github.com/${repo}/releases/download/${tag}"

describe() {
	case "$1" in
	orangepi5)	echo "Orange Pi 5" ;;
	orangepi5b)	echo "Orange Pi 5B" ;;
	rpi3)		echo "Raspberry Pi 3B+" ;;
	rpi4)		echo "Raspberry Pi 4" ;;
	qemu-arm64)	echo "QEMU arm64" ;;
	qemu-x86_64)	echo "QEMU x86_64" ;;
	*)		echo "$1" ;;
	esac
}

link() {
	echo "[$1](${base_url}/$1)"
}

mkdir -p "${out}"
rows=

for dir in "${artifacts}"/pv-ptxdist-*/; do
	device="$(basename "${dir}")"
	device="${device#pv-ptxdist-}"
	image= bsp= other=
	for f in "${dir}"*; do
		name="$(basename "${f}")"
		# The QEMU files have generic names (pv-hd.img, u-boot.rom,
		# pantavisor-bsp.pvrexport.tgz) that would clash between devices.
		case "${name}" in
		*"${device}"*)	;;
		pv-hd.*)	name="pv-${device}.${name#pv-hd.}" ;;
		*)		name="${name%%.*}-${device}.${name#*.}" ;;
		esac
		case "${name}" in
		*.img)
			xz -T0 -c "${f}" > "${out}/${name}.xz"
			image="$(link "${name}.xz")"
			;;
		*.pvrexport.tgz)
			cp "${f}" "${out}/${name}"
			bsp="$(link "${name}")"
			;;
		*)
			cp "${f}" "${out}/${name}"
			other="${other:+${other}, }$(link "${name}")"
			;;
		esac
	done
	rows="${rows}| $(describe "${device}") | ${image} | ${bsp} | ${other} |"$'\n'
done

(cd "${out}" && sha256sum -- * > SHA256SUMS)

{
	body="$(git tag -l --format='%(contents:body)' "${tag}")"
	[ -z "${body}" ] || printf '%s\n\n' "${body}"
	cat <<-EOF
	## Images

	| Device | Image | BSP | Also |
	|---|---|---|---|
	${rows}
	Checksums: $(link SHA256SUMS)

	Write a board image to an SD card or eMMC:

	\`\`\`sh
	xz -dc pv-orangepi5b.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
	\`\`\`

	The BSP (\`.pvrexport.tgz\`) is the signed kernel, initramfs, modules and
	firmware the image was built from, for updating a device with \`pvr\`.
	EOF
} > "${out}/notes.md"
