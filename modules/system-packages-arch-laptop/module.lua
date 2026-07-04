-- Auto-synced from the running system by `dcli merge`.
-- Hardware-conditional packages (microcode, GPU drivers, firmware) live in
-- modules/hardware.lua instead so this module stays host-portable.

return {
    description = "System packages for arch-laptop (auto-synced by dcli merge)",
    package_files = { "packages.lua" },
    hook_behavior = "ask",
}
