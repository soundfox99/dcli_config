# Command runner for arch-config. Run `just` (no args) to see all targets.
#
# Most of these wrap scripts/ and the dcli CLI. The bash aliases in
# modules/shell/bash/dotfiles/.bashrc (dcli-pull / dcli-push / dcli-full)
# do similar things — use whichever feels better.

set shell := ["bash", "-cu"]
set positional-arguments

# Default target: list available recipes
_default:
    @just --list --unsorted

# ─── Lifecycle ─────────────────────────────────────────────────────────────

# Pull latest config from the remote (rebase, autostash work in progress)
pull:
    git pull --rebase --autostash

# Apply the repo to the system (install pkgs, deploy dotfiles, enable services)
sync *FLAGS:
    dcli sync {{FLAGS}}

# Preview what `dcli sync` would change without applying it
dry-run:
    dcli sync --dry-run

# Validate the repo's structure + Lua modules
validate:
    dcli validate

# Show installed-vs-declared status
status:
    dcli status

# Full system upgrade through dcli (pacman -Syu + AUR rebuild)
update:
    dcli update --devel

# Update dcli itself via its AUR `-git` package
self-update:
    yay -S --noconfirm dcli-arch-git

# ─── Snapshot back to repo + commit + push ─────────────────────────────────

# Snapshot system state (bookmarks, extensions) back into data files
snapshot:
    ./scripts/snapshot-system-state.sh

# Snapshot, then commit + push (refuses if any sensitive file is plaintext)
push: snapshot
    ./scripts/safe-commit-push.sh

# The full loop: pull → update (pacman + AUR -git) → sync → snapshot → safe push
full: pull
    dcli update --devel
    dcli sync
    just push

# ─── Theming ───────────────────────────────────────────────────────────────

# Switch the system-wide theme (tokyonight / mocha). No arg = re-apply active.
theme name="":
    ./scripts/switch-theme.sh {{name}}

# Convenience: jump straight to a named theme
mocha:        (theme "mocha")
tokyonight:   (theme "tokyonight")

# ─── Browser bookmark import (Chromium / Brave) ────────────────────────────

# Auto-import (safe: only writes if target profile is empty)
import-bookmarks:
    ./modules/browsers/scripts/import-browser-bookmarks.sh

# Force overwrite browser bookmarks with what's in the repo
import-bookmarks-force:
    ./modules/browsers/scripts/import-browser-bookmarks.sh --force

# ─── git-crypt ─────────────────────────────────────────────────────────────

# One-time: init git-crypt + export key (for fresh clones)
encrypt-init:
    ./scripts/setup-repo-encryption.sh

# Unlock the repo on a new machine (key path defaults to ~/arch-dcli-config.key)
encrypt-unlock keyfile="~/arch-dcli-config.key":
    git-crypt unlock {{keyfile}}

# Show which files git-crypt currently has encrypted
encrypt-status:
    git-crypt status | grep -E '^\s*encrypted:' || echo "(nothing encrypted)"

# ─── Niri / Hyprland helpers ───────────────────────────────────────────────

# Reload niri config without re-login (when running in niri)
niri-reload:
    niri msg action reload-config

# Reload hyprland config without re-login (when running in hyprland)
hyprland-reload:
    hyprctl reload

# Reload waybar
waybar-reload:
    pkill -SIGUSR2 waybar

# ─── Cleanup ───────────────────────────────────────────────────────────────

# Drop orphaned packages and clear the pacman cache (interactive)
clean:
    sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || echo "no orphans"
    sudo paccache -ruk0
