-- Brave on its own. Kept separate from browsers/module (firefox + chromium +
-- brave) so a host can take just this one instead of pulling in three.
--
-- Extension IDs come from the same modules/browsers/data/brave-extensions.txt
-- the full module uses, so a host running this and a host running
-- browsers/module force-install the identical set.

return {
    description = "Brave browser with extension policies deployed for first-launch auto-install",
    packages = {
        "brave-bin",
    },
    post_install_hook = "scripts/install-brave-policy.sh",
    hook_behavior = "always",
    run_hooks_as_user = false,
}
