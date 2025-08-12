{ config, pkgs, lib, ... }:

{
  home = {
    username = "david";
    homeDirectory = "/home/david";
    stateVersion = "23.11";
  };

  # Minimal configuration to avoid warnings
  programs.home-manager.enable = true;
}