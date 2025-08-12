# Shell and terminal tools configuration
{ config, pkgs, lib, ... }:

{
  programs = {
    # Shell configuration
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
          src = lib.cleanSource ../..;
          file = "config/shell/p10k.zsh";
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
        pretty = "POWERLEVEL9K_CONFIG_FILE=/tmp/p10k.zsh p10k configure && cp ~/.p10k.zsh nix/modules/shared/config/shell/p10k.zsh";
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

    # Terminal multiplexers
    tmux = {
      enable = true;
      extraConfig = builtins.readFile ../../config/tmux/tmux.conf;
    };

    zellij = {
      enable = true;
      settings = {
        default_layout = "compact";
        pane_frames = false;
        theme = "ansi";
        simplified_ui = true;
        hide_session_name = true;
      };
    };
  };

  # Link configuration files
  home.file = {
    ".config/zsh".source = ../../config/zsh;
    ".p10k.zsh".source = ../../config/shell/p10k.zsh;
    ".config/tmux".source = ../../config/tmux;
    ".config/zellij".source = ../../config/zellij;
  };
}
