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
| mbedtls | Stock package, rule bumped to 2.28.10 (`rules/mbedtls.make`) | In PTXdist master (f996777be); drop with the next release |
| dropbear | Stock 2026.94 + `-n` patch; rules with `DROPBEAR_GENKEYS` (`rules/dropbear.*`) | `DROPBEAR_GENKEYS` patch sent 24 Nov 2026; the `-n` patch goes in the RFC, applied only with Pantavisor (`DROPBEAR_SERIES`) |
| busybox | Stock 1.38.0 + 6 Pantavisor patches | In the RFC, applied only with Pantavisor (`BUSYBOX_SERIES`) |
| libaio | `rules/libaio.make` backport | Already in PTXdist (5017a47); drop with the next release |
| lxc | Stock 6.0.6 (master's rule) + `series.pantavisor` (12 fork patches); `lxc-pv` (LXC 3) kept as the deprecated choice | Bump to 6.0.6 in PTXdist master (0bf3bd65e); fork patches in the RFC, see section 3 |
| libevent | `libevent22` 2.2.2-alpha, static, private sysroot prefix, coexists with libevent 2.1 | RFC: a second, static libevent package only Pantavisor links |
| picohttpparser, libthttp, pantavisor | Layer packages | The RFC itself |

## 1. Stand-alone PTXdist patches (send before the RFC)

- [x] **mbedtls: version bump 2.28.0 -> 2.28.10.** Sent 17 Nov 2026
      (`<20261117144028.34074-1-fernando.luiz@pantacor.com>`), applied
      unchanged on 21 Nov as f996777be. License now
      `Apache-2.0 OR GPL-2.0-or-later`. The meta-pantavisor pk_wrap.c
      patch is gone: Pantavisor converts ES256/384/512 signatures to DER
      itself (`patches/pantavisor-031/0003-*`), so mbedtls stays stock.
- [ ] **dropbear: make host key generation optional.** Sent 24 Nov 2026
      (`<20261124175844.453455-1-fernando.luiz@pantacor.com>`), no Cc;
      waiting for review. `upstream/ptxdist/0001-dropbear-make-host-key-generation-optional.patch`.
      Adds `DROPBEAR_GENKEYS` (default y); the postinst guard matches
      openssh's. Without it, enabling dropbear selects INITMETHOD, whose
      default is systemd. Checked with it off on v8a; the default path is
      checked by reading only. RFC 6/7 sits on top of it.
- [x] **busybox: fix the `mdev -s` crash first.** `0304` (MODALIAS) passed
      a NULL device name to `regexec()` for PCI devices without `DEVNAME`
      as soon as `mdev.conf` had a device-name rule. `0305` skips name
      rules for those devices; tested natively and on qemu-arm64.
- **busybox and dropbear `-n`: Pantavisor-only patch series.** The
      Pantavisor patches are not sent as stand-alone patches. Each package
      has two series files next to its patches: `series` (PTXdist's,
      unchanged; empty for dropbear, which has no patches upstream) and
      `series.pantavisor` (the same plus busybox 0300-0305, or dropbear
      `0200`). Hidden `BUSYBOX_SERIES` and `DROPBEAR_SERIES` symbols
      default to `series.pantavisor` if PANTAVISOR, else `series`; PTXdist
      reads `PTXCONF_<PKG>_SERIES` for every package, as it does for
      `KERNEL_SERIES`. Checked with `ptxdist extract`: with Pantavisor,
      busybox gets 0200-0203 and 0300-0305 and dropbear gets `0200`;
      without it, busybox gets 0200-0203 and dropbear nothing.
      `BUSYBOX_FEATURE_MDEV_FOLLOW_X_ROOT` now depends on PANTAVISOR. The
      RFC patches are written on PTXdist master (d6b2c7954) and apply with
      `git am`: `upstream/ptxdist/rfc/0005-busybox-*.patch` and
      `0006-dropbear-*.patch` (RFC 5/7 and 6/7). They put the series files into PTXdist's
      `patches/busybox-1.38.0/` and a new `patches/dropbear-2026.94/`, and
      the symbols into `rules/busybox.in` and `rules/dropbear.in`.
      `FOLLOW_X_ROOT` goes into `rules/busybox.in` too, not
      `config/busybox`, which mirrors stock busybox's Kconfig and is
      regenerated on every bump. Then `rules/busybox-pantavisor.in` goes. Until then the layer's
      `patches/busybox-1.38.0/` still replaces PTXdist's, so re-check it on
      every busybox bump. The series is cleaned up (`-F` is a flag again,
      `-c` is documented, nsenter links without setpriv/run-init,
      `chdir()`/`chroot()` are checked when following the root, no
      warnings beyond stock 1.38.0's, every patch builds on its own).
- [x] **lxc: version bump 3.0.1 -> 6.0.6.** Sent 17 Nov 2026
      (`<20261117143034.15388-1-fernando.luiz@pantacor.com>`, Cc Michael
      Grzeschik), applied unchanged on 21 Nov as 0bf3bd65e. Written on
      PTXdist master (4da61501e): `upstream/ptxdist/0001-lxc-version-bump-3.0.1-6.0.6.patch`.
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

- [ ] **Pantavisor** (Pantacor's repo, easy):
  - [ ] Merge `patches/pantavisor-031/0001-gen_version-allow-overriding-the-version-via-PV_GIT_.patch`.
  - [ ] Drop `#include <lxc/pv_export.h>` from `plugins/pv_lxc.c`.
        Nothing uses it, and it is the only reason lxc would need to
        install that header. Carried as
        `patches/pantavisor-031/0002-plugins-pv_lxc-drop-the-unused-pv_export.h-include.patch`
        until then.
  - [ ] Test setting `lxc.cgroup.dir` to `lxc/<name>` per container, so
        that lxc's default `lxc.payload.` prefix can stay (section 3).
- [ ] **lxc 6 fork patches**: LXC 6.0 is maintained (LTS), so send the
      generic ones in section 3 to `lxc/lxc` first, before PTXdist.

## 3. lxc: stock lxc 6.0.6 + a Pantavisor-only series

Done 24 Nov 2026: the layer no longer builds `lxc6-pv`. It carries PTXdist
master's lxc 6.0.6 rule (without `select LIBSELINUX`, which 2026.10.0
lacks) plus `LXC_SERIES`, and `patches/lxc-6.0.6/series.pantavisor`: the
fork's 14 Pantavisor commits (`bfa6810a`; its upstream base `f9ff9ea2a`
is in v6.0.6) cherry-picked onto v6.0.6, without `pv_export.h`, the
rebase notes and a `CLAUDE.md` that one commit added. Only conflict:
the rebase notes. meta-pantavisor's gold-linker patch is not needed
with 6.0.6. Pantavisor runs it with `PV_SYSTEM_CGROUP_VERSION=auto`, so
cgroup v2 on our kernels (they have `CGROUP_BPF`). LXC 3 (`lxc-pv`)
stays as the deprecated menu choice.

Differences from the fork's build: stock lxc's `localstatedir` is
`/var` (the fork used `/usr/var`), so the default lxcpath moved; the
pantavisor package now installs `/etc/lxc/lxc.conf` with
`lxc.lxcpath = /usr/var/lib/lxc`, where Pantavisor keeps its containers,
so `fallbear-cmd`'s `lxc-info`/`lxc-console` find them (SSH into a
container failed with "no container found" without it). lxc is now
built with seccomp and installs all its tools. qemu-arm64: boot, SSH
into `_pv_`, `os` and `pvr-sdk`, both containers STARTED, no lxc
errors, `lxc/` cgroup prefix, Pantahub online.

