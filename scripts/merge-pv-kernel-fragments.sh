#!/bin/bash
#
# Merge kernel config fragments into a platform's kernel config delta.
#
# usage: scripts/merge-pv-kernel-fragments.sh <platform> [extra fragments...]
#   e.g. scripts/merge-pv-kernel-fragments.sh v8a configs/kernel-fragments/rpi4.cfg
#
# The layer keeps configs/platform-<platform>/kernelconfig.diff, a delta to
# DistroKit's kernelconfig in base/. 'ptxdist oldconfig kernel' regenerates
# the full kernelconfig from that delta, so fragments go into the delta: each
# symbol a fragment sets replaces the delta's line for it. Afterwards run
# 'ptxdist oldconfig kernel', which resolves dependencies and rewrites both
# files.

set -e

platform="${1:?usage: $0 <platform> [extra fragments...]}"
shift

bsp="$(cd "$(dirname "$0")/.." && pwd)"
frags="${bsp}/configs/kernel-fragments"
diff="${bsp}/configs/platform-${platform}/kernelconfig.diff"

if [ ! -e "${diff}" ]; then
	echo "${diff} missing; copy base/configs/platform-${platform}/kernelconfig" >&2
	echo "into the layer and run 'ptxdist oldconfig kernel' first" >&2
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
	"$@"
)

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT
cp "${diff}" "${tmp}"

for frag in "${fragments[@]}"; do
	sed -n -e 's/^\(CONFIG_[A-Za-z0-9_]*\)=.*/\1/p' \
		-e 's/^# \(CONFIG_[A-Za-z0-9_]*\) is not set$/\1/p' "${frag}" |
	while read -r sym; do
		# the first two lines are the checksums of the base and this config
		sed -i -e "3,\$ { /^${sym}=/d; /^# ${sym} is /d }" "${tmp}"
	done
	grep -E '^(CONFIG_[A-Za-z0-9_]+=|# CONFIG_[A-Za-z0-9_]+ is not set$)' "${frag}" >> "${tmp}"
done

cp "${tmp}" "${diff}"
echo "merged into ${diff}; now run: ptxdist oldconfig kernel"
