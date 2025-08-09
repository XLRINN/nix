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



      -- Avante.nvim - AI-powered code assistant
      {
        "yetone/avante.nvim",
        event = "VeryLazy",
        lazy = false,
        version = false,
        opts = {
          provider = "openai",
          openai = {
            endpoint = "https://api.openai.com/v1",
            model = "gpt-4o",
            temperature = 0,
            max_tokens = 4096,
          },
          behaviour = {
            auto_suggestions = true,
            auto_set_highlight_group = true,
            auto_set_keymaps = true,
            auto_apply_diff_after_generation = false,
            support_paste_from_clipboard = false,
          },
          mappings = {
            --- @class AvanteConflictMappings
            diff = {
              ours = "co",
              theirs = "ct",
              all_theirs = "ca",
              both = "cb",
              cursor = "cc",
              next = "]x",
              prev = "[x",
            },
            suggestion = {
              accept = "<M-l>",
              next = "<M-]>",
              prev = "<M-[>",
              dismiss = "<C-]>",
            },
            jump = {
              next = "]]",
              prev = "[[",
            },
            submit = {
              normal = "<CR>",
              insert = "<C-s>",
            },
            sidebar = {
              apply_all = "A",
              apply_cursor = "a",
              switch_windows = "<Tab>",
              reverse_switch_windows = "<S-Tab>",
            },
          },
          hints = { enabled = true },
          windows = {
            position = "right",
            wrap = true,
            width = 30,
            sidebar_header = {
              align = "center",
              rounded = true,
            },
          },
          highlights = {
            diff = {
              current = "DiffText",
              incoming = "DiffAdd",
            },
          },
          diff = {
            autojump = true,
            list_opener = "copen",
          },
        },
        build = "make",
        dependencies = {
          "nvim-treesitter/nvim-treesitter",
          "stevearc/dressing.nvim",
          "nvim-lua/plenary.nvim",
          "MunifTanjim/nui.nvim",
          --- The below dependencies are optional,
          "nvim-tree/nvim-web-devicons",
          "zbirenbaum/copilot.lua",
          {
            "HakonHarnes/img-clip.nvim",
            event = "VeryLazy",
            opts = {
              default = {
                embed_image_as_base64 = false,
                prompt_for_file_name = false,
                drag_and_drop = {
                  insert_mode = true,
                },
                use_absolute_path = true,
              },
            },
          },
          {
            "MeanderingProgrammer/render-markdown.nvim",
            opts = {
              file_types = { "markdown", "Avante" },
            },
            ft = { "markdown", "Avante" },
          },
        },
        config = function(_, opts)
          -- Read API key from agenix-managed secret file
          local api_key_file = os.getenv("HOME") .. "/.openai_api_key"
          local file = io.open(api_key_file, "r")
          if file then
            local api_key = file:read("*all"):gsub("%s+", "")
            file:close()
            -- Set environment variable for Avante
            vim.env.OPENAI_API_KEY = api_key
          end
          
          require("avante").setup(opts)
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
