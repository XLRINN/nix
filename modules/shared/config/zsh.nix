{ config, pkgs, lib, ... }:

{
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
    if [ -z "$ZELLIJ" ] && [ -z "$ZELLIJ_RUNNING" ]; then
      export ZELLIJ_RUNNING=1
      zellij
    fi

    # Load API keys from environment
    if [ -f /etc/secrets/api-keys ]; then
      source /etc/secrets/api-keys
    fi
  '';
} 