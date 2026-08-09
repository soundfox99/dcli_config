-- Zen Browser only. Kept separate from browsers/module (firefox + chromium +
-- brave) so a host can pick one or the other instead of excluding three
-- packages out of a module it doesn't really want.
--
-- No extension-policy hook here: zen-browser-bin ships its own package-owned
-- distribution/policies.json under /opt, so the browsers/scripts policy writer
-- would be fighting pacman over that file.
--
-- The shortcut hook runs as the user because Zen profiles live under
-- ~/.config/zen. It is a no-op until Zen has been launched once and created a
-- profile, and it refuses to write while Zen is running (Zen rewrites the
-- shortcuts file from memory on exit and would discard the change).
-- See README.md for the bindings themselves.

return {
    description = "Zen Browser (Firefox-based, performance oriented)",
    packages = {
        "zen-browser-bin",
    },
    post_install_hook = "scripts/install-zen-shortcuts.sh",
    hook_behavior = "always",
    run_hooks_as_user = true,
}
