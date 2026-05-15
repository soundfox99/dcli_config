return {
    description = "Web browsers with extension policies deployed for first-launch auto-install",
    packages = {
        "firefox",
        "chromium",
        "brave-bin",
    },
    post_install_hook = "scripts/install-browser-policies.sh",
    hook_behavior = "always",
    run_hooks_as_user = false,
}
