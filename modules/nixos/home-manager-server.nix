{ config, pkgs, lib, ... }:

let
  user = "david";
  shared_programs = import ../shared/home-manager.nix { inherit config pkgs lib; };
  shared_files = import ../shared/files.nix { inherit config pkgs; };
in
{
  # Minimal, headless Home Manager for server: include shared dotfiles and CLI tools only.

  home = {
    enableNixpkgsReleaseCheck = false;
    username = user;
    homeDirectory = "/home/${user}";
    file = shared_files;
    stateVersion = "23.11";
  };

  # Reuse shared program settings, then selectively disable GUI bits.
  programs = shared_programs.programs // {
    # Disable GUI terminal on servers
    alacritty = { enable = lib.mkForce false; };
  };
}

