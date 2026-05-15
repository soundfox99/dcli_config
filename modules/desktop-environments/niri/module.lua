return {
    description = "Niri scrollable-tiling Wayland compositor with defaults",
    conflicts = {
        "desktop-environments/hyprland",
        "desktop-environments/kde-plasma",
    },
    dotfiles_sync = true,
    packages = {
        "niri",
        "xwayland-satellite",
        "xdg-desktop-portal-gnome",
        "wl-clipboard",
        "wl-clip-persist",
        "cliphist",
        "brightnessctl",
        "fuzzel",
        "sway-audio-idle-inhibit-git",
        "swayidle",
        "quickshell-git",
        "noctalia-shell-git",
    },
}
