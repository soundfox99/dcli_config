# arch-config

Declarative Arch Linux setup managed by [dcli](https://github.com/theblackdon/dcli). Modules are Lua; hardware-conditional packages live in `modules/hardware.lua`; browser bookmarks are encrypted with git-crypt.

## Fresh-install bootstrap

Run these once on a new machine. Order matters.

```bash
# 1. System base (Arch fresh install assumed; chroot/install done)
sudo pacman -S --needed base-devel git

# 2. Bootstrap an AUR helper (yay) if missing
if ! command -v yay; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si)
fi

# 3. Install dcli
yay -S dcli-arch-git

# 4. Clone this repo to its expected path
git clone git@github.com:soundfox99/dcli_config.git ~/.config/arch-config
cd ~/.config/arch-config

# 5. Unlock encrypted files (bookmarks etc.) — needs the key from your backup
git-crypt unlock /path/to/arch-dcli-config.key

# 6. Build the two Noctalia packages the AUR no longer carries
#    (skip on a host that doesn't enable desktop-environments/niri)
for p in noctalia-qs noctalia-shell-git; do
  (cd modules/desktop-environments/niri/pkgbuilds/$p && makepkg -si)
done

# 7. Sync everything
dcli sync           # installs packages, enables services, deploys dotfiles
dcli update --devel # full system upgrade + AUR refresh
```

Open a new terminal afterward so `.bashrc` (cargo, fnm) loads.

Step 6 is not optional on a niri host: `noctalia-qs` and `noctalia-shell-git`
were deleted from the AUR, so `dcli sync` cannot install them and the desktop
comes up with no bar, no launcher and no wallpaper. See
`modules/desktop-environments/niri/pkgbuilds/README.md` — which also covers the
rebuild `noctalia-qs` needs after **every Qt 6 point release**.

## Layout

```
config.lua                    Auto-detects hostname → routes to hosts/<host>.lua
hosts/<hostname>.lua          Per-machine config: enabled_modules, services, theming
modules/
  base.lua                    Always-installed essentials
  hardware.lua                Conditional CPU/GPU/laptop packages (uses dcli.hardware.*)
  declared-packages.lua       Auto-managed by `dcli install`
  system-packages-<host>/     Auto-synced system packages (don't hand-edit)
  <category>/<name>/module.lua + dotfiles/    Feature modules
  desktop-environments/niri/pkgbuilds/        Vendored build recipes for two
                                              packages deleted from the AUR
  scripts/                    Cross-module hook scripts (multilib, fstrim, ...)
modules/browsers/data/*-bookmarks.html            git-crypt encrypted
scripts/setup-repo-encryption.sh   One-time git-crypt init
state/                        Runtime state, auto-managed by dcli
```

## Post-install hooks

A module can declare `post_install_hook = "scripts/<name>.sh"`, plus:

| Field | Meaning |
| --- | --- |
| `hook_behavior = "always"` | Runs on every `dcli sync`. Requires the script be idempotent. |
| `hook_behavior = "once"` | Runs once, then marked done. Won't retry if it failed for the wrong reason. |
| `run_hooks_as_user = true` | *Intent* only — see below. |

**`run_hooks_as_user` does not reliably drop privileges.** `dcli sync` runs under
sudo, and hooks can still land as root. Any hook that touches `$HOME` must
de-escalate itself, **before** `$HOME` is read:

```bash
if [ "${EUID}" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        exec sudo -H -u "${SUDO_USER}" --preserve-env=PATH -- "$0" "$@"
    else
        echo "refuses to run as root and SUDO_USER is unset." >&2
        exit 1
    fi
fi
```

Getting this wrong is silent: the hook succeeds, but writes into `/root`.

| Hook | Runs as | What it does |
| --- | --- | --- |
| `browsers/scripts/install-browser-policies.sh` | root | Extension auto-install policies under `/etc`. No args = all three browsers; pass names for a subset |
| `browsers/brave/scripts/install-brave-policy.sh` | root | Brave only — wrapper that calls the above with `brave` |
| `browsers/zen/scripts/install-zen-shortcuts.sh` | user | Keyboard shortcuts into every Zen profile |
| `editors/vscodium/scripts/install-vscodium-extensions.sh` | user | Extensions from `data/extensions.txt` |
| `onboarding/scripts/onboarding.sh` | user | First-run prompts; silent when already done |
| `programming-languages/nodejs/scripts/fnm-bootstrap.sh` | user | fnm + Node versions |
| `programming-languages/rust/scripts/rustup-default.sh` | user | Default rustup toolchain |
| `shell/tmux/scripts/install-tpm.sh` | user | Clones tpm to `~/.tmux/plugins/tpm` |
| `theming/wallpapers/scripts/install-wallpapers.sh` | user | Wallpaper collection into `~/Pictures`, then chains `apply-wallpaper.sh` (edit the `WALLPAPER=` line at its top to change the wallpaper on every host) |
| `wifi-rtl8821ce/scripts/tune-rtw88.sh` | root | rtw88 driver options |

Modules with more to explain than a package list carry their own README:
`browsers/zen`, `desktop-environments/niri`,
`desktop-environments/niri/pkgbuilds`, `theming/wallpapers`. Everything else is
covered by its `description` field.

## Keybindings

Per-module references, since the chords have to be picked to not collide across
three layers — the compositor grabs first, then the terminal, then the app:

| Where | Reference |
| --- | --- |
| niri (compositor) | `modules/desktop-environments/niri/README.md`, or press `Mod+Shift+/` |
| Zen Browser | `modules/browsers/zen/README.md` |
| tmux | prefix is **`Ctrl+S`**, not the default `Ctrl+B` — see below |

**tmux prefix is `Ctrl+S`.** Deliberate: the default `Ctrl+B` collides with
nvim's page-up and readline's backward-char, both used constantly. The cost is
that LazyVim's `<C-s>` **Save File** never reaches nvim inside tmux, since tmux
eats the prefix first — use `:w`. Switching back to `Ctrl+B` would trade that
for losing `<C-b>` page-up, which is worse. `Ctrl+Space` isn't a way out either;
LazyVim uses it for treesitter incremental selection.

Zen's shortcuts sit on `Ctrl+Alt+*` because niri owns `Mod` outright and grabs
those chords before any application sees them.

## Encrypted files (git-crypt)

`modules/browsers/data/*-bookmarks.html**` is encrypted via the `.gitattributes` filter. The symmetric key file (`~/arch-dcli-config.key`) is the only way to decrypt on another machine — **back it up to a password manager AND a USB**. Without it the bookmarks in the repo are unrecoverable.

### Setting up encryption on a brand-new repo

If you're starting this repo from scratch (no remote yet), follow this exact order. **Do not run `dcli repo init`** — it commits and pushes without consulting git-crypt and will leak plaintext.

```bash
git init -b main
./scripts/setup-repo-encryption.sh    # git-crypt init + export key
git add .gitattributes
git add -A
git-crypt status | grep browser       # MUST show "encrypted: ..." for every file
git commit -m "Initial arch-config"
git remote add origin git@github.com:soundfox99/dcli_config.git
git push -u origin main

# Sanity check after commit:
git show HEAD:modules/browsers/data/*-bookmarks.htmlfirefox.html | head -c 9 | xxd
# Expected output starts with: 0047 4954 4352 5950 54  (GITCRYPT magic)
```

If `git-crypt status` shows any file as `not encrypted` after staging, **stop and do not commit**. Plaintext would otherwise be permanent in history (and on the remote if pushed). Recover by wiping `.git` and starting over before any push.

### On a freshly cloned machine

```bash
git clone git@github.com:soundfox99/dcli_config.git ~/.config/arch-config
cd ~/.config/arch-config
git-crypt unlock /path/to/arch-dcli-config.key
```

## Hardware detection

`modules/hardware.lua` emits packages based on what `dcli.hardware.*` reports at sync time:

- **CPU microcode** — `amd-ucode` or `intel-ucode`
- **GPU** — `nvidia-open-dkms` (desktop) / `nvidia-dkms + nvidia-prime` (laptop), `vulkan-radeon`, `vulkan-intel`, etc.
- **CUDA** — installed only when an NVIDIA GPU is present
- **Laptop power** — `tlp`, `tlp-rdw`, `powertop`, `brightnessctl` only on laptops/battery
- **ASUS vendor** — `asusctl`, `supergfxctl`, `rog-control-center` on ASUS chassis
- **lib32-*** — installed only after `[multilib]` is enabled (auto-enabled via pre-install hook on the hardware module)

This means the same repo bootstraps an AMD desktop and an Intel laptop without any host-specific overrides.

## Adding a new host

```bash
hostname=<new-host>
cp hosts/arch-desktop.lua hosts/${hostname}.lua
# Edit enabled_modules + services for the new machine
dcli validate
dcli sync
```

`config.lua` auto-detects the hostname; just creating `hosts/<hostname>.lua` is enough.

## Desktop environments

Per host, as of now:

| Host | DE modules enabled |
| --- | --- |
| `arch-desktop` | `niri` only |
| `arch-laptop` | `kde-plasma` + `niri` |

The `hyprland` module still exists but is enabled on neither host.

**The DE modules do not conflict.** Any number of them can be enabled at once —
they install side-by-side and SDDM picks the session at login, remembering the
last one per user. Enabling a module only means "deploy this DE's packages and
dotfiles here"; it does not select the session.

To add or drop one, edit `enabled_modules` in `hosts/<host>.lua`:

```lua
enabled_modules = {
  ...
  "desktop-environments/niri",
  -- "desktop-environments/kde-plasma",   -- dropped from this host
  ...
}
```

Then `dcli sync`. Note `auto_prune = false` on both hosts, so removing a module
stops it being *declared* but does not uninstall anything already on the
machine — clear those out with `just clean` or `pacman -Rns` when you want the
disk space back.

Because `arch-desktop` runs niri alone, the niri module has to declare
everything the session needs (`qt6-wayland` for Quickshell, `polkit-kde-agent`
for auth prompts) rather than inheriting it from a heavier DE.

## Updates

```bash
dcli update --devel    # full system upgrade including AUR -git packages
```

`--devel` is required to refresh the `dcli-arch-git` package itself.
