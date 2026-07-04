-- Packages installed manually on the system (auto-synced by dcli).
-- amd-ucode, nvidia-open-dkms, libva-nvidia-driver, linux/linux-firmware are
-- handled by modules/hardware.lua and intentionally absent here.
--
-- Laptop starter list: desktop base minus KDE/X11 stuff (niri is Wayland-only),
-- plus laptop power / brightness essentials. Run `dcli merge` on the actual
-- laptop after first install to sync in whatever else lives on the system.

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
        "xdg-utils",
        "yay",
        "yay-debug",
        "zram-generator",
    },
}
