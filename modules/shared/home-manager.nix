{ config, pkgs, lib, ... }:

let 
  name = "david";
  user = "david";
  email = "xlrin.morgan@gmail.com"; 
in
{
  home.stateVersion = "23.11";
  home.file.".config/rbw/config.json" = {
    text = builtins.toJSON {
      email = email;
      lock_timeout = 43200;
      sync_interval = 3600;
    } + "\n";
    mode = "0600";
  };

  programs = {
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

    zellij = {
      enable = true;
      settings = {
        default_Layout = "compact";
        pane_frames = false;
        theme = "dark-modern";
        simplified_ui = true;
        hide_session_name = true;
        rounded_corners = true;
        show_startup_tips = false;
        themes = {
          "dark-modern" = {
            fg = [204 204 204];
            bg = [31 31 31];
            black = [39 39 39];
            red = [247 73 73];
            green = [46 160 67];
            yellow = [158 106 3];
            blue = [0 120 212];
            magenta = [208 18 115];
            cyan = [29 180 214];
            white = [204 204 204];
            orange = [158 106 3];
          };
        };
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
          background = "0x1f1f1f";
          foreground = "0xcccccc";
          black = "0x272727";
          red = "0xf74949";
          green = "0x2ea043";
          yellow = "0x9e6a03";
          blue = "0x0078d4";
          magenta = "0xd01273";
          cyan = "0x1db4d6";
          white = "0xcccccc";
          bright_black = "0x5d5d5d";
          bright_red = "0xdc5452";
          bright_green = "0x23d18b";
          bright_yellow = "0xf5f543";
          bright_blue = "0x3b8eea";
          bright_magenta = "0xd670d6";
          bright_cyan = "0x29b8db";
          bright_white = "0xe5e5e5";
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
            background = "0x1f1f1f";
            foreground = "0xcccccc";
          };
          normal = {
            black = "0x272727";
            red = "0xf74949";
            green = "0x2ea043";
            yellow = "0x9e6a03";
            blue = "0x0078d4";
            magenta = "0xd01273";
            cyan = "0x1db4d6";
            white = "0xcccccc";
          };
          bright = {
            black = "0x5d5d5d";
            red = "0xdc5452";
            green = "0x23d18b";
            yellow = "0xf5f543";
            blue = "0x3b8eea";
            magenta = "0xd670d6";
            cyan = "0x29b8db";
            white = "0xe5e5e5";
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
        set notermguicolors
        set background=dark
        set clipboard=unnamedplus
        colorscheme default
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
          { "johnseth97/codex.nvim",
            dependencies = { "nvim-lua/plenary.nvim" },
            cmd = { "Codex", "CodexToggle" },
            keys = {
              { "<leader>cc", "<cmd>CodexToggle<CR>", desc = "Codex: toggle window" },
            },
            event = "VeryLazy",
            config = function()
              require("codex").setup({
                keymaps = { toggle = nil, quit = "<C-q>" },
                border = "rounded",
                width = 0.85,
                height = 0.85,
                autoinstall = true,
              })
            end,
          },
          { "yetone/avante.nvim",
            event = "VeryLazy",
            opts = {
              provider = "openai",
              openai = {
                endpoint = "https://openrouter.ai/api/v1",
                model = "openai/gpt-4o",
                temperature = 0,
              },
              behaviour = { auto_suggestions = true },
            },
            dependencies = {
              "nvim-lua/plenary.nvim",
              "MunifTanjim/nui.nvim",
              "stevearc/dressing.nvim",
              "nvim-tree/nvim-web-devicons",
            },
          },
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
        swap= "sudo nix run .#build-switch";
        bss = "sudo nix run .#build-switch && source ~/.zshrc";
        upgrade = "clear && sudo nix run .#build-switch && source ~/.zshrc";
        sauce = "source ~/.zshrc";
        addcask = "nvim ~/nix/modules/darwin/casks.nix";
        cbs = "clear && bs";
        gc = "nix-collect-garbage -d";
        pretty =  "POWERLEVEL9K_CONFIG_FILE=/tmp/p10k.zsh p10k configure && cp ~/.p10k.zsh nix/modules/shared/config/shell/p10k.zsh";
        pretty2 = "cp ~/.p10k.zsh nix/modules/shared/config/shell/p10k.zsh";
        unlock = "bash ~/nix/scripts/secrets-wizard.sh";

        # Sopswarden (SOPS + Bitwarden) shortcuts
        sops-sync = "echo 'Syncing secrets from Bitwarden via sopswarden...'; rbw sync && sopswarden-sync && echo '✓ Secrets synchronized'";
        sops-deploy = "echo 'Building system with sopswarden secrets...'; rbw sync && sopswarden-sync && sudo nixos-rebuild switch --impure && echo '✓ System deployed with secrets'";
        sops-check = "echo 'Checking sopswarden secrets...'; ls -la /run/secrets/ 2>/dev/null | grep -E 'tailscale|openrouter|github' || echo 'No sopswarden secrets found'";
        rbw-login = "echo 'Logging into Bitwarden via rbw...'; rbw login";
        rbw-unlock = "echo 'Unlocking Bitwarden vault...'; rbw unlock";
      };

      initContent = ''
        # Set rbw (Bitwarden) email to the same value used for git
        export RBW_EMAIL="${email}"

        # If only OPENROUTER_API_KEY is present, mirror it to OPENAI_API_KEY for tooling that expects that variable
        if [[ -z "''${OPENAI_API_KEY:-}" && -n "''${OPENROUTER_API_KEY:-}" ]]; then
          export OPENAI_API_KEY="$OPENROUTER_API_KEY"
        fi

        # Start Zellij if not already running
        if [ -z "$ZELLIJ" ] && [ -z "$ZELLIJ_RUNNING" ]; then
          export ZELLIJ_RUNNING=1
          export ZELLIJ_DISABLE_TIPS=1
          zellij
        fi

      '';
    };
  }; # End of programs block
}
