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

        -- Netfilter userspace (nftables backend). The package is named
        -- "iptables"; "iptables-nft" is only a provides/replaces alias, and
        -- dcli doesn't resolve provides — declaring the alias made every
        -- sync report it as missing forever.
        "iptables",

        -- dcli dependencies
        "paru",
        "fzf",
        "timeshift",
    },
}
