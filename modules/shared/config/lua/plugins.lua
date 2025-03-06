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
