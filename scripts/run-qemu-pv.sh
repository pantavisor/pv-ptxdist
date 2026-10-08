#!/bin/bash
#
# Boot a Pantavisor image in QEMU.
#
# usage: scripts/run-qemu-pv.sh [--direct] <platform> [qemu args...]
#   e.g. scripts/run-qemu-pv.sh v8a
#
# Default: U-Boot (images/u-boot.bin as -bios) boots images/pv-hd.img through
# boot.scr, i.e. the same path as on hardware, including try-boot/rollback.
# --direct: boots images/linuximage + images/root.cpio.gz with the kernel
# arguments boot.scr would pass, on images/pv-storage.ext4, skipping U-Boot.
#
# The disk is a scratch copy grown to 4G (room for pv_e2fsgrow and updates);
# set PV_DISK to an existing file to keep state between runs.
# Dropbear (port 8222 on the device) is forwarded to 127.0.0.1:${PV_SSH_PORT:-8222}.

set -e

direct=
if [ "$1" = "--direct" ]; then
	direct=1
	shift
fi
platform="${1:?usage: $0 [--direct] <platform> [qemu args...]}"
shift

bsp="$(cd "$(dirname "$0")/.." && pwd)"
images="${bsp}/platform-${platform}/images"

if [ -n "${direct}" ]; then
	needed="linuximage root.cpio.gz pv-storage.ext4"
	disk_src="pv-storage.ext4"
else
	needed="u-boot.bin pv-hd.img"
	disk_src="pv-hd.img"
fi
for f in ${needed}; do
	if [ ! -e "${images}/${f}" ]; then
		echo "${images}/${f} missing; run 'ptxdist images' first" >&2
		exit 1
	fi
done

disk="${PV_DISK:-}"
if [ -z "${disk}" ]; then
	disk="$(mktemp --tmpdir "pv-${platform}.XXXXXX.img")"
	trap 'rm -f "${disk}"' EXIT
	cp "${images}/${disk_src}" "${disk}"
	truncate -s 4G "${disk}"
fi

case "${platform}" in
v8a)
	qemu=(qemu-system-aarch64 -M virt -cpu cortex-a57)
	console=ttyAMA0
	;;
v7a)
	qemu=(qemu-system-arm -M virt -cpu cortex-a7)
	console=ttyAMA0
	;;
*)
	echo "no QEMU setup for platform '${platform}'" >&2
	exit 1
	;;
esac

if [ -n "${direct}" ]; then
	boot=(
		-kernel "${images}/linuximage"
		-initrd "${images}/root.cpio.gz"
		-append "console=${console} panic=3 root=/dev/ram rootfstype=ramfs rdinit=/usr/bin/pantavisor pv_try=0 pv_rev=0"
	)
else
	boot=(-bios "${images}/u-boot.bin")
fi

# Not exec: the trap has to remove the scratch disk afterwards.
"${qemu[@]}" \
	-smp 2 -m 1024 -nographic \
	"${boot[@]}" \
	-drive if=none,file="${disk}",format=raw,id=hd0 \
	-device virtio-blk-device,drive=hd0 \
	-netdev user,id=net0,hostfwd=tcp:127.0.0.1:${PV_SSH_PORT:-8222}-:8222 \
	-device virtio-net-device,netdev=net0 \
	"$@"
