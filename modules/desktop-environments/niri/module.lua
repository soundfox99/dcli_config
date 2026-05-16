return {
    description = "Niri scrollable-tiling Wayland compositor with defaults",
    -- DEs coexist: SDDM picks the session at login. No conflicts declared.
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
        -- noctalia-shell-git depends on its own Quickshell fork (noctalia-qs),
        -- which provides the `quickshell` binary. Don't also declare quickshell-git
        -- here — they conflict at package-install time.
        "noctalia-shell-git",
    },
}
