{ config, pkgs, lib, ... }:

let 
  name = "david";
  user = "david";
  email = "xlrin.morgan@gmail.com"; 
in
{
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
    delta = {
      enable = true;
      options = {
        line-numbers = true;
        side-by-side = true;
      };
    };
  };

  # Ensure local clone of nixos-config exists and points to the correct remote/branch
  home.activation.ensure-nixos-config = {
    text = ''
      #!/bin/sh
      set -euo pipefail
  REPO_DIR="$HOME/nix"
  REMOTE_URL="https://github.com/xlrinn/nix.git"
  BRANCH="master"

      if [ ! -d "$HOME" ]; then
        mkdir -p "$HOME"
      fi

      if [ ! -d "$REPO_DIR/.git" ]; then
        echo "Cloning $REMOTE_URL into $REPO_DIR"
        git clone --filter=blob:none --depth 1 --branch "$BRANCH" "$REMOTE_URL" "$REPO_DIR"
      else
        echo "Updating existing repo at $REPO_DIR"
        (cd "$REPO_DIR" && git remote set-url origin "$REMOTE_URL" || true)
        (cd "$REPO_DIR" && git fetch --depth 1 origin "$BRANCH" || true)
        (cd "$REPO_DIR" && git checkout "$BRANCH" || true)
        (cd "$REPO_DIR" && git reset --hard "origin/$BRANCH" || true)
      fi
    '';
  };

  zellij = {
    enable = true;
    settings = {
      default_Layout = "compact";
      pane_frames = false;
      theme = "ansi";
      simplified_ui = true;
      hide_session_name = true;
      rounded_corners = true;
    };
  };

  yazi = {
    enable = true;
    settings = {
      editor = "neovim";
      manager = {
        ratio = [ 1 4 3 ];
        sort_by = "natural";
        sort_sensitive = true;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "none";
        show_hidden = true;
        show_symlink = true;
        enable_mouse = true;
      };
      preview = {
        image_filter = "lanczos3";
        image_quality = 90;
        tab_size = 1;
        max_width = 600;
        max_height = 900;
        cache_dir = "";
        ueberzug_scale = 1;
        ueberzug_offset = [ 0 0 0 0 ];
        enable_image_previews = true;
      };
      tasks = {
        micro_workers = 5;
        macro_workers = 10;
        bizarre_retry = 5;
      };
      theme = {
        background = "0x282c34";
        foreground = "0xc5c8c6";
        black = "0x282c34";
        red = "0xcc6666";
        green = "0xb5bd68";
        yellow = "0xf0c674";
        blue = "0x81a2be";
        magenta = "0xb294bb";
        cyan = "0x8abeb7";
        white = "0xc5c8c6";
        bright_black = "0x969896";
        bright_red = "0xcc6666";
        bright_green = "0xb5bd68";
        bright_yellow = "0xf0c674";
        bright_blue = "0x81a2be";
        bright_magenta = "0xb294bb";
        bright_cyan = "0x8abeb7";
        bright_white = "0xffffff";
      };
      open = {
        rules = [
          { mime = "*/*"; use = "edit"; }
          { name = "*"; use = "edit"; }
        ];
      };
    };
  };

  alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "MesloLGS NF";
        };
        bold = {
          family = "MesloLGS NF";
        };
        italic = {
          family = "MesloLGS NF";
        };
        bold_italic = {
          family = "MesloLGS NF";
        };
      };
      cursor = {
        style = "Block";
      };
      window = {
        opacity = 0.8;
        padding = { x = 10; y = 10; };
        dynamic_padding = false;
        decorations = "none";
      };
      colors = {
        primary = {
          background = "0x2E3440";
          foreground = "0xD8DEE9";
        };
        normal = {
          black = "0x3B4252";
          red = "0xBF616A";
          green = "0xA3BE8C";
          yellow = "0xEBCB8B";
          blue = "0x81A1C1";
          magenta = "0xB48EAD";
          cyan = "0x88C0D0";
          white = "0xE5E9F0";
        };
        bright = {
          black = "0x4C566A";
          red = "0xBF616A";
          green = "0xA3BE8C";
          yellow = "0xEBCB8B";
          blue = "0x81A1C1";
          magenta = "0xB48EAD";
          cyan = "0x8FBCBB";
          white = "0xECEFF4";
        };
      };
      selection = {
        semantic_escape_chars = " ,│`|:\"'()[]{}<>";
      };
    };
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
          { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
          { "neovim/nvim-lspconfig", enabled = false },
          { "andersevenrud/nordic.nvim" },
          {"github/copilot.vim"},
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
          src = ./config;
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
