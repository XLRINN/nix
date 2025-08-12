# Monitoring tools configuration
{ config, pkgs, lib, ... }:

{
  programs = {
    htop.enable = true;
    btop.enable = true;
  };

  home.file = {
    ".config/htop".source = ../htop;
    ".config/btop".source = ../btop;
  };
}
