{ pkgs, config ? null }:

let
  # Server-specific CLI packages - minimal for basic installation
  serverPackages = with pkgs; [
    # Basic CLI tools only
    coreutils
    wget
    curl
    vim
    git
    zsh
    htop
    tmux
  ];
in
  serverPackages
