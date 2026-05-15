return {
    description = "tmux terminal multiplexer with tpm",
    packages = { "tmux" },
    dotfiles = {
        { source = "dotfiles/.tmux.conf", target = "~/.tmux.conf" },
    },
    post_install_hook = "scripts/install-tpm.sh",
    hook_behavior = "once",
}
