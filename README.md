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
| `configs/platform-v8a/*.diff` | v8a platform and kernel deltas: U-Boot instead of barebox, Pantavisor images, kernel fragments |
| `configs/platform-v8a/u-boot*.config` | U-Boot for QEMU arm64 and the Orange Pi 5B |
| `configs/kernel-fragments/` | Kernel fragments, merged into the kernel delta with `scripts/merge-pv-kernel-fragments.sh` |
| `configs/pantavisor/` | Device skel, `pantahub.config`, boot script sources |
| `rules/`, `platforms/` | Pantavisor packages and the `image-pv-*` image types |

Only v8a carries Pantavisor changes so far; the other DistroKit platforms
build DistroKit's own images.

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
- `pv-storage.ext4`: storage partition with factory revision 0 (BSP plus pv-alpine-connman)
- `pv-hd.img`: boot vfat plus storage, for QEMU arm64
- `pv-orangepi5b.img`: Orange Pi 5B SD/eMMC image

## Run

```sh
scripts/run-qemu-pv.sh v8a            # U-Boot boots pv-hd.img
scripts/run-qemu-pv.sh --direct v8a   # kernel + initramfs, no U-Boot
```

Press Enter at `Press [ENTER] for debug ash shell...` for a shell;
Ctrl-A X quits QEMU.

## Changing configs

Configs are stored as deltas to `base/`, and the `.diff` is what counts:
`oldconfig` regenerates the full config from it, so a hand edit of the full
config is lost. Change options with `ptxdist menuconfig` (`menuconfig
platform`, `menuconfig kernel`), or edit the `.diff` and run `ptxdist
oldconfig` (`oldconfig platform`, `oldconfig kernel`). Run the same after
updating `base/`. Commit both the config and its `.diff`.
