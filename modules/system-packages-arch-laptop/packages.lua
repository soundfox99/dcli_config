-- Packages installed manually on the system (auto-synced by dcli).
-- intel-ucode, vulkan-intel, intel-media-driver, linux-firmware and the laptop
-- power tooling are emitted by modules/hardware.lua and intentionally absent
-- here. KDE Plasma packages live in modules/desktop-environments/kde-plasma.
--
-- xorg-server is declared below because sddm hard-depends on it — do not
-- remove it as an "X11 leftover". xorg-xinit (startx) is a real leftover and
-- is not declared: sessions start from SDDM.
--
-- Deliberately NOT declared, and safe to `pacman -Rns`: xf86-video-amdgpu,
-- xf86-video-ati, xf86-video-nouveau, vulkan-radeon, vulkan-nouveau
-- (archinstall leftovers — this machine is Intel-only), xorg-xinit, and
-- power-profiles-daemon (tlp, enabled by hardware.lua, is the power tool here).

return {
    description = "Packages installed manually on the system (auto-synced by dcli)",
    packages = {
        "acpid",
        "bluez",
        "bluez-utils",
        "brightnessctl",
        "btrfs-progs",
        "cups",
        "cups-pk-helper",
        "dcli-arch-git",
        "dhcpcd",
        "dkms",
        "dolphin",
        "efibootmgr",
        "git",
        "gst-plugin-pipewire",
        "htop",
        "iwd",
        "libpulse",
        "linux",
        "linux-headers",
        "nano",
        "network-manager-applet",
        "openssh",
        "pipewire",
        "pipewire-alsa",
        "pipewire-jack",
        "pipewire-pulse",
        "powertop",
        "sddm",
        "smartmontools",
        "sudo",
        "system-config-printer",
        "tlp",
        "tlp-rdw",
        "upower",
        "vim",
        "wget",
        "wireless_tools",
        "wireplumber",
        "wpa_supplicant",
        "xorg-server", -- hard dependency of sddm
        "xdg-utils",
        "yay",
        "yay-debug",
        "zram-generator",
    },
}
