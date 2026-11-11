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
- [ ] **busybox: fix the `mdev -s` crash first.** `0304` (MODALIAS) segfaults
      on any PCI device without `DEVNAME` as soon as `mdev.conf` has a
      device-name rule: `make_device()` passes a NULL `device_name` to
      `regexec()`. The `FOLLOW_X_ROOT` daemon dies the same way in its initial
      scan, and `drivers.c` runs `mdev -s`. Seen on qemu-arm64 and natively;
      the series before the squash has it too. Just `continue` on NULL is not
      enough: it loops forever on the default rule, so the fix must also
      end the rule loop there.
- [ ] **busybox: add the Pantavisor patches.** Add 0300-0304 to
      PTXdist's `patches/busybox-1.38.0/series`, and put
      `FEATURE_MDEV_FOLLOW_X_ROOT` into `config/busybox/util-linux/Config.in`.
      That lets `rules/busybox-pantavisor.in` go away (a layer can only
      override all of `config/busybox`, so it lives there for now).
      Clean them up first: `0300` turns nsenter's `-F` into `F::`, so it
      takes an optional argument, and the series leaves unused variables
      (`securebits`, `m`, `ret` in nsenter, `subsys`, `res` in mdev).
- [ ] **lxc: version bump 3.0.1 -> 6.0.6.** A rewrite of PTXdist's rule
      to meson; `rules/lxc6-pv.make` has the pinned option list to start
      from. Fixes `LXC_LICENSE := unknown` too. The 3.0.4 bump in
      `upstream/ptxdist/` is obsolete with the move to LXC 6.
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
  - [ ] Merge `patches/pantavisor-031-rc8/0001-gen_version-allow-overriding-the-version-via-PV_GIT_.patch`.
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
- [ ] Drop `upstream/ptxdist/` (the LXC 3 series) once the LXC 6 series
      replaces it, and `lxc-pv` once nobody needs the deprecated choice.

## 4. libevent (blocker)

Pantavisor needs libevent 2.2's mbed TLS bufferevent backend. PTXdist has
2.1.13, and 2.2.1 is an alpha. `libevent-pv` also carries two patches
(`undef_ssl_renegotiation`, `evhttp-null-guard-freed-conn`).

- [ ] Pick a way forward and ask about it in the RFC:
  - wait for a 2.2 stable release and bump PTXdist's libevent;
  - backport the mbed TLS backend onto 2.1.13 as a patch (large);
  - move Pantavisor's libevent TLS to OpenSSL, which 2.1 supports.
- [ ] Send the libevent patches to libevent upstream. The third one (the
      `@CMAKE_DEBUG_POSTFIX@` in the autotools `.pc` files): check first
      whether libevent master has fixed it.

## 5. The RFC series: new packages

- [ ] **picohttpparser**: no dependencies.
- [ ] **libthttp**: depends on mbedtls. It downloads NSS `certdata.txt`
      as a second part to install only `LIBTHTTP_CA_CERTS`; upstream may
      prefer an option in PTXdist's ca-certificates package to install
      chosen roots to a given directory.
- [ ] **pantavisor**: depends on everything above. Review the menu
      (`rules/pantavisor.in`, `pantavisor-menu.in`) against PTXdist
      conventions: help text on every non-obvious option, no options that
      only one board needs.
- [ ] For each: pin all CMake options (PTXdist's `configure_helper.py`), set
      `_LICENSE` and `_LICENSE_FILES`, remove leftover template stages, and
      have `ptxdist lint` and `licensecheck` pass.
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
- libevent 2.2-alpha, or one of the alternatives in section 4.
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
