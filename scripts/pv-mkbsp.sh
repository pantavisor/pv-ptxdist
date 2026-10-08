#!/bin/bash
#
# Assemble, sign and export a Pantavisor BSP pvrexport.
#
# Port of do_compile from meta-pantavisor recipes-pv/images/pantavisor-bsp.bb
# (non-FIT, non-tryboot path). Called from rules/image-pv-bsp.make; all inputs
# come from the environment so the rule stays readable.
#
# Required:
#   PV_WORKDIR     scratch directory (wiped)
#   PV_OUTPUT      resulting .pvrexport.tgz
#   PV_SKEL        directory with device.json and bsp/drivers.json
#   PV_KERNEL      kernel image (raw Image/zImage/vmlinuz; *.gz is gunzipped)
#   PV_INITRD      initramfs (cpio.gz)
#   PV_CA_KEYS     pvs.defaultkeys.tar.gz from host-pv-developer-ca
# Optional:
#   PV_MODULES     lib/modules/<kver> directory of the kernel
#   PV_FIRMWARE    space separated list of firmware directories to merge
#   PV_FDT         device tree blob to ship as the initial fdt
#   PV_DTBS        space separated <file>:<bsp path> device trees for
#                  boot.scr's bsp/${fdtfile} lookup
#   PV_SQUASHFS_OPTS  mksquashfs compression options (default: -comp xz)
#   PVR_SIG_KEY / PVR_X5C_PATH  production signing key and certificate chain

set -e

: "${PV_WORKDIR:?}" "${PV_OUTPUT:?}" "${PV_SKEL:?}" "${PV_KERNEL:?}"
: "${PV_INITRD:?}" "${PV_CA_KEYS:?}"
squashfs_opts="${PV_SQUASHFS_OPTS:--comp xz}"

rm -rf "${PV_WORKDIR}"
mkdir -p "${PV_WORKDIR}"/{home/.pvr,tmp,mods,fw,repo}

# Keep pvr away from the user's ~/.pvr and its self-upgrade check.
export HOME="${PV_WORKDIR}/home"
export TMPDIR="${PV_WORKDIR}/tmp"
export PVR_DISABLE_SELF_UPGRADE=true
tar -C "${HOME}/.pvr" --no-same-owner -xf "${PV_CA_KEYS}"

if [ -n "${PV_MODULES}" ]; then
	cp -a "${PV_MODULES}/." "${PV_WORKDIR}/mods/"
	# build/source point back into the kernel build tree
	rm -f "${PV_WORKDIR}/mods/build" "${PV_WORKDIR}/mods/source"
fi
for fw in ${PV_FIRMWARE}; do
	[ -d "${fw}" ] && cp -a "${fw}/." "${PV_WORKDIR}/fw/"
done

cd "${PV_WORKDIR}/repo"
cp -a "${PV_SKEL}/." .
pvr init
pvr add
pvr commit
mkdir -p bsp

# Pantavisor mounts both unconditionally when run.json names them, so emit
# them even when empty.
mksquashfs "${PV_WORKDIR}/mods" bsp/modules.squashfs -all-root -noappend ${squashfs_opts}
mksquashfs "${PV_WORKDIR}/fw" bsp/firmware.squashfs -all-root -noappend ${squashfs_opts}

case "${PV_KERNEL}" in
*.gz)	gunzip -c "${PV_KERNEL}" > bsp/kernel.img ;;
*)	cp "${PV_KERNEL}" bsp/kernel.img ;;
esac
cp "${PV_INITRD}" bsp/pantavisor

for dtb in ${PV_DTBS}; do
	install -D -m 0644 "${dtb%%:*}" "bsp/${dtb#*:}"
done

fdt_entry=
if [ -n "${PV_FDT}" ]; then
	cp "${PV_FDT}" "bsp/$(basename "${PV_FDT}")"
	fdt_entry="
	\"fdt\": \"$(basename "${PV_FDT}")\","
fi

cat > bsp/run.json <<EOF
{
	"addons": [],
	"initrd": "pantavisor",
	"linux": "kernel.img",
	"firmware": "firmware.squashfs",
	"modules": "modules.squashfs",${fdt_entry}
	"initrd_config": ""
}
EOF
echo '{}' > bsp/src.json

pvr add
pvr commit
pvr checkout -c
pvr sig add --raw bsp \
	--include 'bsp/**' \
	--include 'device.json' \
	--include '#spec' \
	--exclude 'bsp/src.json'
pvr add
pvr commit
pvr sig up
pvr add
pvr commit

pvr export "${PV_OUTPUT}"
