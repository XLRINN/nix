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

      -- ChatGPT.nvim integration with OpenRouter
      {
        "jackMort/ChatGPT.nvim",
        config = function()
          require("chatgpt").setup({
            api_host_cmd = "echo https://openrouter.ai",
            api_key_cmd = vim.fn.filereadable("/run/secrets/openrouter-api-key") == 1 
              and "cat /run/secrets/openrouter-api-key" 
              or "cat ~/.openrouter_api_key",
          })
        end,
        dependencies = {
          "MunifTanjim/nui.nvim",
          "nvim-lua/plenary.nvim",
          "nvim-telescope/telescope.nvim",
        },
      },

      -- Codex.nvim for inline AI-assisted coding
      {
        "johnseth97/codex.nvim",
        dependencies = {
          "nvim-lua/plenary.nvim",
        },
        cmd = { "Codex", "CodexToggle" },
        keys = {
          {
            "<leader>cc",
            function()
              require("codex").toggle()
            end,
            desc = "Codex: toggle window",
          },
        },
        config = function()
          require("codex").setup({
            keymaps = {
              toggle = nil,
              quit = "<C-q>",
            },
            border = "rounded",
            width = 0.85,
            height = 0.85,
            autoinstall = true,
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

    -- Load API keys from environment file if available
    local api_keys_file = vim.fn.expand("~/.local/share/src/nixos-config/modules/shared/config/api-keys/keys.env")
    if vim.fn.filereadable(api_keys_file) == 1 then
      for line in io.lines(api_keys_file) do
        if line:match("^[A-Z_]*=") then
          local key, value = line:match("^([^=]*)=(.*)$")
          if key and value then
            -- Remove quotes if present
            value = value:gsub('^"(.*)"$', '%1')
            vim.env[key] = value
          end
        end
      end
    end

    -- -- Load API keys from sopswarden secrets if available
    -- local secret_files = {
    --   { env = "OPENROUTER_API_KEY", file = "/run/secrets/openrouter-api-key" },
    --   { env = "GITHUB_TOKEN", file = "/run/secrets/github-token" },
    --   -- Legacy support for direct API keys if needed
    --   { env = "OPENAI_API_KEY", file = "/run/secrets/openai-api-key" },
    -- }
    -- 
    -- for _, secret in ipairs(secret_files) do
    --   if vim.fn.filereadable(secret.file) == 1 then
    --     local handle = io.open(secret.file, "r")
    --     if handle then
    --       local value = handle:read("*a"):gsub("%s+$", "") -- Read and trim whitespace
    --       handle:close()
    --       vim.env[secret.env] = value
    --     end
    --   end
    -- end

    -- Set leader key
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    """.stripIndent
  '';
}
