return {
    description = "KDE Plasma 6 desktop environment",
    -- DEs coexist: SDDM picks the session at login. No conflicts declared.
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
