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
| busybox | Stock 1.38.0 + 11 Pantavisor patches | PTXdist patch to write |
| libaio | `rules/libaio.make` backport | Already in PTXdist (5017a47); drop with the next release |
| lxc | Still `lxc-pv` | Bump ready in `upstream/ptxdist/`; 15 of 41 fork commits ready |
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
- [ ] **busybox: add the Pantavisor patches.** Add 0300-0310 to
      PTXdist's `patches/busybox-1.38.0/series`, and put
      `FEATURE_MDEV_FOLLOW_X_ROOT` into `config/busybox/util-linux/Config.in`.
      That lets `rules/busybox-pantavisor.in` go away (a layer can only
      override all of `config/busybox`, so it lives there for now).
- [ ] **lxc: version bump 3.0.1 -> 3.0.4.** Ready:
      `upstream/ptxdist/0001-lxc-version-bump-3.0.1-3.0.4.patch`. Also fixes
      `LXC_LICENSE := unknown`.
- [ ] Before sending each one, rebase it on current PTXdist master and run
      `ptxdist lint` and `ptxdist licensecheck <pkg>`.

## 2. Upstream projects first

PTXdist prefers patches that the upstream project has accepted or at
least reviewed. Where that is possible, send them there first:

- [ ] **dropbear `-n` any-user mode** (`patches/dropbear-2026.94/0200-*`):
      offer it to dropbear upstream (Matt Johnston). If it is refused,
      the RFC has to argue for carrying it in PTXdist.
- [ ] **busybox patches**, mostly generic: nsenter/unshare `-C`, nsenter
      `--caps`, the netlink and MODALIAS fixes. Send them to the busybox
      list; `FOLLOW_X_ROOT`/`FOLLOW_X_PID` and wget `unix_proxy` are more
      Pantavisor-specific.
- [ ] **Pantavisor** (Pantacor's repo, easy):
  - [ ] Merge `patches/pantavisor-030/0001-gen_version-allow-overriding-the-version-via-PV_GIT_.patch`.
  - [ ] Drop `#include <lxc/pv_export.h>` from `plugins/pv_lxc.c`.
        Nothing uses it, and it is the only reason lxc would need to
        install that header.
  - [ ] Test setting `lxc.cgroup.dir` to `lxc/<name>` per container, so
        that lxc's default `lxc.payload.` prefix can stay (see 3.D).
- [ ] lxc 3.0 has been end-of-life since 2023, so there is nowhere upstream
      to send the lxc fork patches. PTXdist carrying them is the only route.

## 3. lxc: replace lxc-pv with stock lxc + patches

### Ready (B and C)

`upstream/ptxdist/patches/lxc-3.0.4/`, 15 patches. They build with GCC 15
and no warnings, and everything `pv_lxc.c` uses is present. Not yet run
under Pantavisor.

- [ ] Fold the series into a PTXdist patch, after the 3.0.4 bump.
- [ ] Decide on `0002` (no `container=` for `pv-root`). It hardcodes a
      Pantavisor name in lxc; an empty type meaning "do not set it" would
      be generic, but then Pantavisor has to pass `""`.
- [ ] Decide on `0011`. It makes `LXC_LOG_BUFFER_SIZE` 8x bigger
      (4096 -> 32768) for every user; it could be smaller, or configurable.
- [ ] Squash `0003`, `0005` and `0006` (init.cmd parsing) into one patch,
      if the authors agree to a co-authored commit.

### Still to do (D): behaviour changes for every lxc user

Each one needs a config key that is off by default, or a rework in
Pantavisor, before upstream will take it.

- [ ] **Following symlinks in mount targets**: `b03b9cde` `e66bd42c`
      `4acd66a1` `78c77294` `bf4be7b0` `7aa1ad8a` `ab09a6a5` (realpath_x).
      Stock lxc refuses symlinks in mount targets on purpose
      (CVE-2015-1335). Put it behind a key such as
      `lxc.mount.resolve_symlinks`, squash the series, and have it reviewed
      for safety.
- [ ] **`/exports`**: `da3d6e46` skips the umount of, and keeps shared, any
      mount whose target contains the string `exports`. Make it a config
      key that lists the paths, or move it into Pantavisor.
- [ ] **cgroup prefix**: `ea36bada` changes `lxc.payload.` to `lxc/` for
      everyone. Pantavisor's `cgroup.c` expects `lxc/<name>`. Try
      `lxc.cgroup.dir` from Pantavisor (section 2) and drop the patch.
- [ ] **overlay upper/work dirs**: `937c195c` drops the check that they are
      inside the lxc path, so lxc will `mkdir -p` them anywhere on the host.
      Put it behind a config key.
- [ ] Then switch the layer from `lxc-pv` to stock `lxc` (with
      `LXC_SYSTEMD_UNIT` off) and run the QEMU tests: containers start,
      `fallbear-cmd` reaches them, `origin=mkdir` and configoverlay work.

### Dropped, nothing to do

`atom.mk`, CI, and `COPYING` churn; the ptmx add/revert; the static
archive; `set_inherit_namespaces()` (unused). Also `setpgrp()` (reverted
later in the fork), `ad43e43f` (fixes code that is not in 3.0.4), and
`9113e476` (folded into the origin=mkdir port).

## 4. libevent (blocker)

Pantavisor needs libevent 2.2's mbed TLS bufferevent backend. PTXdist has
2.1.13, and 2.2.1 is an alpha. `libevent-pv` also carries two patches
(`undef_ssl_renegotiation`, `evhttp-null-guard-freed-conn`).

- [ ] Pick a way forward and ask about it in the RFC:
  - wait for a 2.2 stable release and bump PTXdist's libevent;
  - backport the mbed TLS backend onto 2.1.13 as a patch (large);
  - move Pantavisor's libevent TLS to OpenSSL, which 2.1 supports.
- [ ] Send the two libevent patches to libevent upstream.

## 5. The RFC series: new packages

- [ ] **picohttpparser**: no dependencies.
- [ ] **libthttp**: depends on mbedtls.
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

- Carrying 15+ patches against lxc 3.0 (EOL). Acceptable, or must
  Pantavisor move to a maintained lxc first?
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
