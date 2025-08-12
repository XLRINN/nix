# Alacritty terminal configuration
{ config, pkgs, lib, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../../config/alacritty/alacritty.toml);
  };

  home.file.".config/alacritty" = {
    source = ../../config/alacritty;
    recursive = true;
  };
}
