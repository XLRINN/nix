-- Neovim init.lua configuration

-- Set the leader key
vim.g.mapleader = ' '

-- Enable line numbers
vim.wo.number = true

-- Basic settings
vim.o.relativenumber = true
vim.o.syntax = 'on'
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- Ensure lazy.nvim is installed
local install_path = vim.fn.stdpath('data')..'/site/pack/lazy/start/lazy.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system({'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', '--branch=stable', install_path})
  vim.cmd [[packadd lazy.nvim]]
end

-- Plugin management using lazy.nvim
require("lazy").setup({
  defaults = {
    lazy = true,
  },
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
    { "williamboman/mason-lspconfig.nvim", enabled = false },
    { "williamboman/mason.nvim", enabled = false },
    { "preservim/nerdtree" },
    { "tpope/vim-fugitive" },
    { "Exafunction/codeium.vim" },  -- Add Codeium plugin
    { import = "plugins" },
    { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
  },
})