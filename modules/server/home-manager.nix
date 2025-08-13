{ config, pkgs, lib, ... }:

let
  user = "david";
  shared-files = import ../shared/files.nix { inherit config pkgs; };
in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix {};
    file = shared-files // import ./files.nix { inherit user; };
    stateVersion = "21.05";
  };

  # Only CLI imports - no GUI components
  imports = [
    # CLI tools
    # ../shared/config/terminal/git.nix
    # ../shared/config/terminal/zsh.nix
    # ../shared/config/terminal/neovim.nix
    # ../shared/config/terminal/tmux.nix
    # ../shared/config/terminal/zellij.nix
    # ../shared/config/terminal/direnv.nix
    # ../shared/config/terminal/monitoring.nix
  ];
}
