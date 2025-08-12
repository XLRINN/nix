{ config, pkgs, lib, ... }:

let
  # Detect if this is a server environment
  isServer = let
    hostName = config.networking.hostName or "unknown";
  in hostName == "loki" || hostName == "server";
in
{
  imports = [
    # Terminal tools
    ./config/terminal/git.nix
    ./config/terminal/zsh.nix
    ./config/terminal/neovim.nix
    ./config/terminal/tmux.nix
    ./config/terminal/zellij.nix
    ./config/terminal/direnv.nix
    ./config/terminal/monitoring.nix
  ] ++ lib.optionals (!isServer) [
    # GUI tools
    #./config/gui/alacritty.nix
  ];

  # Home configuration (required by Home Manager)
  home = {
    enableNixpkgsReleaseCheck = false;
    stateVersion = "23.11";
  };
}
