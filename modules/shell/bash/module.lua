return {
    description = "Bash shell with custom .bashrc",
    packages = { "bash", "bash-completion" },
    dotfiles = {
        { source = "dotfiles/.bashrc", target = "~/.bashrc" },
    },
}
