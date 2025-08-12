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
    

    {
      "yetone/avante.nvim",
      event = "VeryLazy",
      build = (vim.fn.has("win32") ~= 0)
          and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
          or "make",
      config = function()
        require("avante").setup() -- Load the plugin first
        require("avante-config") -- Load your custom configuration module
      end,
      dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "MeanderingProgrammer/render-markdown.nvim",
      },
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
    
   
  },
})

-- Key mappings
vim.keymap.set('n', '<leader>th', ':Themery<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>n', ':NERDTreeToggle<CR>', { noremap = true, silent = true })

-- Avante key mappings
vim.keymap.set('n', '<leader>aa', ':Avante<CR>', { noremap = true, silent = true })
vim.keymap.set('v', '<leader>aa', ':Avante<CR>', { noremap = true, silent = true })