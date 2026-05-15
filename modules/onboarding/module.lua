return {
    description = "Interactive first-run setup: SSH key, git-crypt unlock, docker group",
    packages = {
        "openssh",
    },
    post_install_hook = "scripts/onboarding.sh",
    hook_behavior = "always",
    run_hooks_as_user = true,
}
