{ pkgs, ... }:

pkgs.writeTextFile rec {
  name = "nvim-config";
  text = ''
    """ Lua
    -- Load Lazy.nvim as the plugin manager
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
      vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
      })
    end
    vim.opt.rtp:prepend(lazypath)

    -- Lazy.nvim setup with plugins
    require("lazy").setup({
      -- Treesitter for syntax highlighting
      {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate",
        config = function()
          require("nvim-treesitter.configs").setup({
            ensure_installed = "all",
            highlight = { enable = true },
          })
        end,
      },

      -- Telescope for fuzzy finding
      {
        "nvim-telescope/telescope.nvim",
        requires = { { "nvim-lua/plenary.nvim" } },
        config = function()
          require("telescope").setup({
            defaults = {
              path_display = { "truncate" },
            },
          })
        end,
      },



      -- CoC for LSP and autocompletion
      {
        "neoclide/coc.nvim",
        branch = "release",
        config = function()
          vim.cmd [[
            set hidden
            set updatetime=300

            " Use <Tab> and <S-Tab> for navigation in the completion menu
            inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
            inoremap <silent><expr> <S-TAB> pumvisible() ? "\<C-p>" : "\<S-TAB>"

            " Confirm completion with <CR>
            inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"

            " Trigger completion with <C-Space>
            inoremap <silent><expr> <C-Space> coc#refresh()

            " Key mappings for navigation
            nmap <silent> gd <Plug>(coc-definition)
            nmap <silent> gr <Plug>(coc-references)
          ]]
        end,
      },
    })

    -- Enable line numbers
    vim.opt.number = true
    vim.opt.relativenumber = true

    """.stripIndent
  '';
}
