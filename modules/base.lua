-- Base packages installed on every system regardless of host or modules.
-- Microcode/firmware are not here — see modules/hardware.lua.

return {
    description = "Base system packages",
    post_install_hook = "scripts/enable-fstrim-timer.sh",
    hook_behavior = "always",
    run_hooks_as_user = false,
    packages = {
        -- Essential base system
        "base",
        "base-devel",

        -- Basic tools
        "git",
        "nano",
        "htop",
        "man-db",
        "man-pages",
        -- Every host enables the NetworkManager service, so declare the
        -- package that provides it. iwd/dhcpcd stay as fallback backends.
        "networkmanager",
        "iwd",
        "dhcpcd",
        "neofetch",

        -- Netfilter userspace (nftables backend)
        "iptables-nft",

        -- dcli dependencies
        "paru",
        "fzf",
        "timeshift",
    },
}
