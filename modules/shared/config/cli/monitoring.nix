# System monitoring tools configuration
{ config, pkgs, lib, ... }:

{
  programs = {
    htop.enable = true;
    btop.enable = true;
  };

  # Link configuration files
  home.file = {
    ".config/htop".source = ../../config/htop;
    ".config/btop".source = ../../config/btop;
  };
}
