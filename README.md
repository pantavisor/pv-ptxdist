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

Build one device at a time with `scripts/pv-build.sh`. It runs in the build
container, selects the device's platform and toolchain, and builds only that
device's image and everything it needs:

```sh
git clone --recursive git@github.com:pantavisor/pv-ptxdist.git && cd pv-ptxdist
scripts/pv-docker.sh --pull          # once: fetch the build container

scripts/pv-build.sh orangepi5        # Orange Pi 5
scripts/pv-build.sh orangepi5b       # Orange Pi 5B
scripts/pv-build.sh rpi3             # Raspberry Pi 3B+
scripts/pv-build.sh rpi4             # Raspberry Pi 4
scripts/pv-build.sh qemu-arm64       # QEMU arm64
scripts/pv-build.sh qemu-x86_64      # QEMU x86_64
```

| Device | Platform | Image | Also produced |
|---|---|---|---|
| `orangepi5` | v8a | `platform-v8a/images/pv-orangepi5.img` | `pantavisor-bsp-orangepi5.pvrexport.tgz` |
| `orangepi5b` | v8a | `platform-v8a/images/pv-orangepi5b.img` | `pantavisor-bsp-orangepi5b.pvrexport.tgz` |
| `rpi3` | v8a | `platform-v8a/images/pv-rpi3.img` | `pantavisor-bsp-rpi3.pvrexport.tgz` |
| `rpi4` | v8a | `platform-v8a/images/pv-rpi4.img` | `pantavisor-bsp-rpi4.pvrexport.tgz` |
| `qemu-arm64` | v8a | `platform-v8a/images/pv-hd.img` | `u-boot.bin`, `pantavisor-bsp.pvrexport.tgz` |
| `qemu-x86_64` | x86_64 | `platform-x86_64/images/pv-hd.img` | `u-boot.rom`, `pantavisor-bsp.pvrexport.tgz` |

Each board has its own signed BSP (kernel, initramfs, modules and firmware
squashfs, and only that board's devicetree) and its own storage partition
with factory revision 0 (the BSP plus the pv-alpine-connman and pv-pvr-sdk
containers).

- Options after the device go to PTXdist, e.g. `scripts/pv-build.sh rpi4 -q`
  for a quiet build.
- `scripts/pv-build.sh --list` lists the devices.
- `--no-docker` builds on the host instead, which then needs PTXdist
  2026.10.0, the OSELAS.Toolchain 2025.11.1 toolchains in `/opt` and `swig`.
- The workspace has one selected platform at a time, but each platform keeps
  its own build tree, so switching between devices only rebuilds what
  changed.

### Choosing boards and containers

Both are menus in PTXdist's configuration:

| What | Command | Menu |
|---|---|---|
| The board a platform builds | `scripts/pv-docker.sh ptxdist menuconfig platform` | Pantavisor boards |
| Containers in revision 0 | `scripts/pv-docker.sh ptxdist menuconfig` | Pantavisor → containers in revision 0 |

- **Pantavisor boards** is a choice: the one board the selected platform
  builds (v8a: QEMU, Orange Pi 5, Orange Pi 5B, Raspberry Pi 3B+,
  Raspberry Pi 4; x86_64: QEMU). The board brings in its image, its own
  BSP and its bootloader, so `ptxdist images` builds only that board. The
  menu also holds the settings all boards share: boot and storage partition
  size, OEM kernel arguments, bootloader integration, squashfs compression.
  `scripts/pv-build.sh <device>` selects the board itself.
- **Containers in revision 0** applies to every board: pv-alpine-connman
  (network), pv-pvr-sdk (SDK shell over SSH; it turns on dm-crypt, since
  its volume is on the encrypted disk) and a list of extra container
  pvrexports.

The board menu is per platform: run `scripts/pv-build.sh <device>` (or
`ptxdist platform configs/platform-<name>/platformconfig`) first to select
the platform the menu should show. Choosing a board, in the menu or with
`pv-build.sh`, changes `configs/platform-<name>/platformconfig` and its
`.diff`: commit them to make it the platform's default board (v8a ships
with the Orange Pi 5B), or revert them.

### The build container

`ghcr.io/pantavisor/pv-ptxdist-builder` has PTXdist, the OSELAS toolchains
and all host dependencies; `docker/Dockerfile` builds it and CI publishes it
on changes to `docker/`. `scripts/pv-docker.sh` runs anything else in it:

```sh
scripts/pv-docker.sh --build               # build the container locally instead of pulling
scripts/pv-docker.sh ptxdist menuconfig    # any PTXdist command
scripts/pv-docker.sh                       # a shell
```

The workspace is mounted at its host path and commands run with your
uid/gid. The full workflow (daily work, menuconfig, testing, options) is in
[docs/building-with-docker.md](docs/building-with-docker.md).

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

Each job runs `scripts/pv-build.sh <device>`, which selects the board and
builds its image together with the BSP it is made from (the board's own
one, or the platform's generic one for QEMU), so one broken target never
blocks the others. It uploads the image with
that BSP and caches the `src/` download directory.

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

The run is triggered by pushes to `main`, tags (matching `v*`, e.g. a
release marker), pull requests, and `workflow_dispatch`; artifacts are
named `pv-ptxdist-<target>` per run. Doc-only pushes and pull requests
are skipped.

## Changing configs

Configs are stored as deltas to `base/`, and the `.diff` is what counts:
`oldconfig` regenerates the full config from it, so a hand edit of the full
config is lost. Change options with `ptxdist menuconfig` (`menuconfig
platform`, `menuconfig kernel`), or edit the `.diff` and run `ptxdist
oldconfig` (`oldconfig platform`, `oldconfig kernel`). Run the same after
updating `base/`. Commit both the config and its `.diff`.
