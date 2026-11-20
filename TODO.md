# Upstreaming Pantavisor support to PTXdist

What is left before this layer's Pantavisor support can go to the PTXdist
mailing list as an `[RFC PATCH]` series, and what the RFC should ask.

PTXdist takes patches by mail (`git send-email` to the PTXdist list), each
with a `Signed-off-by:`. New and changed packages must pass `ptxdist lint`
and `ptxdist licensecheck`, pin every configure option, and have help text.
Patches are based on PTXdist `master`, not on a release.

## Status

| Package | In this layer | Upstream form |
|---|---|---|
| mbedtls | Stock package, rule bumped to 2.28.10 (`rules/mbedtls.make`) | PTXdist patch to write |
| dropbear | Stock 2026.94 + `-n` patch; rules with `DROPBEAR_GENKEYS` (`rules/dropbear.*`) | PTXdist patch to write |
| busybox | Stock 1.38.0 + 5 Pantavisor patches | PTXdist patch to write |
| libaio | `rules/libaio.make` backport | Already in PTXdist (5017a47); drop with the next release |
| lxc | `lxc6-pv` (LXC 6 fork, `bfa6810a`); `lxc-pv` (LXC 3) kept as the deprecated choice | Bump PTXdist's lxc 3.0.1 to 6.0.x (meson) plus 11 fork patches; see section 3 |
| libevent | Still `libevent-pv` 2.2.1-alpha | Blocked |
| picohttpparser, libthttp, pantavisor | Layer packages | The RFC itself |

## 1. Stand-alone PTXdist patches (send before the RFC)

- [ ] **mbedtls: version bump 2.28.0 -> 2.28.10.** Turn the diff between
      `rules/mbedtls.make` and PTXdist's into a patch on PTXdist master,
      noting the license change to `Apache-2.0 OR GPL-2.0-or-later`. The
      pk_wrap.c patch (`patches/mbedtls-2.28.10/`) is Pantavisor-specific:
      send it with the RFC, or to mbed TLS first.
- [ ] **dropbear: add DROPBEAR_GENKEYS.** The diff between
      `rules/dropbear.{in,make,postinst}` and PTXdist's. The postinst guard
      matches openssh's. Without it, enabling dropbear selects INITMETHOD,
      whose default is systemd.
- [x] **busybox: fix the `mdev -s` crash first.** `0304` (MODALIAS) passed
      a NULL device name to `regexec()` for PCI devices without `DEVNAME`
      as soon as `mdev.conf` had a device-name rule. `0305` skips name
      rules for those devices; tested natively and on qemu-arm64.
- [ ] **busybox: add the Pantavisor patches.** Add 0300-0305 to
      PTXdist's `patches/busybox-1.38.0/series`, and put
      `FEATURE_MDEV_FOLLOW_X_ROOT` into `config/busybox/util-linux/Config.in`.
      That lets `rules/busybox-pantavisor.in` go away (a layer can only
      override all of `config/busybox`, so it lives there for now).
      The series is cleaned up: `-F` is a flag again, `-c` is documented,
      nsenter links without setpriv/run-init, `chdir()`/`chroot()` are
      checked when following the root, and nsenter.c and mdev.c build with
      no warnings beyond stock 1.38.0's. Every patch builds on its own.
- [x] **lxc: version bump 3.0.1 -> 6.0.6.** Written on PTXdist master
      (4da61501e): `upstream/ptxdist/0001-lxc-version-bump-3.0.1-6.0.6.patch`.
      Meson, every option pinned (`configure_helper.py` shows no
      difference), license set. Cross-built and target-installed with
      `LXC_TEST_TOOLS` on v8a; `lint` and `licensecheck` pass. Stock 6.0.6
      needs no gold patch: meson falls back when the linker has no gold.
      Not built: `LXC_SYSTEMD_UNIT` (needs `INITMETHOD_SYSTEMD`). Not run
      on a target.
- [ ] Before sending each one, rebase it on current PTXdist master and run
      `ptxdist lint` and `ptxdist licensecheck <pkg>`.

## 2. Upstream projects first

PTXdist prefers patches that the upstream project has accepted or at
least reviewed. Where that is possible, send them there first:

- [ ] **dropbear `-n` any-user mode** (`patches/dropbear-2026.94/0200-*`):
      offer it to dropbear upstream (Matt Johnston). If it is refused,
      the RFC has to argue for carrying it in PTXdist.
- [ ] **busybox patches**, mostly generic: nsenter `-C` and `--caps`, the
      netlink and MODALIAS fixes. Send them to the busybox list;
      `FOLLOW_X_ROOT` is more Pantavisor-specific.
