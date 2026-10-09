# pv-ptxdist

A [PTXdist](https://www.ptxdist.org) layer that builds
[Pantavisor](https://github.com/pantavisor/pantavisor) on top of
[DistroKit](https://git.pengutronix.de/cgit/DistroKit), the Pengutronix
reference BSP. DistroKit sits unmodified in `base/`; this layer only adds
packages, image types and config deltas (`*.diff`) against it.

Needs PTXdist 2026.10.0 and OSELAS.Toolchain 2025.11.1.

The `distrokit` branch is upstream DistroKit plus its migration to PTXdist
2026.10.0, which upstream has not done yet. Once it has, `base/` can point at
upstream DistroKit directly.

## Layout

| Path | What |
|---|---|
| `base/` | DistroKit (git submodule, the `distrokit` branch of this repository) |
| `configs/ptxconfig{,.diff}` | Pantavisor initramfs userland, as a delta to DistroKit's |
| `configs/platform-v8a/*.diff` | v8a kernel delta: U-Boot instead of barebox, Pantavisor images, kernel fragments |
| `configs/platform-x86_64/*.diff` | x86_64 platform and kernel deltas, created for the QEMU target |
| `configs/platform-v8a/u-boot*.config` | U-Boot for QEMU arm64, the Orange Pi 5B and the Raspberry Pi 4 |
| `configs/platform-x86_64/u-boot.config` | U-Boot qemu-x86_64, the QEMU firmware |
| `configs/kernel-fragments/` | Kernel fragments, merged into the kernel delta with `scripts/merge-pv-kernel-fragments.sh` |
| `configs/pantavisor/` | Device skel, `pantahub.config`, boot script sources |
| `rules/`, `platforms/` | Pantavisor packages (including `host-pv-pvr-sdk`) and the `image-pv-*` image types |

The v8a and x86_64 platforms carry the Pantavisor changes; the other
DistroKit platforms build DistroKit's own images.

## Build

```sh
git clone --recursive <this repo> pv-ptxdist && cd pv-ptxdist
ptxdist select configs/ptxconfig
ptxdist platform configs/platform-v8a/platformconfig
ptxdist toolchain /opt/OSELAS.Toolchain-2025.11.1/aarch64-v8a-linux-gnu/gcc-15.2.1-clang-21.1.8-glibc-2.42-binutils-2.45.1-kernel-6.17.6-sanitized/bin
ptxdist images
```

Build host needs `swig` (U-Boot binman for Rockchip).

### In the build container

`ghcr.io/pantavisor/pv-ptxdist-builder` has PTXdist, the OSELAS toolchains
and all host dependencies; `docker/Dockerfile` builds it and CI publishes it
on changes to `docker/`.

```sh
scripts/pv-docker.sh --pull                # fetch the image
scripts/pv-docker.sh ptxdist images        # run one command
scripts/pv-docker.sh                       # or a shell
scripts/pv-docker.sh --build               # build the image locally instead
```

The workspace is mounted at its host path and commands run with your
uid/gid. The full workflow (first build, daily work, menuconfig, testing,
options) is in [docs/building-with-docker.md](docs/building-with-docker.md).

Outputs in `platform-v8a/images/`:

- `pantavisor-bsp.pvrexport.tgz`: signed BSP (kernel, initramfs, modules and firmware squashfs)
- `pv-storage.ext4`: storage partition with factory revision 0 (BSP plus pvr-sdk)
- `pv-hd.img`: boot vfat plus storage, for QEMU arm64
- `pv-orangepi5b.img`: Orange Pi 5B SD/eMMC image
- `pv-rpi4.img`: Raspberry Pi 4 SD image

Build one image only with `ptxdist image <img>` — e.g.
`scripts/pv-docker.sh ptxdist image pv-orangepi5b.img` — which is what the
CI does per target.

`platform-x86_64/images/` has the same layout for the QEMU x86_64 target
(`pv-hd.img` plus `u-boot.rom` as firmware).

## Run

```sh
scripts/run-qemu-pv.sh v8a     # U-Boot boots pv-hd.img (QEMU arm64)
scripts/run-qemu-pv.sh x86_64  # U-Boot.rom boots pv-hd.img (QEMU x86_64)
```

Details:

- The image boots the same path as on hardware: the U-Boot firmware
  (`u-boot.bin` / `u-boot.rom`) loads `boot.scr` and boots factory revision 0
  from `pv-hd.img`, including try-boot/rollback. PVR-SDK, `os` and the
  encrypted `dm-versatile` secrets disk come up in revision 0; Pantavisor
  reaches state READY with no reboots. `--direct` boots kernel + initramfs
  on `pv-storage.ext4` without U-Boot, skipping the bootloader entirely.
- `PV_DISK=/path/to/disk.img` keeps state between runs (update installs,
  Pantahub device identity). Without it, the disk is a fresh scratch copy of
  `pv-hd.img` grown to 4G on every run and deleted on exit. Copy the image
  *before* growing the file, since `cp` truncates:
  `cp images/pv-hd.img $PV_DISK && truncate -s 4G $PV_DISK`.
- Dropbear (port 8222 on the device) is forwarded to 127.0.0.1:8222
  (`PV_SSH_PORT` selects a different local port).
- Press Enter at `Press [ENTER] for debug ash shell...` for a Pantavisor
  debug ash shell; Ctrl-A X quits QEMU.
- Pantavisor logs live on the storage partition (partition 2), not on the
  console. Extract and grep them after a bad run for `ERROR`:

  ```sh
  dd if=$PV_DISK bs=512 skip=133120 count=2097152 of=/tmp/vda2.img
  debugfs -R "dump /logs/0/pantavisor/pantavisor.log /tmp/pv.log" /tmp/vda2.img
  grep ERROR /tmp/pv.log
  ```

- Try-boot/rollback is active, exactly like on hardware. If a revision has
  bad volumes, Pantavisor rolls back and reboots; with factory revision 0
  as the only revision, errors end in a reboot loop, so read the log on
  the storage partition before blaming the image or the bootloader.

## CI

`.github/workflows/build.yml` builds three targets, one job each:

| Job | Platform | Builds | Artifact |
|---|---|---|---|
| `orangepi5b` | v8a | `pv-orangepi5b.img` | image + signed BSP |
| `rpi4` | v8a | `pv-rpi4.img` | image + signed BSP |
| `qemu_x86` | x86_64 | `pv-hd.img` | image, `u-boot.rom` and signed BSP |

Each job runs `ptxdist image <img>` together with
`pantavisor-bsp.pvrexport.tgz`, so one broken target never blocks the
others, and runs `actions/cache` on the `src/` download directory.

Jobs run on the self-hosted `bsp-builder` machines (the fleet label
meta-pantavisor's `buildkas-target.yaml` uses). Machine requirements:

- Docker available; jobs may run as root, the workflow then creates a
  non-root `builder` user (idempotently, flock-guarded, with `useradd` or
  `adduser`) and only falls back to an existing regular account when the
  shadow tools are missing. The user gets access to the docker socket
  (usually the `docker` group).
- PTXdist refuses to run as root; the workflow handles that, and the build
  never touches the host otherwise: everything happens inside the
  `pv-ptxdist-builder` container.
- ptxdist reaches the workspace by absolute path while some runner hosts
  keep the runner home at 750; the workflow opens those paths for
  traversal (chmod a+x).
- keep at least ~30 GB free: ~10 GB build tree, 5.7 GB container, plus the
  `src/` downloads cache.

The run is triggered by pushes to `main`, pull requests, and
`workflow_dispatch`; artifacts are named `pv-ptxdist-<target>`.

## Changing configs

Configs are stored as deltas to `base/`, and the `.diff` is what counts:
`oldconfig` regenerates the full config from it, so a hand edit of the full
config is lost. Change options with `ptxdist menuconfig` (`menuconfig
platform`, `menuconfig kernel`), or edit the `.diff` and run `ptxdist
oldconfig` (`oldconfig platform`, `oldconfig kernel`). Run the same after
updating `base/`. Commit both the config and its `.diff`.
