return {
    description = "Git, GitHub CLI, and git-crypt for transparent file encryption",
    packages = {
        "git",
        "github-cli",
        "git-crypt",
    },
    dotfiles = {
        { source = "dotfiles/.gitconfig", target = "~/.gitconfig" },
    },
}
