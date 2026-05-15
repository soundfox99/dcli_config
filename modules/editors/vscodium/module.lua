return {
    description = "VSCodium — telemetry-free VS Code build, with extensions",
    packages = { "vscodium" },
    post_install_hook = "scripts/install-vscodium-extensions.sh",
    hook_behavior = "always",
    run_hooks_as_user = true,
}
