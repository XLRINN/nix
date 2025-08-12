{ config, pkgs, lib, ... }:

let
  user = "david";
in
{
  # imports = [
  #   # CLI tools only - commented out for initial installation testing
  #   ../shared/config/terminal/git.nix
  #   ../shared/config/terminal/zsh.nix
  #   ../shared/config/terminal/neovim.nix
  #   ../shared/config/terminal/tmux.nix
  #   ../shared/config/terminal/zellij.nix
  #   ../shared/config/terminal/direnv.nix
  #   ../shared/config/terminal/monitoring.nix
  # ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    stateVersion = "23.11";
  };
}
}
