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
          file = ".p10k.zsh";
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
    };
    initExtra = ''
      if [ -z "$ZELLIJ" ] && [ -z "$ZELLIJ_RUNNING" ]; then
        export ZELLIJ_RUNNING=1
        zellij
      fi
    '';
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
        editor = "vim";
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
      pane_frames = false;
      #default_layout = "compact";
      theme = "nord";
    };
  };

}
