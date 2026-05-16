local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {
        -- LazyVim core + sensible defaults
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },

        -- Language extras: matches modules/programming-languages/*
        { import = "lazyvim.plugins.extras.lang.rust" },
        { import = "lazyvim.plugins.extras.lang.python" },
        { import = "lazyvim.plugins.extras.lang.go" },
        { import = "lazyvim.plugins.extras.lang.ruby" },
        { import = "lazyvim.plugins.extras.lang.typescript" },

        -- Common file types
        { import = "lazyvim.plugins.extras.lang.json" },
        { import = "lazyvim.plugins.extras.lang.yaml" },
        { import = "lazyvim.plugins.extras.lang.markdown" },
        { import = "lazyvim.plugins.extras.lang.docker" },
        { import = "lazyvim.plugins.extras.lang.toml" },

        -- Editor extras
        { import = "lazyvim.plugins.extras.editor.telescope" },
        { import = "lazyvim.plugins.extras.editor.dial" },
        { import = "lazyvim.plugins.extras.coding.mini-surround" },
        { import = "lazyvim.plugins.extras.formatting.prettier" },
        { import = "lazyvim.plugins.extras.dap.core" },

        -- Your own plugin overrides
        { import = "plugins" },
    },
    defaults = {
        lazy = false,
        version = false, -- always use latest git
    },
    install = { colorscheme = { "tokyonight", "habamax" } },
    checker = { enabled = true, notify = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
            },
        },
    },
})
