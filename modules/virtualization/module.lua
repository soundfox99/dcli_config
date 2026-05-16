return {
    description = "Full-system virtualization: QEMU/KVM (via libvirt + virt-manager) and VirtualBox",
    packages = {
        -- QEMU / KVM stack via libvirt
        "qemu-full",         -- all emulators + SPICE + GTK frontend
        "libvirt",           -- management daemon + API
        "virt-manager",      -- GUI for libvirt
        "virt-viewer",       -- SPICE client
        "dnsmasq",           -- default NAT network
        "edk2-ovmf",         -- UEFI firmware for guests
        "swtpm",             -- software TPM (Windows 11 guests etc.)
        "dmidecode",         -- host info passthrough
        "openbsd-netcat",    -- libvirt SSH transport helper

        -- VirtualBox (kept alongside)
        "virtualbox",
    },
}
