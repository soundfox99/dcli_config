return {
    description = "KDE Plasma 6 desktop environment",
    conflicts = {
        "desktop-environments/niri",
        "desktop-environments/hyprland",
    },
    packages = {
        "plasma-meta",
        "plasma-workspace",
        "sddm",
        "dolphin",
        "konsole",
        "kate",
        "ark",
        "kde-cli-tools",
        "polkit-kde-agent",
        "system-config-printer",
    },
}
