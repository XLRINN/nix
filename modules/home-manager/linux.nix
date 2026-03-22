# Standalone Home Manager configuration for any Linux distro.
# This does NOT require NixOS — just Nix + home-manager installed.
#
# Usage:
#   home-manager switch --flake .#david
#
{ config, pkgs, lib, ... }:

let
  user = "david";
in
{
  imports = [
    ../shared/home-manager.nix
  ];

  home = {
    username      = user;
    homeDirectory = "/home/${user}";
    # nixos/packages.nix already includes shared/packages.nix internally,
    # and adds GUI apps: Firefox, Termius, Alacritty, VSCode, VLC, etc.
    packages      = pkgs.callPackage ../nixos/packages.nix {};
    file          = import ../shared/files.nix { inherit config pkgs; };
    stateVersion  = "24.05";
    enableNixpkgsReleaseCheck = false;
  };

  programs.home-manager.enable = true;
}
