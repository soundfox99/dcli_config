# Vendored PKGBUILDs

`noctalia-qs` and `noctalia-shell-git` **were deleted from the AUR.** These are
the last known-good build recipes, kept here so this repo can still bootstrap a
working niri desktop. Nothing in `dcli sync` reads them — they are built by
hand, see below.

## Why they're here

Noctalia 5.0 (2026) is a ground-up rewrite: native C++/meson, no Quickshell, no
Qt. Upstream renamed `noctalia-dev/noctalia-shell` → `noctalia-dev/noctalia`,
froze the v4 line on the `legacy-v4` branch, and the two AUR packages that
built v4 were dropped. The AUR replacement, `noctalia-git` 5.0, is a different
program with a different binary (`noctalia`, not `qs`) and a different IPC
surface.

This host still runs v4, and the niri config has six call sites hardcoding the
v4 interface (`qs -c noctalia-shell ipc call ...` in `binds.kdl`,
`shell-switcher-*.kdl`, `startup.kdl`, and `theming/wallpapers`'
`apply-wallpaper.sh`). Migrating to 5.0 means rewriting all of them. Until
that's done, v4 has to be buildable from something — and the AUR is no longer
that something.

| | |
| --- | --- |
| `noctalia-qs` | Quickshell fork, pinned to the final tag `v0.0.12`. Upstream repo and release tarball still resolve; the `sha256sums` in the PKGBUILD still match. |
| `noctalia-shell-git` | The QML shell itself. Tracks upstream's frozen `legacy-v4` branch (`a48885b9` as of 2026-08-23). |

Both were copied verbatim from `~/.cache/yay/`, with one edit to
`noctalia-shell-git`: its source URL now names the renamed repo directly
instead of relying on GitHub's redirect, with a `noctalia-shell::` prefix so
the clone directory keeps the name `pkgver()`/`package()` expect.

## Rebuilding

**`noctalia-qs` must be rebuilt after every Qt 6 point release.** Quickshell
links ~59 Qt private-API symbols, which carry no ABI guarantee. Qt 6.11 moved
one of them from the `Qt_6_PRIVATE_API` version node to public `Qt_6`, and the
shell died at startup with:

```
qs: symbol lookup error: qs: undefined symbol:
    _ZN23QUntypedPropertyBindingC1EP23QPropertyBindingPrivate, version Qt_6_PRIVATE_API
```

Symptom is total: no bar, no launcher, no wallpaper, since noctalia draws all
three. `dcli sync` will not catch this — its satisfaction test is `pacman -Q`
exit status, and a broken binary is still an installed package. `dcli update
--devel` won't either: `noctalia-qs` is a fixed-version package, so there is
nothing for the AUR helper to re-resolve.

```bash
cd modules/desktop-environments/niri/pkgbuilds/noctalia-qs
makepkg -f                                  # no sudo needed to build
sudo pacman -U noctalia-qs-*.pkg.tar.zst
pkill -f 'qs -c noctalia-shell'; qs -c noctalia-shell & disown
```

Verify a build actually fixed the ABI before installing it — this should print
nothing:

```bash
ldd -r src/noctalia-qs-*/build/src/quickshell 2>&1 | grep 'undefined symbol'
```

`noctalia-shell-git` is pure QML and does not need rebuilding on Qt updates —
only to pick up new commits on `legacy-v4`.

## Removing this directory

When the 5.0 migration lands, this whole directory and the two package names in
`../module.lua` go away, replaced by `noctalia-git`.
