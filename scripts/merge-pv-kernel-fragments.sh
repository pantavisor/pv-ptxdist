#!/bin/bash
#
# Merge the Pantavisor kernel config fragments into a platform kernelconfig.
#
# PTXdist has no notion of config fragments, so the merged result is what
# gets committed. Re-run this after rebasing a platform's kernelconfig.
#
# usage: scripts/merge-pv-kernel-fragments.sh <platform> [extra fragments...]
#   e.g. scripts/merge-pv-kernel-fragments.sh v8a
#
# The kernel must already be extracted ('ptxdist extract kernel') for the
# selected platform, as its scripts/kconfig/merge_config.sh is used.

set -e

platform="${1:?usage: $0 <platform> [extra fragments...]}"
shift

bsp="$(cd "$(dirname "$0")/.." && pwd)"
frags="${bsp}/configs/kernel-fragments"
kconfig="${bsp}/configs/platform-${platform}/kernelconfig"

kdir="$(ls -d "${bsp}/platform-${platform}"/build-target/linux-* 2>/dev/null | head -n1)"
if [ ! -x "${kdir}/scripts/kconfig/merge_config.sh" ]; then
	echo "kernel source for '${platform}' not found; run 'ptxdist extract kernel' first" >&2
	exit 1
fi

# meta-pantavisor's default set (linux-%.bbappend) plus the BSP's own.
fragments=(
	"${frags}/overlayfs.cfg"
	"${frags}/pantavisor.cfg"
	"${frags}/pvcrypt.cfg"
	"${frags}/dm.cfg"
	"${frags}/pv-nftables.cfg"
	"${frags}/pv-kernel-6.x.cfg"
)
# merge_config.sh runs from a temporary directory
for f in "$@"; do
	fragments+=("$(realpath "${f}")")
done

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

# -m: merge only; 'ptxdist oldconfig kernel' does the olddefconfig pass with
# the right ARCH and cross compiler.
(cd "${tmp}" && "${kdir}/scripts/kconfig/merge_config.sh" -m -O "${tmp}" \
	"${kconfig}" "${fragments[@]}")

cp "${tmp}/.config" "${kconfig}"
echo "merged into ${kconfig}; now run: ptxdist oldconfig kernel"
