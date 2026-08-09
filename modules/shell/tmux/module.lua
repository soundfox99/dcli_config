return {
    description = "tmux terminal multiplexer with tpm",
    packages = { "tmux" },
    dotfiles = {
        { source = "dotfiles/.tmux.conf", target = "~/.tmux.conf" },
    },
    post_install_hook = "scripts/install-tpm.sh",
    -- "always" not "once": the hook clones into $HOME and previously ran as
    -- root, so it landed in /root and was marked done. It self-skips when tpm
    -- is already present, so re-running costs nothing.
    hook_behavior = "always",
    run_hooks_as_user = true,
}
