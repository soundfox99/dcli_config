-- Brave on its own. Kept separate from browsers/module (firefox + chromium +
-- brave) so a host can take just this one instead of pulling in three.
--
-- Extension auto-install policies were removed along with bookmark sync;
-- extensions are managed by hand now.

return {
    description = "Brave browser",
    packages = {
        "brave-bin",
    },
}
