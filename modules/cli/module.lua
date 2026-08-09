return {
    description = "Utility-tier CLI tools",
    packages = {
        "bat",
        "fzf",
        "eza",
        "yazi",          -- TUI file manager; niri binds Mod+Y to `kitty yazi`
        "plocate",
        "tree",
        "lazydocker",
        "wget",
        "unzip",
        "less",
        "stow",
        "just",          -- command runner; arch-config has a top-level Justfile
        "bitwarden-cli",
        "github-cli",
        "tailscale",
    },
}
