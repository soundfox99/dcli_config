return {
    description = "Neovim with LazyVim distribution. Plugins bootstrap via lazy.nvim on first launch.",
    packages = {
        "neovim",
        "vim",
        -- Tooling LazyVim leans on:
        "ripgrep",         -- telescope live_grep
        "fd",              -- telescope file finder
        "lazygit",         -- LazyVim's git UI keymap (<leader>gg)
        "tree-sitter-cli", -- compiling missing parsers on the fly
        "wl-clipboard",    -- system clipboard on Wayland (also in WM modules)
        "xclip",           -- system clipboard on X11 fallback
    },
    dotfiles_sync = true,
}
