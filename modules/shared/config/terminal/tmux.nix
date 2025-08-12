# Tmux configuration
{ config, pkgs, lib, ... }:

{
  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ../../config/tmux/tmux.conf;
  };

  home.file.".config/tmux" = {
    source = ../../config/tmux;
    recursive = true;
  };
}
