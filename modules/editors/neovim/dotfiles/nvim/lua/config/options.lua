-- Options are loaded before lazy.nvim startup and any plugin (LazyVim provides
-- sensible defaults — overrides go here).
-- Full list: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt

-- Local conventions for this repo
opt.relativenumber = true
opt.number = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.scrolloff = 8
opt.signcolumn = "yes"
