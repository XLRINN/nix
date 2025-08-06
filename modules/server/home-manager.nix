{ config, pkgs, lib, ... }:

let
  user = "david";
in
{
  # Minimal server home configuration
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    stateVersion = "23.11";
  };

  # Basic git configuration
  programs.git = {
    enable = true;
    userName = "david";
    userEmail = "xlrin.morgan@gmail.com";
  };

  # Enhanced zsh configuration with aliases
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
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
  };
}
