# Development tools configuration
{ config, pkgs, lib, ... }:

{
  programs = {
    # Git configuration
    git = {
      enable = true;
      ignores = [ "*.swp" ];
      userName = "david";
      userEmail = "xlrin.morgan@gmail.com";
      lfs.enable = true;
      extraConfig = {
        init.defaultBranch = "master";
        core = {
          editor = "nvim";
          autocrlf = "input";
        };
        commit.gpgsign = false;
        pull.rebase = true;
        rebase.autoStash = true;
      };
    };

    # Neovim configuration
    neovim = {
      enable = true;
      defaultEditor = true;
      extraPackages = with pkgs; [
        stylua
        ripgrep
        curl
      ];
      extraLuaConfig = builtins.readFile ../config/nvim/init.lua;
    };

    # Directory environment management
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };

  # Link configuration files
  home.file = {
    ".config/nvim".source = ../config/nvim;
    ".config/direnv".source = ../config/direnv;
  };
}
