-- Zen Browser only. Kept separate from browsers/module (firefox + chromium +
-- brave) so a host can pick one or the other instead of excluding three
-- packages out of a module it doesn't really want.
--
-- No extension-policy hook here: zen-browser-bin ships its own package-owned
-- distribution/policies.json under /opt, so the browsers/scripts policy writer
-- would be fighting pacman over that file.

return {
    description = "Zen Browser (Firefox-based, performance oriented)",
    packages = {
        "zen-browser-bin",
    },
}
