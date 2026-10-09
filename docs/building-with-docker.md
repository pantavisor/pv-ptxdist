# Building with the container

`scripts/pv-docker.sh` runs PTXdist in a container that has everything the
build needs: PTXdist 2026.10.0, the OSELAS.Toolchain 2025.11.1 toolchains
(aarch64-v8a, arm-v7a, x86-64) and the host packages. The only things the
build machine needs are Docker and git.

## How it works

- The image is `ghcr.io/pantavisor/pv-ptxdist-builder:ptxdist-2026.10.0`,
  built from `docker/Dockerfile`. CI publishes it when `docker/` changes on
  `main`.
- The workspace is mounted at the same path as on the host, because PTXdist
  stores absolute paths in the build tree.
- Commands run with your uid and gid, so everything the build writes belongs
  to you.
- The container is removed after each command; only the workspace keeps
  state.

## First build

1. Clone with the DistroKit base layer:

   ```sh
   git clone --recursive git@github.com:pantavisor/pv-ptxdist.git
   cd pv-ptxdist
   ```

   In an existing clone without `base/`: `git submodule update --init`.

2. Get the image. Pull it from the registry:

   ```sh
   scripts/pv-docker.sh --pull
   ```

   While the package is private, log in first with a GitHub token that has
   `read:packages`:

   ```sh
   echo <token> | docker login ghcr.io -u <github-user> --password-stdin
   ```

   Or build it locally instead (about 10 minutes, 5.7 GB):

   ```sh
   scripts/pv-docker.sh --build
   ```

3. Build a device:

   ```sh
   scripts/pv-build.sh orangepi5b       # or rpi4, qemu-arm64, qemu-x86_64
   ```

   `scripts/pv-build.sh` selects the device's platform and toolchain in the
   workspace and builds only that device's image, plus everything the image
   needs. A first build takes a while and downloads the sources into
   `src/`. It ends by listing what it produced:

   | Device | Image | Also produced |
   |---|---|---|
   | `orangepi5b` | `platform-v8a/images/pv-orangepi5b.img` | `pantavisor-bsp-orangepi5b.pvrexport.tgz` |
   | `rpi4` | `platform-v8a/images/pv-rpi4.img` | `pantavisor-bsp-rpi4.pvrexport.tgz` |
   | `qemu-arm64` | `platform-v8a/images/pv-hd.img` | `u-boot.bin`, `pantavisor-bsp.pvrexport.tgz` |
   | `qemu-x86_64` | `platform-x86_64/images/pv-hd.img` | `u-boot.rom`, `pantavisor-bsp.pvrexport.tgz` |

   The `.pvrexport.tgz` is the device's signed BSP, for updates through
   Pantahub. Options after the device go to PTXdist
   (`scripts/pv-build.sh rpi4 -q`), and `scripts/pv-build.sh --list` lists
   the devices.

## Daily work

Rebuild a device's image after a change with the same command,
`scripts/pv-build.sh <device>`. Switching to a device of another platform
keeps the other platform's build tree, so going back later is quick.

Any other PTXdist command runs through `scripts/pv-docker.sh`, in the
platform the last `pv-build.sh` selected. It stays in the current directory
when that is inside the workspace.

```sh
scripts/pv-docker.sh ptxdist clean pantavisor      # force one package to rebuild
scripts/pv-build.sh orangepi5b                     # then the image again
```

Kconfig menus work as well, since the script passes the terminal through:

```sh
scripts/pv-docker.sh ptxdist menuconfig            # userland (ptxconfig)
scripts/pv-docker.sh ptxdist menuconfig platform   # platform, images
scripts/pv-docker.sh ptxdist menuconfig kernel
scripts/pv-docker.sh ptxdist menuconfig u-boot-orangepi5b
scripts/pv-docker.sh ptxdist menuconfig u-boot-rpi4
```

Which boards a platform builds is the Pantavisor boards menu of
`ptxdist menuconfig platform`; which containers go into revision 0 is
Pantavisor → containers in revision 0 in `ptxdist menuconfig` (see
"Choosing boards and containers" in the README).

