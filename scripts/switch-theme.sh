#!/usr/bin/env bash
# Switch the system-wide theme between supported palettes.
# Idempotent: re-running with the same theme is a no-op.
#
# Usage:  switch-theme.sh <name>
#         switch-theme.sh           # apply the theme recorded in active-theme.txt
#
# Supported names live in modules/theming/active-theme.txt (one of: tokyonight, mocha).
#
# Touches:
#   - modules/theming/active-theme.txt              (records the choice)
#   - modules/terminals/kitty/dotfiles/kitty/current-theme.conf   (copy of themes/<name>.conf)
#   - modules/shell/starship/dotfiles/starship.toml (palette = '...' line)
#   - modules/shell/tmux/dotfiles/tmux/current-theme.conf         (copy of themes/<name>.conf)
#   - gsettings org.gnome.desktop.interface gtk-theme (if the GTK theme is installed)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ACTIVE_FILE="${REPO_ROOT}/modules/theming/active-theme.txt"

usage() { sed -n '2,15p' "$0"; exit 1; }

THEME="${1:-}"
if [ -z "${THEME}" ]; then
    [ -f "${ACTIVE_FILE}" ] || { echo "no active theme recorded and none given" >&2; usage; }
    THEME=$(tr -d '[:space:]' < "${ACTIVE_FILE}")
fi

case "${THEME}" in
    tokyonight|mocha) ;;
    *)
        echo "Unknown theme: '${THEME}' (supported: tokyonight, mocha)" >&2
        exit 2 ;;
esac

# Per-theme: starship palette name + GTK theme name (must match installed pkg)
case "${THEME}" in
    tokyonight)
        STARSHIP_PALETTE="tokyo_night"
        GTK_THEME="Tokyonight-Dark"
        ;;
    mocha)
        STARSHIP_PALETTE="catppuccin_mocha"
        GTK_THEME="Catppuccin-Mocha-Standard-Mauve-Dark"
        ;;
esac

echo "Switching to: ${THEME}"

# 1. Record the active theme
echo "${THEME}" > "${ACTIVE_FILE}"

# 2. Kitty — copy themes/<name>.conf to current-theme.conf
KITTY_DIR="${REPO_ROOT}/modules/terminals/kitty/dotfiles/kitty"
if [ -f "${KITTY_DIR}/themes/${THEME}.conf" ]; then
    cp "${KITTY_DIR}/themes/${THEME}.conf" "${KITTY_DIR}/current-theme.conf"
    echo "  kitty: themes/${THEME}.conf -> current-theme.conf"
fi

# 3. Starship — flip the palette line
STARSHIP_TOML="${REPO_ROOT}/modules/shell/starship/dotfiles/starship.toml"
if [ -f "${STARSHIP_TOML}" ]; then
    sed -i -E "s/^palette = .*/palette = '${STARSHIP_PALETTE}'/" "${STARSHIP_TOML}"
    echo "  starship: palette = '${STARSHIP_PALETTE}'"
fi

# 4. Hyprland palette (sourced by hyprland.conf when the WM is active)
HYPR_DIR="${REPO_ROOT}/modules/desktop-environments/hyprland/dotfiles/hypr"
if [ -f "${HYPR_DIR}/themes/${THEME}.conf" ]; then
    cp "${HYPR_DIR}/themes/${THEME}.conf" "${HYPR_DIR}/current-theme.conf"
    echo "  hyprland: themes/${THEME}.conf -> current-theme.conf"
fi

# 5. Waybar palette
WAYBAR_DIR="${REPO_ROOT}/modules/desktop-environments/hyprland/dotfiles/waybar"
if [ -f "${WAYBAR_DIR}/themes/${THEME}.css" ]; then
    cp "${WAYBAR_DIR}/themes/${THEME}.css" "${WAYBAR_DIR}/current-theme.css"
    echo "  waybar: themes/${THEME}.css -> current-theme.css"
fi

# 5b. Niri layout palette (sourced AFTER noctalia.kdl so it wins for borders)
NIRI_DIR="${REPO_ROOT}/modules/desktop-environments/niri/dotfiles/niri"
if [ -f "${NIRI_DIR}/themes/${THEME}.kdl" ]; then
    cp "${NIRI_DIR}/themes/${THEME}.kdl" "${NIRI_DIR}/current-theme.kdl"
    echo "  niri: themes/${THEME}.kdl -> current-theme.kdl"
fi

# 5c. tmux palette (declares the theme plugin too, so tpm needs prefix + I after a switch)
TMUX_DIR="${REPO_ROOT}/modules/shell/tmux/dotfiles/tmux"
if [ -f "${TMUX_DIR}/themes/${THEME}.conf" ]; then
    cp "${TMUX_DIR}/themes/${THEME}.conf" "${TMUX_DIR}/current-theme.conf"
    echo "  tmux: themes/${THEME}.conf -> current-theme.conf"
fi

# 6. GTK / cursor — gsettings; skip silently if running headless or theme not installed
if command -v gsettings >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    if gsettings list-recursively org.gnome.desktop.interface >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME}" 2>/dev/null \
            && echo "  gsettings: gtk-theme = ${GTK_THEME}" \
            || echo "  gsettings: failed to set gtk-theme to ${GTK_THEME} (theme installed? try 'pacman -Q tokyonight-gtk-theme-git')"
    fi
fi

echo "Done. Reload running apps to see the change:"
echo "  kitty:    Ctrl+Shift+F5  (or restart)"
echo "  bash:     start a new shell  (starship reads at startup)"
echo "  hyprland: hyprctl reload    (if running)"
echo "  waybar:   pkill -SIGUSR2 waybar   (if running)"
echo "  niri:     niri msg action reload-config   (if running)"
echo "  tmux:     prefix + I to fetch the new theme plugin, then prefix + r"
echo "  GTK apps: log out + back in for full effect"
