-- Packages installed manually on the system (auto-synced by dcli).
-- intel-ucode, vulkan-intel, intel-media-driver, linux-firmware and the laptop
-- power tooling are emitted by modules/hardware.lua and intentionally absent
-- here. KDE Plasma packages live in modules/desktop-environments/kde-plasma.
--
-- Deliberately NOT declared, though installed: xf86-video-amdgpu, xf86-video-ati,
-- xf86-video-nouveau, vulkan-radeon, vulkan-nouveau (archinstall leftovers — this
-- machine is Intel-only), xorg-server/xorg-xinit, and power-profiles-daemon
-- (conflicts with the tlp that hardware.lua enables). Safe to `pacman -Rns` later.

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
        "xdg-utils",
        "yay",
        "yay-debug",
        "zram-generator",
    },
}