Configs are deltas to `base/`: commit both the config and its `.diff`
afterwards (see "Changing configs" in the README).

For several commands in a row, open a shell instead:

```sh
scripts/pv-docker.sh
# now inside the container, in the workspace
ptxdist targetinstall pantavisor
ptxdist image pv-orangepi5b.img
exit
```

## Testing

QEMU is not in the image; run it on the host (`qemu-system-arm` and
`qemu-system-x86` packages on Ubuntu/Debian):

```sh
scripts/run-qemu-pv.sh v8a      # QEMU arm64: U-Boot boots pv-hd.img
scripts/run-qemu-pv.sh x86_64   # QEMU x86_64: u-boot.rom boots pv-hd.img
```

Both boot the same path as on hardware: U-Boot loads `boot.scr`, boots
factory revision 0 of `pv-hd.img` and Pantavisor brings up the `os`
container, `pvr-sdk` and the encrypted `dm-versatile` secrets disk.
Press Enter at `Press [ENTER] for debug ash shell...` for a shell on the
device; Ctrl-A X quits QEMU.

Set `PV_DISK=/path/to/disk.img` to keep the disk between runs
(update installs, Pantahub device identity): copy `pv-hd.img` first —
`cp` truncates — then `truncate -s 4G` as shown in the README's Run
section. Debug logs are on the storage partition
(`/logs/0/pantavisor/pantavisor.log`), not the console; extract them with
`debugfs`, see the README's Run section.

For the Orange Pi 5B, write `platform-v8a/images/pv-orangepi5b.img` to an SD
card or to the eMMC (with `rkdeveloptool`), and watch the serial console at
1500000 baud. For the Raspberry Pi 4, write `pv-rpi4.img` to an SD card and
watch its serial console at 115200 baud.

## CI

The `.github/workflows/build.yml` workflow builds three targets, one job
each (`orangepi5b`, `rpi4`, `qemu_x86`) inside the `pv-ptxdist-builder`
container, on the self-hosted machines with the `bsp-builder` label. Each
job runs `ptxdist image <img>` and uploads the image plus the signed
`pantavisor-bsp.pvrexport.tgz` as the `pv-ptxdist-<target>` artifact.

The runner box only needs Docker: the workflow creates a non-root
`builder` user (PTXdist refuses to run as root), gives it the docker
socket and makes the runner workspace path traversable for it; machine
requirements are listed in the README's CI section.

## Options

| Variable | Default | Use |
|---|---|---|
| `PV_DOCKER_IMAGE` | `ghcr.io/pantavisor/pv-ptxdist-builder:ptxdist-2026.10.0` | Another image or tag, e.g. a locally built test image |
| `PV_DOCKER_ARGS` | | Extra `docker run` arguments, word-split |

For example, to share a source download directory between several clones,
make `src` a symlink to it; the script mounts the target as well:

```sh
ln -s ~/ptxdist-src src
```

Or mount something extra:

```sh
PV_DOCKER_ARGS="-v $HOME/keys:$HOME/keys:ro" scripts/pv-docker.sh ptxdist images
```

`--pull` and `--build` can be followed by a command, which then runs in the
fresh image:

```sh
scripts/pv-docker.sh --pull ptxdist images
```

## Notes

- **Inside and outside.** A build tree can be used both inside and outside
  the container only if the host has the same toolchain path and a
  compatible distribution (Ubuntu 24.04): host tools PTXdist built in the
  container link against the container's libraries. When in doubt, stick to
  one of the two for a given workspace.
- **Disk space.** A v8a build tree is about 10 GB, plus the 5.7 GB image.
- **Updating the image.** After `docker/Dockerfile` changes, run
  `--pull` (once CI has published) or `--build`. PTXdist host packages that
  depend on what changed may need a `ptxdist clean` of the affected host
  package.
- **Permission errors on files in the workspace** come from a build run as
  root, e.g. a manual `docker run` without the script. Fix the owner with
  `sudo chown -R $(id -u):$(id -g) platform-v8a`.
