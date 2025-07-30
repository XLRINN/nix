-- Neovim init.lua configuration

-- Set the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable line numbers
vim.wo.number = true

-- Basic settings
vim.o.relativenumber = true
vim.o.syntax = 'on'
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.mouse = 'a'
vim.o.termguicolors = true
vim.o.background = 'dark'
vim.o.clipboard = 'unnamedplus'

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
    -- LazyVim base configuration
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    
    -- Telescope and fuzzy finding
    { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
    
    -- LSP and Mason (disabled for LazyVim)
    { "williamboman/mason-lspconfig.nvim", enabled = false },
    { "williamboman/mason.nvim", enabled = false },
    
    -- File explorer and git
    { "preservim/nerdtree" },
    { "tpope/vim-fugitive" },
    
    -- Avante AI assistant
    { "yetone/avante.nvim",
      config = function()
        require("avante").setup({
          api_key = os.getenv("AVANTE_API_KEY") or "your-api-key-here",
          model = "gpt-4",
          max_tokens = 1000,
          temperature = 0.7,
        })
      end,
    },
    
    -- Theme collection
    { "craftzdog/solarized-osaka.nvim", priority = 1000, config = true },
    { "folke/tokyonight.nvim", priority = 1000, config = true },
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    { "rose-pine/neovim", name = "rose-pine", priority = 1000 },
    { "projekt0n/github-nvim-theme", priority = 1000 },
    { "rebelot/kanagawa.nvim", priority = 1000 },
    { "EdenEast/nightfox.nvim", priority = 1000 },
    { "sainnhe/gruvbox-material", priority = 1000 },
    { "navarasu/onedark.nvim", priority = 1000 },
    { "shaunsingh/nord.nvim", priority = 1000, config = function()
        vim.cmd("colorscheme nord")
      end },
    { "sainnhe/everforest", priority = 1000 },
    { "sainnhe/edge", priority = 1000 },
    { "sainnhe/sonokai", priority = 1000 },
    { "marko-cerovac/material.nvim", priority = 1000 },
    { "dracula/vim", as = "dracula", priority = 1000 },
    { "bluz71/vim-nightfly-guicolors", priority = 1000 },
    { "bluz71/vim-moonfly-colors", priority = 1000 },
    { "rafamadriz/neon", priority = 1000 },
    { "tanvirtin/monokai.nvim", priority = 1000 },
    { "Mofiqul/vscode.nvim", priority = 1000 },
    
    -- Theme switcher
    { "zaldih/themery.nvim",
      config = function()
        require("themery").setup({
          themes = {
            "tokyonight",
            "catppuccin",
            "rose-pine",
            "github_dark",
            "kanagawa",
            "nightfox",
            "gruvbox-material",
            "onedark",
            "solarized-osaka",
            "nordic",
            "nord",
            "everforest",
            "edge",
            "sonokai",
            "material",
            "dracula",
            "nightfly",
            "moonfly",
            "neon",
            "monokai",
            "vscode",
          },
          themeConfigFile = vim.fn.stdpath("config") .. "/lua/theme.lua",
          livePreview = true,
        })
      end,
    },
    
    -- Treesitter and LSP
    { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
    { "neovim/nvim-lspconfig", enabled = false },
    { "andersevenrud/nordic.nvim" },
    
    -- GitHub Copilot
    {"github/copilot.vim"},
  },
})

-- Key mappings
vim.keymap.set('n', '<leader>th', ':Themery<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>n', ':NERDTreeToggle<CR>', { noremap = true, silent = true })