{ config, pkgs, lib, ... }:

{
  # User configuration
  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Basic packages
  home.packages = with pkgs; [
    # Essential tools
    git
    vim
    htop
    tree
    wget
    curl
    # Development tools
    direnv
    # Monitoring
    btop
  ];
}