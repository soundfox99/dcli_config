-- 3.3 GB of images, fetched from GitHub's tarball endpoint rather than tracked
-- here or cloned over git (the pack broke past 1.6 GB and git can't resume).
-- See README.md.

return {
    description = "Wallpaper collection (dharmx/walls) fetched to ~/Pictures/Wallpapers",
    packages = {
        "git",      -- hook uses git ls-remote to resolve upstream HEAD
        "curl",
    },
    post_install_hook = "scripts/install-wallpapers.sh",
    hook_behavior = "always",
    run_hooks_as_user = true,
}
