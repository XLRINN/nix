# Neovim configuration
{ config, pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      stylua
      ripgrep
      curl
    ];
    extraLuaConfig = builtins.readFile ../../config/nvim/init.lua;
  };

  home.file.".config/nvim" = {
    source = ../../config/nvim;
    recursive = true;
  };
}