10 of the 12 patches have no Signed-off-by (Alexander Sack's); they are
copied unchanged.

### Generic: send to lxc upstream, then carry in PTXdist

- [ ] `9343fe09` block SIGCHLD in run_buffer (a fix).
- [ ] `04fe2f99` conf: match pivot_root mount propagation in lxc_chroot
      (a fix).
- [ ] `5efac56d` lxc_string_split_quoted: handle escaped characters.
- [ ] `aa2b45c3` hook commands with parameters.
- [ ] `bfa6810a` the `lxc.tty.min` key.
- [ ] `21cf380b` the `origin=mkdir` mount option.
- [ ] `568fd7fd` the `lxc.rootfs.bdev_type` key.
- [x] The gold linker patch: not needed with 6.0.6 (meson falls back).

### Pantavisor-specific

Decided 24 Nov 2026: these go into RFC 4/7 as a Pantavisor-only series
(`series.pantavisor`, `LXC_SERIES`), like busybox and dropbear, so they
no longer need a config key to be safe for other builds. The reworks
below still make them easier to argue for; `realpath_x()` has to be
flagged in the cover letter either way.


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

`0f491096` `pv_export.h` (Pantavisor uses nothing from it; the pantavisor
package drops the include, section 2) and `c2017d42` (rebase notes).

### Validation

- [ ] Run the QEMU tests on LXC 6 for every container feature
      Pantavisor uses: `origin=mkdir`, configoverlay, `/exports`, the
      `mdev` hook, `lxc.tty.min`, cgroup v1 (`PV_SYSTEM_CGROUP_VERSION=1`)
      as well as v2.
- [x] Drop the LXC 3 series from `upstream/ptxdist/`.
- [ ] Drop `lxc-pv` once nobody needs the deprecated choice.

## 4. libevent: a static 2.2 only Pantavisor links

Pantavisor talks to Pantahub over HTTPS through evhttp on an mbed TLS
bufferevent (`bufferevent_mbedtls_dyncontext_new()`, `libevent_mbedtls`).
That backend exists only in 2.2; 2.1 has OpenSSL only. Everything else
Pantavisor uses (evhttp client and server) is in 2.1 too. mbed TLS
rather than OpenSSL: presumably for size, as Pantavisor runs from the
initramfs; confirm with the Pantavisor team before writing it in the
cover letter.

meta-pantavisor replaces libevent 2.1 with 2.2 for the whole image. The
RFC proposes something smaller: PTXdist's `libevent` stays at 2.1, and a
second package builds 2.2 as static libraries in a private sysroot
prefix (`/usr/lib/libevent-2.2/{include,lib}`) with nothing installed on
the target. `pantavisor` finds it through `CMAKE_PREFIX_PATH` and an
`-I`, without source changes. That answers the objections a bump would
get: no alpha for the 7 packages that use libevent (json-dbus-bridge,
libcamera, lldpd, libwebsockets, ntp, nfsutils, tmux), no soname change,
no rebuilds. The cost is a second libevent rule to keep up to date until
2.2 has a stable release; then it goes and `libevent` is bumped. A bump
of `libevent` stays the fallback if upstream prefers one version.

Prototype in this layer (then `libevent-pv`), checked on qemu-arm64 on
24 Nov 2026:

- `pantavisor` and `pv-xconnect` need no libevent library; the initramfs
  has none. `root.cpio.gz` 8,472,503 -> 8,334,520 bytes (-138 KB),
  uncompressed -471 KB: the binaries grow by 328 KB and 262 KB, the five
  shared libraries (1.06 MB) go, three of which nothing used.
- Boot, SSH into `_pv_`, `os` and `pvr-sdk`, wrong key refused, and
  Pantavisor reaches Pantahub over TLS (online, token, device checks).
- With `LIBEVENT` and `TMUX` enabled as well, the sysroot holds 2.1.13
  in `/usr` and 2.2.1 in the private prefix; tmux links
  `libevent_core-2.1.so.7`, Pantavisor the static 2.2, and its depfiles
  show the 2.2 headers.

To do:

- [x] RFC 3/7 written (`upstream/ptxdist/rfc/0003-*`): `libevent22`,
      2.2.2-alpha, mbed TLS, static only, private prefix, PTXdist's
      license string; `configure_helper.py` shows only the intended
      directory overrides. The layer's `libevent-pv` is now the same
      `libevent22`. qemu-arm64 on 2.2.2-alpha (24 Nov 2026): boot, SSH,
      Pantahub over TLS. The `pantavisor` side goes in 7/7.
- [ ] Move meta-pantavisor to 2.2.2-alpha too, so the RFC proposes what
      devices run.
- [ ] Send the patches to libevent:
  - [ ] `evhttp-null-guard-freed-conn`: a crash fix for evhttp on TLS
        bufferevents. Written by Aníbal Portero Hermida (meta-pantavisor
        6e4b8fcb0b); the placeholder author and sign-off are replaced by
        him as author and Fernando's sign-off. Tell Aníbal, or have him
        add his own sign-off.
  - [ ] `pkg-config-drop-cmake-debug-postfix`: master's `.pc.in` files
        still have `@CMAKE_DEBUG_POSTFIX@` (checked at d82464a2).
- [x] `undef_ssl_renegotiation` dropped (24 Nov 2026): it only changes
      `bufferevent_ssl_renegotiate()`, which neither Pantavisor nor
      libthttp calls. It had no description or sign-off (added in
      meta-pantavisor de04d20297). Build and Pantahub TLS test pass
      without it.
- [ ] meta-pantavisor sets `ac_cv_func_epoll_pwait2=no` for kernels older
      than 5.11 (Jetson Nano 4.9). `libevent22` does not: decide whether
      the PTXdist rule needs it.

## 5. The RFC series

Decided 24 Nov 2026: the Pantavisor-only series covers lxc too (and
mbedtls, until 26 Nov 2026: see below); the developer trust store stays in this layer; the initramfs layout
folds into the pantavisor patch; the second libevent is `libevent22`.
Order (changed 24 Nov 2026): pantavisor comes last, so that PTXdist
builds at every commit: Pantavisor needs the lxc series. Until 7/7 the
series patches refer to a `PANTAVISOR` that does not exist yet and keep
the stock series. The pantavisor patch drops the unused
`#include <lxc/pv_export.h>` with a patch of its own.

| # | Patch | State |
|---|---|---|
| 0/7 | Cover letter | to write, last |
| 1/7 | picohttpparser: new package | written (`upstream/ptxdist/rfc/0001-*`) |
| 2/7 | libthttp: new package | written (`0002-*`); certdata.txt from ca-certificates |
| 3/7 | libevent22: new package (static, Pantavisor only) | written (`0003-*`) |
| 4/7 | lxc: Pantavisor-only patch series | written (`0004-*`) |
| 5/7 | busybox: Pantavisor-only patch series | written (`0005-*`) |
| 6/7 | dropbear: Pantavisor-only patch series | written (`0006-*`); needs the GENKEYS patch |
| 7/7 | pantavisor: new package, with the initramfs layout | written (`0007-*`) |

- [x] **mbedtls: no RFC patch (26 Nov 2026).** The meta-pantavisor
      `pk_wrap.c` patch made ECDSA verify retry a non-DER signature as
      raw R || S, for every mbedtls user, and had bugs (a `realloc()` of
      the caller's buffer, a bitwise test of negative error codes, an
      unchecked `malloc()`). Pantavisor now converts JWS ES256/384/512
      signatures (raw R || S, RFC 7518 3.4) to DER itself before
      `mbedtls_pk_verify()`: `patches/pantavisor-031/0003-*`, from
      Fernando, for Pantavisor upstream too. A raw signature is exactly
      twice the curve size and DER is always longer, so DER and RSA pass
      through. Host test against stock 2.28.10: raw P-256/384/521 verify
      (50 signatures each), DER and RSA unchanged, stock mbedtls alone
      rejects raw (-0x4fe2), flipping any signature byte is rejected.
- [ ] Test an ES256-signed revision on a device.
- [ ] Send `0003-signature-*` to Pantavisor upstream.

- [x] **picohttpparser**: upstream h2o/picohttpparser at 066d2b1 (what
      the Pantavisor fork is based on). Upstream has no build system for
      the library, so the rule compiles `picohttpparser.c` into a static,
      PIC `libpicohttpparser.a` itself (`-O2 -DNDEBUG`, as the fork's
      CMake release build did), instead of carrying that CMake build as a
      patch. Built in Docker, qemu-arm64 boots and reaches Pantahub.
      Later, Pantavisor could compile picohttpparser.c itself, as
      upstream's README suggests, and the package would go.
- [ ] **libthttp**: depends on mbedtls. It downloads NSS `certdata.txt`
      as a second part to install only `LIBTHTTP_CA_CERTS`; upstream may
      prefer an option in PTXdist's ca-certificates package to install
      chosen roots to a given directory. Its certdata.txt part now reuses
      ca-certificates' (version, URL, checksum and certdata2pem.py), as
      cross-llvm reuses llvm's sources, so the NSS version is pinned once.
- [ ] **libevent22**: 2.2.2-alpha, PTXdist's license string
      (`BSD-3-Clause AND 0BSD AND MIT`) and the 2.2 `LICENSE` checksum.
- [x] **pantavisor**: menu reviewed. Every option has help text, nothing
      is board-specific, and the debug build is off by default (the
      layer's ptxconfig keeps it on).
- [x] **pantavisor in the RFC (7/7, 26 Nov 2026)**: `SECTION=applications`
      (next to rauc; `initmethod` is only shown with `INITMETHOD` on),
      selects `LXC` and `LIBEVENT22`, no LXC 3 choice (cgroup version
      `auto`), the initramfs layout folded in (`depends on !ROOTFS_MEDIA`,
      since `/media` is a link), `PANTAVISOR_PVS_SKIP_INSTALL=ON` instead of
      `PANTAVISOR_DEVELOPER_TRUST`, and the three Pantavisor patches. The
      debug help says the SSH server needs `DROPBEAR` with `GENKEYS` off;
      selecting `DROPBEAR` would pull in `INITMETHOD` while `GENKEYS`
      defaults to y. All 7 patches apply with `git am` on master
      `d6b2c7954` plus GENKEYS.
- [x] The layer folds `pantavisor-rootfs` into `pantavisor` the same way;
      its rule is now the RFC's plus the layer-only parts: the
      `pantavisor` menu, `PANTAVISOR_DEVELOPER_TRUST` and the LXC 3 choice.
      qemu-arm64: boot, SSH into all three, containers READY, signature OK,
      Pantahub online; lint shows only the 3 known warnings.
- [x] For each: every CMake option pinned (`configure_helper.py` shows
      only `CMAKE_POSITION_INDEPENDENT_CODE`, kept on purpose, and
      `find_library()` results), `_LICENSE` and `_LICENSE_FILES` set,
      `git+https` URLs with PTXdist-style versions, `licensecheck` passes,
      `lint` reports nothing for them.

### Stays in this layer

`host-pv-*` and `pv-containers` (container exports), `host-pvr`, and the
developer trust store (`host-pv-developer-ca`, `PANTAVISOR_DEVELOPER_TRUST`).
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

- A second, static libevent 2.2 that only Pantavisor links, until 2.2
  has a stable release; or bump `libevent` for everyone, as
  meta-pantavisor does (section 4).
- A `pantavisor` init choice: Pantavisor is PID 1, so it could be an
  `INITMETHOD` choice, or a standalone initramfs package.
- mbed TLS 2.28 LTS is end-of-life. Should Pantavisor and libthttp move to
  mbed TLS 3.x, or to OpenSSL, before upstream depends on them?
- Pantavisor-only patch series for lxc, busybox and dropbear
  (`series.pantavisor`, chosen by `<PKG>_SERIES`): nobody else's build
  changes, but whoever bumps those packages has to rebase them.
  Acceptable, or should they stay in a layer? `realpath_x()` in the lxc
  series follows symlinks stock lxc refuses (CVE-2015-1335).

## Smaller decisions

- [ ] The dropbear patch has today's date as its author date, not the
      original 2019 commit's.
- [ ] If the reduced mbedtls config is wanted for size, propose it as an
      option in PTXdist's mbedtls rule, not as a layer workaround.
