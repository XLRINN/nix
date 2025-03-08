{ config, pkgs, lib, ... }:
  

let 
  name = "david";
  user = "david";
  email = "xlrin.morgan@gmail.com"; 
  zshrc = config/shell/.zshrc;
  nvim = ./config/nvim/init.lua;
  yazi = builtins.fromTOML (builtins.readFile ./config/yazi/yazi.toml);
  alacritty = builtins.fromTOML (builtins.readFile ./config/alacritty/alacritty.toml);
  rifle = ./config/ranger/rifle.conf;
  ghost = ./config/ghostty/config;
  tmux = ./config/tmux/tmux.conf;
in
{

#imports = [];

  direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  git = {
    enable = true;
    ignores = [ "*.swp" ];
    userName = name;
    userEmail = email;
    lfs = {
      enable = true;
    };
    extraConfig = {
      init.defaultBranch = "master";
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
      commit.gpgsign = false;
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  

  zellij = {
    enable = true;
    settings = {
      defaultLayout = "compact";
      pane_frames = false;
      theme = "Nord";
      simplified_ui = true;
    };
  
    };

  yazi = {
    enable = true;
    settings = yazi;
  };

  alacritty = {
    enable = true;
    settings = alacritty;
  };

  neovim = {
    enable = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      stylua
      ripgrep
      curl
    ];
    extraConfig = ''
      set number
      set relativenumber
      set expandtab
      set tabstop=2
      set softtabstop=2
      set shiftwidth=2
      set smartindent
      set mouse=a
      set termguicolors
      set background=dark
      set clipboard=unnamedplus
      set termguicolors
      " Keybindings to toggle NERDTree
      nnoremap <leader>n :NERDTreeToggle<CR>

      " Plugin management using lazy.nvim
      lua << EOF
      -- bootstrap lazy.nvim
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

      -- leader key setup
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- setup keymaps
      vim.keymap.set('n', '<leader>th', ':Themery<CR>', { noremap = true, silent = true })

      -- setup plugins
      require("lazy").setup({
        spec = {
          {
            "LazyVim/LazyVim",
            import = "lazyvim.plugins",
            opts = {
              -- explicitly set fzf as the picker
              ui = {
                -- picker = "fzf",
              },
            },
          },
          { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
          { "williamboman/mason-lspconfig.nvim", enabled = false },
          { "williamboman/mason.nvim", enabled = false },
          { "preservim/nerdtree" },
          { "tpope/vim-fugitive" },
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
          { "glepnir/zephyr-nvim", priority = 1000 },
          { "bluz71/vim-nightfly-guicolors", priority = 1000 },
          { "bluz71/vim-moonfly-colors", priority = 1000 },
          { "rafamadriz/neon", priority = 1000 },
          { "tanvirtin/monokai.nvim", priority = 1000 },
          { "Mofiqul/vscode.nvim", priority = 1000 },
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
                  "zephyr",
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
          { "jackMort/ChatGPT.nvim",
            dependencies = {
              "MunifTanjim/nui.nvim",
              "nvim-lua/plenary.nvim",
              "nvim-telescope/telescope.nvim"
            },
            config = function()
              require("chatgpt").setup({
                openai_params = {
                  -- model = "gpt-4",
                 -- max_tokens = 2000,
                },
                keymaps = {
                  close = "<C-c>",
                  submit = "<C-s>",
                  yank_last = "<C-y>",
                  scroll_up = "<C-u>",
                  scroll_down = "<C-d>",
                },
              })
              vim.keymap.set('n', '<leader>cc', ':ChatGPT<CR>', { noremap = true, silent = true })
              vim.keymap.set('n', '<leader>ce', ':ChatGPTEditWithInstructions<CR>', { noremap = true, silent = true })
            end,
          },
          { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
          { "neovim/nvim-lspconfig", enabled = false },
          { "andersevenrud/nordic.nvim" },
        },
      })


      EOF
    '';
  };

  zsh = {
    enable = true;
    autocd = false;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    cdpath = [ "~/.local/share/src" ];
    plugins = [ {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
          name = "powerlevel10k-config";
          src = lib.cleanSource ./config;
          file = "shell/p10k.zsh";
      }];
    shellAliases = {
      pf = "pfetch";
      bs = "nix run .#build-switch";
      bss = "nix run .#build-switch && source ~/.zshrc";
      fmu = "clear && nix run .#build-switch && source ~/.zshrc";
      sauce = "source ~/.zshrc";
      addcask = "nvim ~/nix/modules/darwin/casks.nix";
      cbs = "clear && bs";
      gc = "nix-collect-garbage -d";
      pretty =  "POWERLEVEL9K_CONFIG_FILE=/tmp/p10k.zsh p10k configure && cp ~/.p10k.zsh nix/modules/shared/config/shell/p10k.zsh";
      pretty2 = "cp ~/.p10k.zsh nix/modules/shared/config/shell/p10k.zsh";
    };
  
    initExtra = ''
      if [ -z "$ZELLIJ" ] && [ -z "$ZELLIJ_RUNNING" ]; then
        export ZELLIJ_RUNNING=1
        zellij
      fi

    '';
  };
}
