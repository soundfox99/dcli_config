return {
    description = "Node.js: LTS as the system Node (required by bitwarden-cli) + fnm for user-space multi-version dev (latest, nightly, project-pinned)",
    packages = {
        -- System Node: bitwarden-cli pins this exact package via its dep.
        "nodejs-lts-jod",
        "npm",
        -- User-space version manager: install/switch any Node version under ~/.fnm
        -- without touching the pacman one. Initialized in .bashrc via `fnm env`.
        "fnm",
    },
    post_install_hook = "scripts/fnm-bootstrap.sh",
    hook_behavior = "always",
    run_hooks_as_user = true,
}
