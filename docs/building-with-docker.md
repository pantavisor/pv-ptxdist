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

3. Select the configuration. This only creates the `selected_*` symlinks in
   the workspace, so it is needed once per clone:

   ```sh
   scripts/pv-docker.sh sh -c '
   	ptxdist select configs/ptxconfig &&
   	ptxdist platform configs/platform-v8a/platformconfig &&
   	ptxdist toolchain /opt/OSELAS.Toolchain-2025.11.1/aarch64-v8a-linux-gnu/gcc-15.2.1-clang-21.1.8-glibc-2.42-binutils-2.45.1-kernel-6.17.6-sanitized/bin'
   ```

4. Build:

   ```sh
   scripts/pv-docker.sh ptxdist -j$(nproc) images
   ```

   A first build takes a while and downloads the sources into `src/`. The
   results are in `platform-v8a/images/`:

   | File | What |
   |---|---|
   | `pv-hd.img` | QEMU arm64 disk: boot partition plus storage |
   | `pv-orangepi5b.img` | Orange Pi 5B SD card / eMMC image |
   | `pv-rpi4.img` | Raspberry Pi 4 SD card image |
   | `pantavisor-bsp.pvrexport.tgz` | Signed BSP, for updates through Pantahub |
   | `pv-storage.ext4` | Storage partition with factory revision 0 |
   | `u-boot.bin` | U-Boot for QEMU (`-bios`) |

## Daily work

Run any PTXdist command through the script. It stays in the current
directory when that is inside the workspace.

```sh
scripts/pv-docker.sh ptxdist clean pantavisor      # rebuild one package
scripts/pv-docker.sh ptxdist targetinstall pantavisor
scripts/pv-docker.sh ptxdist images                # regenerate the images
```

Kconfig menus work as well, since the script passes the terminal through:

```sh
scripts/pv-docker.sh ptxdist menuconfig            # userland (ptxconfig)
scripts/pv-docker.sh ptxdist menuconfig platform   # platform, images
scripts/pv-docker.sh ptxdist menuconfig kernel
scripts/pv-docker.sh ptxdist menuconfig u-boot-orangepi5b
scripts/pv-docker.sh ptxdist menuconfig u-boot-rpi4
```

Configs are deltas to `base/`: commit both the config and its `.diff`
afterwards (see "Changing configs" in the README).

For several commands in a row, open a shell instead:

```sh
scripts/pv-docker.sh
# now inside the container, in the workspace
ptxdist go
ptxdist images
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
