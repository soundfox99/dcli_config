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

# 6. Sync everything
dcli sync           # installs packages, enables services, deploys dotfiles
dcli update --devel # full system upgrade + AUR refresh
```

Open a new terminal afterward so `.bashrc` (cargo, fnm) loads.

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
  scripts/                    Cross-module hook scripts (multilib, fstrim, ...)
modules/browsers/data/*-bookmarks.html            git-crypt encrypted
scripts/setup-repo-encryption.sh   One-time git-crypt init
state/                        Runtime state, auto-managed by dcli
```

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

## Switching desktop environments

KDE Plasma is active by default. Niri and Hyprland modules are present but commented out in the host file. To switch:

```lua
-- in hosts/<host>.lua
enabled_modules = {
  ...
  -- "desktop-environments/kde-plasma",
  "desktop-environments/niri",         -- or hyprland
  ...
}
```

Then `dcli sync` and log out / pick the session from SDDM. The three DE modules conflict via `conflicts = {...}` so only one is ever active.

## Updates

```bash
dcli update --devel    # full system upgrade including AUR -git packages
```

`--devel` is required to refresh the `dcli-arch-git` package itself.
