{ config, pkgs, lib, ... }:

{
  # User configuration
  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Basic packages
  home.packages = with pkgs; [
    # Add any basic packages you want here
  ];
}