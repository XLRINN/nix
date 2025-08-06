{ config, pkgs, lib, ... }:

let 
  name = "david";
  user = "david";
  email = "xlrin.morgan@gmail.com"; 
  zshrc = config/shell/.zshrc;
  nvim = ./config/nvim/init.lua;
  yazi = builtins.fromTOML (builtins.readFile ./config/yazi/yazi.toml);
  rifle = ./config/ranger/rifle.conf;
  ghost = ./config/ghostty/config;
  tmux = ./config/tmux/tmux.conf;
  
  # Detect if this is a server environment
  isServer = let
    hostName = config.networking.hostName or "unknown";
  in hostName == "loki" || hostName == "server";
  
  # Only read alacritty config if not server
  # alacritty = if !isServer then builtins.fromTOML (builtins.readFile ./config/alacritty/alacritty.toml) else {};
in
{
  # Direnv configuration
  # direnv = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   nix-direnv.enable = true;
  # };

  # Git configuration
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



  # Zsh configuration
  zsh = {
    enable = true;
    autocd = false;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    cdpath = [ "~/.local/share/src" ];
    plugins = [ 
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./config;
        file = "shell/p10k.zsh";
      }
    ];
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
      # Auto-start zellij if not already in a session
      if [ -z "$ZELLIJ" ] && [ -z "$ZELLIJ_RUNNING" ]; then
        export ZELLIJ_RUNNING=1
        zellij
      fi
    '';
  };

  # Desktop-specific configurations (GUI environments)
  # alacritty = lib.mkIf (!isServer && builtins.length (builtins.attrNames alacritty) > 0) {
  #   enable = true;
  #   settings = alacritty;
  # };

  # Zellij configuration (works in both desktop and server environments)
  # zellij = {
  #   enable = true;
  #   settings = {
  #     default_Layout = "compact";
  #     pane_frames = false;
  #     theme = "ansi";
  #     simplified_ui = true;
  #     hide_session_name = true;
  #     rounded_corners = true;
  #   };
  # };

  # Yazi file manager
  # yazi = {
  #   enable = true;
  #   settings = yazi;
  # };

  # Neovim editor - modular approach
  # neovim = {
  #   enable = true;
  #   defaultEditor = true;
  #   extraPackages = with pkgs; [
  #     stylua
  #     ripgrep
  #     curl
  #   ];
  #   # Load configuration from modular config
  #   extraLuaConfig = builtins.readFile ./config/nvim/init.lua;
  # };

}
