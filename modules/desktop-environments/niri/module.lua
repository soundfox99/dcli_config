return {
    description = "Niri scrollable-tiling Wayland compositor with defaults",
    -- DEs coexist: SDDM picks the session at login. No conflicts declared.
    -- This is the only DE arch-desktop enables, so anything the session needs
    -- has to be declared here — it can no longer be inherited from the
    -- kde-plasma / hyprland modules.
    dotfiles_sync = true,
    packages = {
        "niri",
        "xwayland-satellite",
        "xdg-desktop-portal-gnome",
        -- Quickshell (noctalia) is a Qt6 Wayland client and won't start
        -- without the platform plugin. Previously pulled in by hyprland.
        "qt6-wayland",
        -- Authentication dialogs. Previously pulled in by kde-plasma and
        -- hyprland; works fine outside KDE. Spawned from
        -- dotfiles/niri/startup.kdl.
        "polkit-kde-agent",
        "wl-clipboard",
        "wl-clip-persist",
        "cliphist",
        "brightnessctl",
        "playerctl",     -- media keys shell out to this
        -- File manager for the Mod+F bind in dotfiles/niri/binds.kdl. Was only
        -- present as a transitive dep of xdg-desktop-portal-gnome, so the bind
        -- silently depended on a package nothing declared. Declared explicitly
        -- here since this module owns the bind.
        "nautilus",
        -- gvfs alone has no MTP backend, so Nautilus cannot see MTP devices
        -- (phones, e-readers, the Supernote). Dolphin is unaffected — it reaches
        -- MTP through kio-extras, a separate stack.
        "gvfs-mtp",
        -- fuzzel dropped: noctalia provides the launcher.
        "sway-audio-idle-inhibit-git",
        "swayidle",
        -- noctalia-shell-git depends on its own Quickshell fork (noctalia-qs),
        -- which provides the `quickshell` binary. Don't also declare quickshell-git
        -- here — they conflict at package-install time.
        --
        -- BOTH WERE DELETED FROM THE AUR. dcli cannot install this on a fresh
        -- machine; build it from the vendored recipes in pkgbuilds/ first, then
        -- sync. noctalia-qs also needs a manual rebuild after every Qt 6 point
        -- release. pkgbuilds/README.md explains both.
        "noctalia-shell-git",
    },
}
