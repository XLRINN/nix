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

  # Basic zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
}
