# Development tools configuration
{ config, pkgs, lib, ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.file.".config/direnv" = {
    source = ../../config/direnv;
    recursive = true;
  };
}
