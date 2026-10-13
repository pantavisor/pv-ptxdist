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

# The same machine and devices as scripts/run-qemu-pv.sh, which needs a
# build tree; these work with the downloaded files alone.
#   $1: device, $2: image, $3: U-Boot firmware
qemu_howto() {
	local qemu dev
	case "$1" in
	qemu-x86_64)
		# U-Boot's qemu-x86_64 build supports i440fx, not q35.
		qemu="qemu-system-x86_64 -M pc"
		dev=pci
		;;
	qemu-arm64)
		qemu="qemu-system-aarch64 -M virt -cpu cortex-a57"
		dev=device
		;;
	*)
		return 0
		;;
	esac
	cat <<-EOF

	### $(describe "$1")

	\`\`\`sh
	xz -dc $2.xz > $2
	truncate -s 4G $2    # room for the storage partition to grow
	${qemu} -smp 2 -m 1024 -nographic \\
	    -bios $3 \\
	    -drive if=none,file=$2,format=raw,id=hd0 \\
	    -device virtio-blk-${dev},drive=hd0 \\
	    -netdev user,id=net0,hostfwd=tcp:127.0.0.1:8222-:8222 \\
	    -device virtio-net-${dev},netdev=net0
	\`\`\`
	EOF
}

mkdir -p "${out}"
rows=
qemu=

for dir in "${artifacts}"/pv-ptxdist-*/; do
	device="$(basename "${dir}")"
	device="${device#pv-ptxdist-}"
	image= bsp= other= image_name= firmware=
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
			image_name="${name}"
			;;
		*.pvrexport.tgz)
			cp "${f}" "${out}/${name}"
			bsp="$(link "${name}")"
			;;
		*)
			cp "${f}" "${out}/${name}"
			other="${other:+${other}, }$(link "${name}")"
			case "${name}" in u-boot*) firmware="${name}" ;; esac
			;;
		esac
	done
	rows="${rows}| $(describe "${device}") | ${image} | ${bsp} | ${other} |"$'\n'
	qemu="${qemu}$(qemu_howto "${device}" "${image_name}" "${firmware}")"
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
	[ -z "${qemu}" ] || cat <<-EOF

	## Run in QEMU

	U-Boot boots the image the same way as on hardware. The image file is the
	device's disk and keeps its state between runs; decompress it again for
	a fresh device.
	${qemu}

	- Press Enter at \`Press [ENTER] for debug ash shell...\` for a debug
	  shell. Ctrl-A X quits QEMU.
	- The device's SSH port 8222 is forwarded to 127.0.0.1:8222.
	- U-Boot tries a FIT image and several boot commands before the one
	  that works, so \`Failed to load fit\` and an \`ERROR\` or two before
	  \`Starting kernel ...\` are expected.
	EOF
} > "${out}/notes.md"
