-- Wallpaper collection cloned from a git remote rather than tracked in this
-- repo: it is ~1700 images, which has no business inflating a config repo that
-- otherwise holds text.
--
-- Shallow (--depth 1) and single-branch, so the clone carries the current
-- snapshot without the full history behind it.
--
-- Runs as the user; the clone lands under $HOME/Pictures. See README.md.

return {
    description = "Wallpaper collection (dharmx/walls) shallow-cloned to ~/Pictures/Wallpapers",
    packages = {},
    post_install_hook = "scripts/install-wallpapers.sh",
    hook_behavior = "always",
    run_hooks_as_user = true,
}