- [ ] **Pantavisor** (Pantacor's repo, easy):
  - [ ] Merge `patches/pantavisor-031/0001-gen_version-allow-overriding-the-version-via-PV_GIT_.patch`.
  - [ ] Drop `#include <lxc/pv_export.h>` from `plugins/pv_lxc.c`.
        Nothing uses it, and it is the only reason lxc would need to
        install that header.
  - [ ] Test setting `lxc.cgroup.dir` to `lxc/<name>` per container, so
        that lxc's default `lxc.payload.` prefix can stay (section 3).
- [ ] **lxc 6 fork patches**: LXC 6.0 is maintained (LTS), so send the
      generic ones in section 3 to `lxc/lxc` first, before PTXdist.

## 3. lxc: replace lxc6-pv with stock lxc 6 + patches

The layer builds `lxc6-pv`, meta-pantavisor's LXC 6 fork
(`stable-6.0-BASE-f9ff9ea2a` at `bfa6810a`): upstream `stable-6.0` (v6.0.5
+ 17 upstream commits) plus 14 Pantavisor commits, and meta-pantavisor's
patch that stops meson forcing the gold linker. Pantavisor runs it with
`PV_SYSTEM_CGROUP_VERSION=auto`, so cgroup v2 on our kernels (they have
`CGROUP_BPF`). LXC 3 (`lxc-pv`) stays as the deprecated menu choice.

### Generic: send to lxc upstream, then carry in PTXdist

- [ ] `9343fe09` block SIGCHLD in run_buffer (a fix).
- [ ] `04fe2f99` conf: match pivot_root mount propagation in lxc_chroot
      (a fix).
- [ ] `5efac56d` lxc_string_split_quoted: handle escaped characters.
- [ ] `aa2b45c3` hook commands with parameters.
- [ ] `bfa6810a` the `lxc.tty.min` key.
- [ ] `21cf380b` the `origin=mkdir` mount option.
- [ ] `568fd7fd` the `lxc.rootfs.bdev_type` key.
- [ ] The gold linker patch: check whether lxc main still forces gold.

### Pantavisor-specific: needs a rework first

- [ ] `897b2c54` `set_container_type()` API. Hardcodes Pantavisor's
      container type; make it generic or move the logic into Pantavisor.
- [ ] `38180347` `realpath_x()`, following symlinks in mount targets inside
      the rootfs. Stock lxc refuses them on purpose (CVE-2015-1335): put it
      behind a config key and have it reviewed for safety.
- [ ] `afa148a5` cgroup prefix `lxc.payload.` -> `lxc/` for everyone. Try
      `lxc.cgroup.dir` from Pantavisor (section 2) and drop the patch.
- [ ] `76489961` overlay upper/work dirs outside the container dir: put it
      behind a config key.
- [ ] `d99a550c` `/exports` mounts: make it a config key that lists the
      paths, or move it into Pantavisor.

### Dropped, nothing to do

`0f491096` `pv_export.h` (nothing uses it once Pantavisor drops the
include, section 2) and `c2017d42` (rebase notes).

### Validation

- [ ] Run the QEMU tests on LXC 6 for every container feature
      Pantavisor uses: `origin=mkdir`, configoverlay, `/exports`, the
      `mdev` hook, `lxc.tty.min`, cgroup v1 (`PV_SYSTEM_CGROUP_VERSION=1`)
      as well as v2.
- [x] Drop the LXC 3 series from `upstream/ptxdist/`.
- [ ] Drop `lxc-pv` once nobody needs the deprecated choice.

## 4. libevent: the case for 2.2

The RFC proposes what meta-pantavisor does: libevent 2.2 replaces 2.1
for the whole image (its recipe is `libevent_2.2.1.bb`, which overrides
OE-core's), built with mbed TLS. In PTXdist that means a version bump of
the `libevent` package, not a second libevent package: both would
install the same headers.

Why 2.2:

- Pantavisor talks to Pantahub over HTTPS through evhttp on an mbed TLS
  bufferevent (`bufferevent_mbedtls_dyncontext_new()`, `libevent_mbedtls`).
  That backend exists only in 2.2; 2.1 has OpenSSL only. Everything else
  Pantavisor uses (evhttp client and server) is in 2.1 too.
- mbed TLS rather than OpenSSL: presumably for size, as Pantavisor runs
  from the initramfs. Confirm with the Pantavisor team before writing it
  in the cover letter.
- 2.2 is what Pantavisor devices run: every meta-pantavisor build uses
  it, with the patches below.

What upstream will object to, and the answers:

- **"It is an alpha."** 2.2 is the development series libevent releases
  from: 2.2.1-alpha (2023-05), 2.2.2-alpha (2026-07), master active (11
  commits after 2.2.2-alpha). There is no 2.2 stable to wait for, and 2.1
  gets no new features. 2.2.2-alpha adds mbed TLS 3 and 4 support
  (`7cfffeaa`), which the mbed TLS 2.28 EOL question needs anyway.
- **"It changes libevent for everyone."** The soname changes
  (`libevent-2.1.so.7` -> `libevent-2.2.so.1`), so the 7 packages that
  select `LIBEVENT` rebuild: json-dbus-bridge, libcamera, lldpd,
  libwebsockets, ntp, nfsutils, tmux. The 2.1 API is kept. Build all 7
  against it before sending and list the result in the patch.
- **"Patches on an alpha."** Each one is small and goes to libevent
  first (below).

To do:

- [ ] Write the PTXdist patch: `libevent` 2.1.13 -> 2.2.2-alpha, with a
      `LIBEVENT_MBEDTLS` option next to `LIBEVENT_OPENSSL`. Propose
      2.2.2-alpha, not meta's 2.2.1-alpha: all three patches apply to it
      unchanged.
- [ ] Build the 7 consumers against it.
- [ ] Move `libevent-pv` (and meta-pantavisor) to 2.2.2-alpha too, so
      the RFC proposes what devices run.
- [ ] Send the patches to libevent:
  - [ ] `evhttp-null-guard-freed-conn`: a crash fix for evhttp on TLS
        bufferevents. Has a placeholder author (`Pantacor
        <dev@pantacor.com>`); find the real one.
  - [ ] `pkg-config-drop-cmake-debug-postfix`: master's `.pc.in` files
        still have `@CMAKE_DEBUG_POSTFIX@` (checked at d82464a2).
  - [ ] `undef_ssl_renegotiation`: turns off renegotiation in the mbed TLS
        bufferevent. Libevent's own `370d9924` only touches the tests.
        Author is `OpenEmbedded <oe.patch@oe>`; find the real one and the
        reason, or drop it if it is not needed with mbed TLS 3.
- [ ] meta-pantavisor sets `ac_cv_func_epoll_pwait2=no` for kernels older
      than 5.11 (Jetson Nano 4.9). `libevent-pv` does not: decide whether
      the PTXdist rule needs it.

## 5. The RFC series: new packages

- [x] **picohttpparser**: upstream h2o/picohttpparser at 066d2b1 (what
      the Pantavisor fork is based on) plus the fork's CMake build as a
      patch; the fork has no other change.
- [ ] **libthttp**: depends on mbedtls. It downloads NSS `certdata.txt`
      as a second part to install only `LIBTHTTP_CA_CERTS`; upstream may
      prefer an option in PTXdist's ca-certificates package to install
      chosen roots to a given directory.
- [x] **pantavisor**: menu reviewed. Every option has help text, nothing
      is board-specific, the debug build is off by default (the layer's
      ptxconfig keeps it on), and `PANTAVISOR_DEVELOPER_TRUST` makes the
      developer trust store visible and optional.
- [x] For each: every CMake option pinned (`configure_helper.py` shows
      only `CMAKE_POSITION_INDEPENDENT_CODE`, kept on purpose, and
      `find_library()` results), `_LICENSE` and `_LICENSE_FILES` set,
      `git+https` URLs with PTXdist-style versions, `licensecheck` passes,
      `lint` reports nothing for them.
- [ ] Not built: `PANTAVISOR_DEVELOPER_TRUST` off.
- [ ] Decide whether **pantavisor-rootfs** (the initramfs layout) folds into
      the `pantavisor` package, so that PTXdist alone gives a bootable
      Pantavisor initramfs.

### Stays in this layer

`host-pv-*` and `pv-containers` (container exports), and `host-pvr`.
`host-pvr` downloads a prebuilt amd64 binary, which PTXdist will not take;
upstream it would need a Go source build. Also the `image-pv-*` image types,
the kernel fragments and the boot scripts. `ptxdist lint` only warns about
`pv-containers` selecting other packages' options.

## 6. Validation before sending

- [ ] Build every CI device with the migrated packages: so far only
      `qemu-arm64` (build, boot, SSH tests). Still to build: `orangepi5b`,
      `rpi4`, `qemu-x86_64`, `orangepi5`, `rpi3`.
- [ ] Boot test on real hardware (one Rockchip and one Raspberry Pi board).
- [ ] Re-run the QEMU dropbear tests after any change to the `-n` patch.
- [ ] Check the initramfs size budget: the default mbedtls config adds
      262 KB uncompressed.

## 7. Open questions for the cover letter

- Carrying Pantavisor's LXC 6 patches (section 3) that lxc upstream does
  not take: acceptable in PTXdist, or must they all land in lxc first?
- libevent 2.2 for everyone, as meta-pantavisor does (section 4).
- The dropbear `-n` patch, if dropbear upstream does not take it.
- A `pantavisor` init choice: Pantavisor is PID 1, so it could be an
  `INITMETHOD` choice, or a standalone initramfs package.
- mbed TLS 2.28 LTS is end-of-life. Should Pantavisor and libthttp move to
  mbed TLS 3.x, or to OpenSSL, before upstream depends on them?

## Smaller decisions

- [ ] The dropbear patch has today's date as its author date, not the
      original 2019 commit's.
- [ ] If the reduced mbedtls config is wanted for size, propose it as an
      option in PTXdist's mbedtls rule, not as a layer workaround.
